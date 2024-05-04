#property strict

#ifdef __MQL5__
#include <Object.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#else

#endif
#include "TradingBasket.mqh"
#include "TradingStatus.mqh"
#include "..\Filters\FilterManager.mqh"
#include "..\Constants.mqh"
#include "..\UI\Reporter.mqh"
#include "..\UI\UIHelper.mqh"
#ifdef __MQL4__
#include "Trade_mql4.mqh"
#include "PositionInfo.mqh"
#endif

class CTradingManager : public CObject
{

protected:
    CConstants *_constants;
    CUIHelper *_uiHelper;
    CTradingBasket *_basket;
    CReporter *_reporter;
    CTradingStatusManager *_tradingStatusManager;

    CTrade _trade;
    CPositionInfo _position;

public:
    CTradingManager(CConstants *constnats, CUIHelper *uiHelper, CTradingBasket *basket, CReporter *reporter, CTradingStatusManager *tradingStatusManager)
    {
        _constants = constnats;
        _uiHelper = uiHelper;
        _basket = basket;
        _reporter = reporter;
        _tradingStatusManager = tradingStatusManager;
    }

public:
    virtual bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints,
                                     string &message, Trade &newTrade, int virtualSLPoints = 0, int virtualTPPoints = 0, string comment = "")
    {
        double slPrice = 0, tpPrice = 0;
        double virtualSLPrice = 0, virtualTPPrice = 0;
        double ask = _constants.Ask(_basket.Symbol());
        double bid = _constants.Bid(_basket.Symbol());
        double spread = ask - bid;
        int spread_points = (int)MathRound(spread / _constants.Point(_basket.Symbol()));
        if (slPoints <= spread_points && virtualSLPoints <= spread_points)
        {
            message = "SL points is less than the spread points";
            _reporter.ReportError(message);
            return (false);
        }

        if (orderType == ORDER_TYPE_BUY)
        {
            slPrice = slPoints > 0 ? price - (slPoints * _constants.Point(_basket.Symbol())) : 0;
            tpPrice = tpPoints > 0 ? price + (tpPoints * _constants.Point(_basket.Symbol())) : 0;
            virtualSLPrice = virtualSLPoints > 0 ? price - (virtualSLPoints * _constants.Point(_basket.Symbol())) : 0;
            virtualTPPrice = virtualTPPoints > 0 ? price + (virtualTPPoints * _constants.Point(_basket.Symbol())) : 0;
        }
        else
        {
            slPrice = slPoints > 0 ? price + (slPoints * _constants.Point(_basket.Symbol())) : 0;
            tpPrice = tpPoints > 0 ? price - (tpPoints * _constants.Point(_basket.Symbol())) : 0;
            virtualSLPrice = virtualSLPoints > 0 ? price + (virtualSLPoints * _constants.Point(_basket.Symbol())) : 0;
            virtualTPPrice = virtualTPPoints > 0 ? price - (virtualTPPoints * _constants.Point(_basket.Symbol())) : 0;
        }
        return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade, virtualSLPrice, virtualTPPrice, comment);
    }

    virtual bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice,
                                    string &message, Trade &newTrade, double virtualSLPrice = 0, double virtualTPPrice = 0, string comment = "")
    {
        if (!_tradingStatusManager.IsTradingAllowed(_basket.Symbol(), TimeCurrent(), NULL))
        {
            _reporter.ReportWarning("Trading is not allowed because of Profit/Loss rules");
            return (false);
        }

        bool success = _basket.OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade, virtualSLPrice, virtualTPPrice, comment);
        if (success)
        {
            _reporter.ReportTradeOpen(orderType);
        }
        return success;
    }

    virtual void OnTick()
    {
        _basket.OnTick();
    }
};