
#include "ExpertBase.mqh"
#include "..\Signals\SignalBase.mqh"
#include "..\Trade\TradingBasket.mqh"

class CBoxSignal : public CSignalBase
{
private:
    string pSymbol;
    ENUM_SIGNAL _prevSignal;
    double rangePercentage;
    double maxRectangleSize;
    int highBarIndex;
    int lowBarIndex;
    double maCurrent[1];
    double maPrevious[1];

    ENUM_SIGNAL CalcSignal();
    bool IsWithinTradeTime();
    bool IsPriceWithinMA();

protected:
public:
    ENUM_SIGNAL GetSignal();
    CBoxSignal(string symbol, double rangePerc, double maxRectSize, int highBar, int lowBar);
    ~CBoxSignal() {}
    virtual bool ValidateInputs() { return true; }
};

CBoxSignal::CBoxSignal(string symbol, double rangePerc, double maxRectSize, int highBar, int lowBar)
{
    _prevSignal = SIGNAL_NEUTRAL;
    rangePercentage = rangePerc;
    maxRectangleSize = maxRectSize;
    pSymbol = symbol;
    highBarIndex = highBar;
    lowBarIndex = lowBar;
}

bool CBoxSignal::IsPriceWithinMA()
{
    return maCurrent[0] < iHigh(pSymbol, PERIOD_CURRENT, highBarIndex) && maCurrent[0] > iLow(pSymbol, PERIOD_CURRENT, lowBarIndex);
}

ENUM_SIGNAL CBoxSignal::CalcSignal()
{
    if (rangePercentage <= maxRectangleSize && IsPriceWithinMA())
    {

        if (maCurrent[0] > maPrevious[0] && Ask > maCurrent[0])
        {
            return SIGNAL_SELL;
        }

        if (maCurrent[0] < maPrevious[0] && Bid < maCurrent[0])
        {
            return SIGNAL_BUY;
        }
    }

    return SIGNAL_NEUTRAL;
}

ENUM_SIGNAL CBoxSignal::GetSignal(void)
{
    ENUM_SIGNAL signal = CalcSignal();

    if (_prevSignal != signal)
    {
        _prevSignal = signal;
        return signal;
    }

    return SIGNAL_NEUTRAL;
}

class CBoxEA : public CExpertBase
{

public:
    CBoxEA(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
           MartingaleOptions &options, RiskOptions &riskOptions, CPnLManager *pnlManager, CTradingStatusManager *tradingStatusManager)
        : CExpertBase(symbol, maxSpread, defaultSLPoints, defaultTPPoints, options, riskOptions, pnlManager, tradingStatusManager) {}

protected:
    void RegisterFilters(CFilterManager *filterManager)
    {
    }

    void RegisterBuySignals(CSignalManager *signalManager)
    {
        signalManager.RegisterSignal(new CBoxSignal(pSymbol, 0.5, 0.2, 0, 1));
    }

    void RegisterSellSignals(CSignalManager *signalManager)
    {
        signalManager.RegisterSignal(new CBoxSignal(pSymbol));
    }

    void OnBuySignal()
    {
        double ask = _constants.Ask(pSymbol);
        if (_buyBasket.IsEmpty())
        {
            HandleTradeSignal(ask, ORDER_TYPE_BUY, _buyBasket, buyRecovery, "test buy");
        }
    }

    void OnSellSignal()
    {
        double bid = _constants.Bid(pSymbol);
        if (_sellBasket.IsEmpty())
        {
            HandleTradeSignal(bid, ORDER_TYPE_SELL, _sellBasket, sellRecovery, "test sell");
        }
    }

    void HandleTradeSignal(double price, ENUM_ORDER_TYPE direction, CTradingBasket *basket, CTradingManager *recovery, string comment)
    {
        int slPoints = _defaultSLPoints;
        int tpPoints = _defaultTPPoints;

        double slPrice = price + (slPoints * _constants.Point(pSymbol));
        double lots = _lotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
        string message;
        Trade trade;
        if (!recovery.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, comment))
        {
            PrintFormat("Failed to open %s trade: %s", (direction == ORDER_TYPE_BUY ? "buy" : "sell"), message);
        }
    }
};