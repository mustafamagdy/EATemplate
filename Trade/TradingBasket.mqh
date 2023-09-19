#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Object.mqh>
#include "Trade.mqh"
#include "..\UI\Reporter.mqh"

enum ENUM_BASKET_STATUS
{
    BASKET_OPEN = 0,
    BASKET_CLOSING = 1,
    BASKET_CLOSED = 2
};

class CTradingBasket : public CObject
{
private:
    CReporter _reporter;
    Trade _trades[];
    ENUM_BASKET_STATUS _basketStatus;
    long _magicNumber;
    string _symbol;
    double _basketAvgTpPrice;
    double _basketAvgSlPrice;
    int lastOrderCount;
    double firstOrderVolume;
    
public:
    CTradingBasket(string symbol, long magicNumber);
    ~CTradingBasket();

public:
    double Volume();
    double Volume(ENUM_ORDER_TYPE orderType);
    long MagicNumber() { return _magicNumber; }
    double AverageOpenPrice();
    double Profit();
    int Count();
    string Symbol();
    bool HasOpenedTrades();
    bool IsEmpty();
    ENUM_BASKET_STATUS Status();
    bool FirstTrade(Trade &trade);
    bool LastTrade(Trade &trade);
    int LastOrderCount() { return lastOrderCount; }
    double FirstOrderVolume() { return firstOrderVolume; }

public:
    void SetBasketAvgTpPrice(double tpPrice);
    bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string &message, Trade &newTrade, int virtualSLPoints, int virtualTPPoints, string comment);
    bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string &message, Trade &newTrade, double virtualSLPrice, double virtualTPPrice, string comment);
    void SetBasketSlPrice(double slPrice);
    void SwitchTradeToVirtualSLTP(ulong ticket);
    void SetTradeToVirtualSLTP(ulong ticket, double slPrice, double tpPrice);
    bool GetTradeByIndex(int index, Trade &trade);
    bool RemoveTradeByIndex(int index);
    void CloseBasketOrders();
    bool UpdateSLTP(int recoverySLPoints, double tpPrice);
    void CloseFirstOrder();
    void OnTick();

private:
    void UpdateAvgTpForBasketTrades();
    void UpdateVirtualSlForBasketTrades();
    void UpdateCurrentTrades();
};

CTradingBasket::CTradingBasket(string symbol, long magicNumber)
{
    _symbol = symbol;
    _magicNumber = magicNumber;
    _basketStatus = BASKET_CLOSED;
    ArrayResize(_trades, 0);
}

CTradingBasket::~CTradingBasket()
{
    ArrayFree(_trades);
}

void CTradingBasket::SetBasketAvgTpPrice(double tpPrice)
{
    _basketAvgTpPrice = tpPrice;
    CTradingBasket::UpdateAvgTpForBasketTrades();
}

void CTradingBasket::SetBasketSlPrice(double slPrice)
{
    if (IsEmpty())
        return;

    CPositionInfo _position;
    CTrade _trade;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, slPrice, _position.TakeProfit());
        }
    }
}

void CTradingBasket::SetTradeToVirtualSLTP(ulong ticket, double slPrice, double tpPrice)
{
    CPositionInfo _position;
    CTrade _trade;
    for (int i = Count() - 1; i >= 0; i--)
    {
        if (_trades[i].Ticket() != ticket)
            continue;

        _trades[i].SwitchToVirtualSLTP(slPrice, tpPrice);
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, 0, 0);
        }
    }
}

void CTradingBasket::CloseFirstOrder()
{
    CPositionInfo _position;
    CTrade _trade;
    if (ArraySize(_trades) > 0)
    {
        ulong ticket = _trades[0].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            if (_trade.PositionClose(ticket, ULONG_MAX))
            {
                ArrayRemove(_trades, 0, 1);
            }
            else
            {
                _reporter.ReportError("Failed to close first order of the basket");
            }
        }
        else
        {
            _reporter.ReportError("Failed to close first order of the basket");
        }
    }
}

bool CTradingBasket::UpdateSLTP(int recoverySLPoints, double tpPrice)
{
    CTrade _trade;
    CPositionInfo _position;
    double avgOpenPrice = AverageOpenPrice();
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            double slPrice = 0;
            if (_position.PositionType() == POSITION_TYPE_BUY)
            {
                slPrice = recoverySLPoints == 0 ? 0 : avgOpenPrice - (recoverySLPoints * SymbolInfoDouble(_symbol, SYMBOL_POINT));
            }
            else if (_position.PositionType() == POSITION_TYPE_SELL)
            {
                slPrice = recoverySLPoints == 0 ? 0 : avgOpenPrice + (recoverySLPoints * SymbolInfoDouble(_symbol, SYMBOL_POINT));
            }

            if (!_trade.PositionModify(ticket, slPrice, tpPrice))
            {
                return (false);
            }
        }
    }

    return (true);
}

bool CTradingBasket::GetTradeByIndex(int index, Trade &trade)
{
    if (index > Count() || index < 0)
        return (false);
    trade = _trades[index];
    return (true);
}

bool CTradingBasket::RemoveTradeByIndex(int index)
{
    if (index > Count() || index < 0)
        return (false);
    ArrayRemove(_trades, index, 1);
    return (true);
}
void CTradingBasket::SwitchTradeToVirtualSLTP(ulong ticket)
{
    if (IsEmpty())
        return;

    CPositionInfo _position;
    CTrade _trade;
    for (int i = Count() - 1; i >= 0; i--)
    {
        if (_trades[i].Ticket() != ticket)
        {
            continue;
        }
        Trade trade = _trades[i];
        trade.SwitchToVirtualSLTP();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, trade.StopLoss(), trade.TakeProfit());
        }
    }
}

bool CTradingBasket::OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string &message, Trade &newTrade, int virtualSLPoints, int virtualTPPoints, string comment)
{
    double slPrice = 0, tpPrice = 0;
    double ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
    double spread = ask - bid;
    int spread_points = (int)MathRound(spread / _Point);
    if (slPoints <= spread_points)
    {
        message = "SL points is less than the spread points";
        return (false);
    }

    if (orderType == ORDER_TYPE_BUY)
    {
        slPrice = slPoints > 0 ? price - (slPoints * _Point) : 0;
        tpPrice = tpPoints > 0 ? price + (tpPoints * _Point) : 0;
    }
    else
    {
        slPrice = slPoints > 0 ? price + (slPoints * _Point) : 0;
        tpPrice = tpPoints > 0 ? price - (tpPoints * _Point) : 0;
    }

    return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade, virtualSLPoints, virtualTPPoints, comment);
}

bool CTradingBasket::OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice,
                                        string &message, Trade &newTrade, double virtualSLPrice, double virtualTPPrice, string comment)
{
   if(Count() == 0) {
      firstOrderVolume = volume;
   }
   
    if (_basketStatus == BASKET_CLOSING)
    {
        // TODO: error reporting
        message = StringFormat("Basket is %s, cannot receive orders now", EnumToString(_basketStatus));
        return (false);
    }

    MqlTradeResult result;
    CTrade _trade;
    _trade.SetExpertMagicNumber(_magicNumber);
    _trade.PositionOpen(_symbol, orderType, volume, price, slPrice, tpPrice, comment);
    _trade.Result(result);

    if (result.retcode > 0)
    {
        Trade trade;
        trade.Init(result.order, _trade.RequestMagic(), _trade.RequestSymbol(), orderType,
                   result.price, result.volume, 0, _trade.RequestSL(), _trade.RequestTP(),
                   virtualSLPrice, virtualTPPrice, result.comment);

        ArrayResize(_trades, ArraySize(_trades) + 1);
        _trades[ArraySize(_trades) - 1] = trade;
        newTrade = trade;
        _basketStatus = BASKET_OPEN;
        lastOrderCount++;
    }
    else
    {
        // TODO
        message = StringFormat("Order failed: %s", result.retcode);
        return (false);
    }

    return (true);
}

double CTradingBasket::Volume()
{
    double totalVolume = 0.0;
    for (int i = 0; i < ArraySize(_trades); i++)
    {
        totalVolume += _trades[i].Volume();
    }
    return totalVolume;
}

double CTradingBasket::Volume(ENUM_ORDER_TYPE orderType)
{
    double totalVolume = 0.0;
    for (int i = 0; i < ArraySize(_trades); i++)
    {
        if (_trades[i].OrderType() == orderType)
            totalVolume += _trades[i].Volume();
    }
    return totalVolume;
}

double CTradingBasket::AverageOpenPrice()
{
    double totalPrice = 0.0;
    double totalVolume = 0.0;
    for (int i = 0; i < Count(); i++)
    {
        totalVolume += _trades[i].Volume();
        totalPrice += _trades[i].OpenPrice() * _trades[i].Volume();
    }

    if (IsEmpty() || totalVolume == 0)
        return 0;
    double avgPrice = totalPrice / totalVolume;
    return avgPrice;
}

double CTradingBasket::Profit()
{
    CPositionInfo _position;
    double totalProfit = 0.0;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            totalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
    }
    return totalProfit;
}

int CTradingBasket::Count() { return ArraySize(_trades); }
string CTradingBasket::Symbol() { return _symbol; }
bool CTradingBasket::HasOpenedTrades() { return Count() > 0; }
bool CTradingBasket::IsEmpty() { return Count() == 0; }
ENUM_BASKET_STATUS CTradingBasket::Status() { return _basketStatus; }

bool CTradingBasket::FirstTrade(Trade &trade)
{
    if (Count() > 0)
    {
        trade = _trades[0];
        return (true);
    }
    return (false);
}

bool CTradingBasket::LastTrade(Trade &trade)
{
    if (Count() > 0)
    {
        trade = _trades[Count() - 1];
        return (true);
    }
    return (false);
}

void CTradingBasket::CloseBasketOrders()
{
    CTrade _trade;
    CPositionInfo _position;
    _basketStatus = BASKET_CLOSING;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            if (_trade.PositionClose(ticket, ULONG_MAX))
            {
                ArrayRemove(_trades, i, 1);
            }
            else
            {
                PrintFormat("Failed to close position %d", ticket);
            }
        }
    }

    if (IsEmpty())
    {
        _basketStatus = BASKET_CLOSED;
    }
}

void CTradingBasket::UpdateCurrentTrades()
{
    CPositionInfo _position;
    // Cleanup the basket
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (!_position.SelectByTicket(ticket))
        {
            ArrayRemove(_trades, i, 1);
        }
    }

    if (ArraySize(_trades) == 0)
    {
        _basketStatus = BASKET_CLOSED;
        lastOrderCount = 0;
    }
}

void CTradingBasket::OnTick()
{
    if (_basketStatus == BASKET_CLOSING)
    {
        CTradingBasket::CloseBasketOrders();
    }

    CTradingBasket::UpdateCurrentTrades();
}

/**********************************************/

void CTradingBasket::UpdateAvgTpForBasketTrades()
{
    if (IsEmpty())
        return;
    CPositionInfo _position;
    CTrade _trade;

    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, _position.StopLoss(), _basketAvgTpPrice);
        }
    }
}

void CTradingBasket::UpdateVirtualSlForBasketTrades()
{
    if (IsEmpty())
        return;
}