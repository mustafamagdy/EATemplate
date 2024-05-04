#ifdef __MQL5__
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\DealInfo.mqh>
#else
#include "Trade_mql4.mqh"
#include "PositionInfo.mqh"
#endif
#include <Object.mqh>
#include "Trade.mqh"
#include "..\UI\Reporter.mqh"
#include "..\Common.mqh"
#include "..\Constants.mqh"
#include "..\UI\UIHelper.mqh"

enum ENUM_BASKET_STATUS
{
    BASKET_OPEN = 0,
    BASKET_CLOSING = 1,
    BASKET_CLOSED = 2,
};

class CTradingBasket : public CObject
{
private:
    CReporter *_reporter;
    CConstants *_constants;
    CUIHelper *_uiHelper;

    Trade _trades[];
    ENUM_BASKET_STATUS _basketStatus;
    long _magicNumber;
    string pSymbol;
    double basketAvgTpPrice;
    double basketAvgSlPrice;
    int lastOrderCount;
    double firstOrderVolume;
    double profit;
    double totalCommission;

public:
    CTradingBasket(string symbol, long magicNumber, CReporter *reporter, CConstants *constants, CUIHelper *uiHelper);
    ~CTradingBasket();

public:
    double Volume();
    double Volume(ENUM_ORDER_TYPE orderType);
    long MagicNumber() { return _magicNumber; }
    double AverageOpenPrice();
    double Profit() { return profit; }
    void ResetPnL() { profit = 0; }
    int Count();
    string Symbol();
    bool HasOpenedTrades();
    bool IsEmpty();
    ENUM_BASKET_STATUS Status();
    bool FirstTrade(Trade &trade);
    bool LastTrade(Trade &trade);
    int LastOrderCount() { return lastOrderCount; }
    double FirstOrderVolume() { return firstOrderVolume; }
    string BasketId() { return StringFormat("basket_%d", _magicNumber); }
    string GetTpLineName() { return StringFormat("%s_tp", BasketId()); }

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
    void ClosePartial(double ratioToClose);
    double CTradingBasket::TotalCommission() { return 0; /*return totalCommission; */ }
    double TotalSwap();
    void OnTick();

private:
    void CheckPnL();
    void UpdateAvgTpForBasketTrades();
    void UpdateVirtualSlForBasketTrades();
    void UpdateCurrentTrades();
};

CTradingBasket::CTradingBasket(string symbol, long magicNumber, CReporter *reporter, CConstants *constants, CUIHelper *uiHelper)
{
    pSymbol = symbol;
    _magicNumber = magicNumber;
    _reporter = reporter;
    _constants = constants;
    _uiHelper = uiHelper;
    _basketStatus = BASKET_CLOSED;
    ArrayResize(_trades, 0);    
}

CTradingBasket::~CTradingBasket()
{
    ArrayFree(_trades);
}

void CTradingBasket::SetBasketAvgTpPrice(double tpPrice)
{
    basketAvgTpPrice = tpPrice;
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
            double commission = _position.Commission();
            if (_trade.PositionClose(ticket, ULONG_MAX))
            {
                totalCommission -= commission;
                ArrayRemove(_trades, 0, 1);
                // Do we need to update profit?
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

void CTradingBasket::ClosePartial(double ratioToClose)
{
    if (ratioToClose <= 0 || ratioToClose >= 1)
    {
        Print("Invalid ratio provided. Should be between 0 and 1.");
        return;
    }

    CTrade _trade;
    CPositionInfo _position;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            double currentVolume = _position.Volume();
            double volumeToClose = currentVolume * ratioToClose;
            double totalCommissionForPosition = _position.Commission();
            double commissionClosedPortion = totalCommissionForPosition * (volumeToClose / currentVolume);

            if (_trade.PositionClosePartial(ticket, volumeToClose, ULONG_MAX))
            {
                totalCommission -= commissionClosedPortion;
                ArrayRemove(_trades, i, 1);
            }
            else
            {
                PrintFormat("Failed to close position %d", ticket);
            }
        }
    }
}

double CTradingBasket::TotalSwap()
{
return 0;
    double totalSwap = 0.0;
    CPositionInfo _position;
    for (int i = 0; i < Count(); i++)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            totalSwap += _position.Swap();
        }
    }
    return totalSwap;
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
                slPrice = recoverySLPoints == 0 ? 0 : avgOpenPrice - (recoverySLPoints * SymbolInfoDouble(pSymbol, SYMBOL_POINT));
            }
            else if (_position.PositionType() == POSITION_TYPE_SELL)
            {
                slPrice = recoverySLPoints == 0 ? 0 : avgOpenPrice + (recoverySLPoints * SymbolInfoDouble(pSymbol, SYMBOL_POINT));
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
    double ask = _constants.Ask(pSymbol);
    double bid = _constants.Bid(pSymbol);
    double spread = ask - bid;
    int spread_points = (int)MathRound(spread / _constants.Point(pSymbol));
    if (slPoints <= spread_points)
    {
        message = "SL points is less than the spread points";
        _reporter.ReportError(message);
        return (false);
    }

    if (orderType == ORDER_TYPE_BUY)
    {
        slPrice = slPoints > 0 ? price - (slPoints * _constants.Point(pSymbol)) : 0;
        tpPrice = tpPoints > 0 ? price + (tpPoints * _constants.Point(pSymbol)) : 0;
    }
    else
    {
        slPrice = slPoints > 0 ? price + (slPoints * _constants.Point(pSymbol)) : 0;
        tpPrice = tpPoints > 0 ? price - (tpPoints * _constants.Point(pSymbol)) : 0;
    }

    return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade, virtualSLPoints, virtualTPPoints, comment);
}

bool CTradingBasket::OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice,
                                        string &message, Trade &newTrade, double virtualSLPrice, double virtualTPPrice, string comment)
{
    if (Count() == 0)
    {
        firstOrderVolume = volume;
    }

    if (_basketStatus == BASKET_CLOSING)
    {
        message = StringFormat("Basket is %s, cannot receive orders now", EnumToString(_basketStatus));
        _reporter.ReportError(message);
        return (false);
    }

    MqlTradeResult result;
    CTrade _trade;
    CDealInfo _deal;
    _trade.SetExpertMagicNumber((int)_magicNumber);
    _trade.PositionOpen(pSymbol, orderType, volume, price, slPrice, tpPrice, comment);
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
        totalCommission += _deal.Commission(); 
        
       if(Count() == 1)
       {
           _uiHelper.DrawPriceLine(GetTpLineName(), virtualTPPrice, clrGreen, STYLE_SOLID, 2);
       }       
    }
    else
    {
        message = StringFormat("Order failed: %s", result.retcode);
        _reporter.ReportError(message);
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

int CTradingBasket::Count() { return ArraySize(_trades); }
string CTradingBasket::Symbol() { return pSymbol; }
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
            double commission = _position.Commission();
            if (_trade.PositionClose(ticket, ULONG_MAX))
            {
                totalCommission -= commission;
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
        profit = 0;
        totalCommission = 0;
    }
}

void CTradingBasket::UpdateCurrentTrades()
{
    CPositionInfo _position;
    profit = 0;
    // Cleanup the basket
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (!_position.SelectByTicket(ticket))
        {
            ArrayRemove(_trades, i, 1);
        }
        else
        {
            profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
    }

    if (ArraySize(_trades) == 0)
    {
        _basketStatus = BASKET_CLOSED;
        lastOrderCount = 0;
        _uiHelper.RemoveLine(GetTpLineName());
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
            _trade.PositionModify(ticket, _position.StopLoss(), basketAvgTpPrice);
        }
    }
}

void CTradingBasket::UpdateVirtualSlForBasketTrades()
{
    if (IsEmpty())
        return;
}