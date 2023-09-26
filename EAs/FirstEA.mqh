#include "ExpertBase.mqh"
#include "..\Signals\EMATrendSignal.mqh"

class CFirstEA : public CExpertBase
{

public:
    CFirstEA(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
             RecoveryOptions &options, RiskOptions &riskOptions, CPnLManager *pnlManager, CTradingStatusManager *tradingStatusManager)
        : CExpertBase(symbol, maxSpread, defaultSLPoints, defaultTPPoints, options, riskOptions, pnlManager, tradingStatusManager) {}

protected:
    void RegisterFilters(CFilterManager *filterManager)
    {
    }

    void RegisterBuySignals(CSignalManager *signalManager)
    {
        // signalManager.RegisterSignal(new CBandsSignal(pSymbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, false));
        // signalManager.RegisterSignal(new CMACDSignal(pSymbol, PERIOD_M5, MACD_SIGNAL_LINE, 12, 26, 9, false));
        signalManager.RegisterSignal(new CEMASignal(pSymbol, PERIOD_M5, 21, MODE_EMA, PRICE_CLOSE, 0.0001));
        // signalManager.RegisterSignal(new CMACDSignal(pSymbol, PERIOD_M5, MACD_HISTOGRAM, 12, 26, 9, false));
    }

    void RegisterSellSignals(CSignalManager *signalManager)
    {
        // signalManager.RegisterSignal(new CBandsSignal(pSymbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, false));
        // signalManager.RegisterSignal(new CMACDSignal(pSymbol, PERIOD_M5, MACD_SIGNAL_LINE, 12, 26, 9, false));
        signalManager.RegisterSignal(new CEMASignal(pSymbol, PERIOD_M5, 21, MODE_EMA, PRICE_CLOSE, 0.0001));
        // signalManager.RegisterSignal(new CMACDSignal(pSymbol, PERIOD_M5, MACD_HISTOGRAM, 12, 26, 9, false));
    }

    void OnBuySignal()
    {
        int slPoints = _defaultSLPoints;
        int tpPoints = _defaultTPPoints;
        double ask = SymbolInfoDouble(pSymbol, SYMBOL_ASK);

        if (_buyBasket.IsEmpty())
        {
            ENUM_ORDER_TYPE direction = ORDER_TYPE_BUY;
            double price = ask;

            double slPrice = price + (slPoints * _constants.Point(pSymbol));
            double lots = _lotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
            string message;
            Trade trade;
            if (!buyRecovery.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test buy"))
            {
                PrintFormat("Failed to open sell trade: %s", message);
            }
        }
    }

    void OnSellSignal()
    {
        int slPoints = _defaultSLPoints;
        int tpPoints = _defaultTPPoints;
        double bid = SymbolInfoDouble(pSymbol, SYMBOL_BID);

        if (_sellBasket.IsEmpty())
        {
            ENUM_ORDER_TYPE direction = ORDER_TYPE_SELL;
            double price = bid;

            double slPrice = price + (slPoints * _constants.Point(pSymbol));
            double lots = _lotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
            string message;
            Trade trade;
            if (!sellRecovery.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test sell"))
            {
                PrintFormat("Failed to open sell trade: %s", message);
            }
        }
    }
};