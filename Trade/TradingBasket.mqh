#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Object.mqh>
#include "Trade.mqh"

enum ENUM_BASKET_STATUS
{
    BASKET_OPEN = 0,
    BASKET_CLOSING = 1,
    BASKET_CLOSED = 2
};

class CTradingBasket : CObject
{
private:
    CTrade _trade;
    CPositionInfo _position;
    Trade _trades[];
    ENUM_BASKET_STATUS _basketStatus;
    long _magicNumber;
    string _symbol;
    double _basketAvgTpPrice;
    double _basketAvgSlPrice;

public:
    CTradingBasket(string symbol, long magicNumber);
    ~CTradingBasket();

public:
    double Volume();
    double Volume(ENUM_ORDER_TYPE orderType);
    double AverageOpenPrice();
    double Profit();
    int Count();
    string Symbol();
    bool HasOpenedTrades();
    bool IsEmpty();
    ENUM_BASKET_STATUS Status();
    bool FirstTrade(Trade &trade);
    bool LastTrade(Trade &trade);

public:
    void SetBasketAvgTpPrice(double tpPrice);
    bool AddTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message);
    bool AddTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string comment, string &message);
    void SetBasketOriginalSlPrice(double slPrice);
    void SetBasketSlPrice(double slPrice);
    void CloseBasketOrders();
    void OnTick();

private:
    void _UpdateAvgTpForBasketTrades();
    void _UpdateVirtualSlForBasketTrades();
    void _UpdateCurrentTrades();
};

CTradingBasket::CTradingBasket(string symbol, long magicNumber)
{
    _symbol = symbol;
    _magicNumber = magicNumber;
    _trade.SetExpertMagicNumber(magicNumber);
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
    CTradingBasket::_UpdateAvgTpForBasketTrades();
}

void CTradingBasket::SetBasketSlPrice(double slPrice)
{
    if (IsEmpty())
        return;

    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, slPrice, _position.TakeProfit());
        }
    }
}

void CTradingBasket::SetBasketOriginalSlPrice(double basketAvgSlPrice)
{
    _basketAvgSlPrice = basketAvgSlPrice;
    CTradingBasket::_UpdateVirtualSlForBasketTrades();
}

bool CTradingBasket::AddTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message)
{
    double slPrice = 0, tpPrice = 0;
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double spread = ask - bid;
    int spread_points = (int)MathRound(spread / SymbolInfoDouble(Symbol(), SYMBOL_POINT));
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

    return AddTradeWithPrice(volume, price, orderType, slPrice, tpPrice, comment, message);
}

bool CTradingBasket::AddTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string comment, string &message)
{
    if (_basketStatus == BASKET_CLOSING)
    {
        // TODO: error reporting
        message = StringFormat("Basket is %s, cannot receive orders now", EnumToString(_basketStatus));
        return (false);
    }

    MqlTradeResult result;
    _trade.PositionOpen(Symbol(), orderType, volume, price, slPrice, tpPrice, comment);
    _trade.Result(result);

    if (result.retcode > 0)
    {
        Trade trade;
        trade.Init(result.order, _trade.RequestMagic(), _trade.RequestSymbol(), orderType,
                   result.price, result.volume, 0, _trade.RequestSL(), _trade.RequestTP(),
                   result.comment);

        ArrayResize(_trades, ArraySize(_trades) + 1);
        _trades[ArraySize(_trades) - 1] = trade;

        _basketStatus = BASKET_OPEN;
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
    double totalProfit = 0.0;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (PositionSelectByTicket(ticket))
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
    _basketStatus = BASKET_CLOSING;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (PositionSelectByTicket(ticket))
        {
            if (_trade.PositionClose(ticket, ULONG_MAX))
            {
                ArrayRemove(_trades, i, 1);
            }
            else
            {
                // TODO
            }
        }
    }

    if (IsEmpty())
    {
        _basketStatus = BASKET_CLOSED;
    }
}

void CTradingBasket::_UpdateCurrentTrades()
{
    // Cleanup the basket
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (!PositionSelectByTicket(ticket))
        {
            ArrayRemove(_trades, i, 1);
        }
    }

    // Close orders and remove them if SL/TP hit
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (!PositionSelectByTicket(ticket))
        {
            continue;
        }

        // check virtual SL/TP if either, close and remove
        string symbol = PositionGetString(POSITION_SYMBOL);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double bidPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
        double askPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double takeProfit = _trades[i].VirtualTakeProfit();
        double stopLoss = _trades[i].VirtualStopLoss();
        bool closed = false;

        if ((type == POSITION_TYPE_BUY && bidPrice >= takeProfit) ||
            (type == POSITION_TYPE_SELL && askPrice <= takeProfit))
        {
            closed = _trade.PositionClose(ticket, ULONG_MAX);
        }
        else if ((type == POSITION_TYPE_BUY && bidPrice <= stopLoss) ||
                 (type == POSITION_TYPE_SELL && askPrice >= stopLoss))
        {
            closed = _trade.PositionClose(ticket, ULONG_MAX);
        }

        if (closed)
        {
            ArrayRemove(_trades, i, 1);
        }
    }

    if (ArraySize(_trades) == 0)
    {
        _basketStatus = BASKET_CLOSED;
    }
}

void CTradingBasket::OnTick()
{
    CTradingBasket::_UpdateCurrentTrades();
}

/**********************************************/

void CTradingBasket::_UpdateAvgTpForBasketTrades()
{
    if (IsEmpty())
        return;

    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, _position.StopLoss(), _basketAvgTpPrice);
        }
    }
}

void CTradingBasket::_UpdateVirtualSlForBasketTrades()
{
    if (IsEmpty())
        return;
}