#include <Object.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include "TradingBasket.mqh"
#include "..\Filters\FilterManager.mqh"
#include "..\Constants.mqh"
#include "..\UI\Reporter.mqh"

#property strict

class CTradingManager : public CObject
{

protected:
    CConstants *constants;
    CTradingBasket *_basket;
    CReporter *_reporter;
    CFilterManager _entryFilters;
    CFilterManager _exitFilters;

    CTrade _trade;
    CPositionInfo _position;

public:
    CTradingManager(CTradingBasket *basket, CReporter *reporter, CFilterManager &entryFilters, CFilterManager &exitFilters)
    {
        _basket = basket;
        _reporter = reporter;
        _entryFilters = entryFilters;
        _exitFilters = exitFilters;
    }

public:
    virtual bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints,
                                     string &message, Trade &newTrade, int virtualSLPoints = 0, int virtualTPPoints = 0, string comment = "")
    {
        double slPrice = 0, tpPrice = 0;
        double virtualSLPrice = 0, virtualTPPrice = 0;
        double ask = SymbolInfoDouble(_basket.Symbol(), SYMBOL_ASK);
        double bid = SymbolInfoDouble(_basket.Symbol(), SYMBOL_BID);
        double spread = ask - bid;
        int spread_points = (int)MathRound(spread / _Point);
        if (slPoints <= spread_points && virtualSLPoints <= spread_points)
        {
            message = "SL points is less than the spread points";
            return (false);
        }

        if (orderType == ORDER_TYPE_BUY)
        {
            slPrice = slPoints > 0 ? price - (slPoints * _Point) : 0;
            tpPrice = tpPoints > 0 ? price + (tpPoints * _Point) : 0;
            virtualSLPrice = virtualSLPoints > 0 ? price - (virtualSLPoints * _Point) : 0;
            virtualTPPrice = virtualTPPoints > 0 ? price + (virtualTPPoints * _Point) : 0;
        }
        else
        {
            slPrice = slPoints > 0 ? price + (slPoints * _Point) : 0;
            tpPrice = tpPoints > 0 ? price - (tpPoints * _Point) : 0;
            virtualSLPrice = virtualSLPoints > 0 ? price + (virtualSLPoints * _Point) : 0;
            virtualTPPrice = virtualTPPoints > 0 ? price - (virtualTPPoints * _Point) : 0;
        }
        return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade, virtualSLPrice, virtualTPPrice, comment);
    }

    virtual bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice,
                                    string &message, Trade &newTrade, double virtualSLPrice = 0, double virtualTPPrice = 0, string comment = "")
    {

        if (_entryFilters.AllAgree())
        {
            bool success = _basket.OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade, virtualSLPrice, virtualTPPrice, comment);
            _reporter.ReportTradeOpen(orderType);
            return success;
        }
        else
        {
            _reporter.ReportWarning("Some filters don\'t agree to open more trades");
            return (false);
        }
    }

    virtual void OnTick()
    {
        _basket.OnTick();
    }
};