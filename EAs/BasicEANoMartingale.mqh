#include "ExpertBase.mqh"
#include "..\Signals\EMATrendSignal.mqh"
#include "..\Signals\SpikeSignal.mqh"

class BasicEANoMartingale : public CExpertBase
{

public:
    BasicEANoMartingale(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
                        RiskOptions &riskOptions, CPnLManager *pnlManager, CTradingStatusManager *tradingStatusManager)
        : CExpertBase(symbol, maxSpread, defaultSLPoints, defaultTPPoints, riskOptions, pnlManager, tradingStatusManager) {}

protected:
    void RegisterFilters(CFilterManager *filterManager)
    {
    }

    void RegisterBuySignals(CSignalManager *signalManager)
    {
         signalManager.RegisterSignal(new CMACDSignal(pSymbol, PERIOD_M5, MACD_HISTOGRAM, 12, 26, 9, false));
    }

    void RegisterSellSignals(CSignalManager *signalManager)
    {
         signalManager.RegisterSignal(new CMACDSignal(pSymbol, PERIOD_M5, MACD_HISTOGRAM, 12, 26, 9, false));
    }

    void OnBuySignal()
    {
        int slPoints = _defaultSLPoints;
        int tpPoints = _defaultTPPoints;
        double ask = _constants.Ask(pSymbol);

        if (_buyBasket.IsEmpty())
        {
            ENUM_ORDER_TYPE direction = ORDER_TYPE_BUY;
            double price = ask;

            double slPrice = price + (slPoints * _constants.Point(pSymbol));
            double lots = _normalLotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
            string message;
            Trade trade;
            if (!buyManager.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test buy"))
            {
                _reporter.ReportError(StringFormat("Failed to open buy trade: %s", message));
            }
        }
    }

    void OnSellSignal()
    {
        int slPoints = _defaultSLPoints;
        int tpPoints = _defaultTPPoints;
        double bid = _constants.Bid(pSymbol);

        if (_sellBasket.IsEmpty())
        {
            ENUM_ORDER_TYPE direction = ORDER_TYPE_SELL;
            double price = bid;

            double slPrice = price + (slPoints * _constants.Point(pSymbol));
            double lots = _normalLotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
            string message;
            Trade trade;
            if (!sellManager.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test sell"))
            {
                _reporter.ReportError(StringFormat("Failed to open sell trade: %s", message));
            }
        }
    }
};