
#include "ExpertBase.mqh"
#include "..\Signals\SignalBase.mqh"

class CBoxSignal : public CSignalBase
{
private:
    double rangePercentage;
    double maxRectangleSize;
    string tradeStartTime;
    string tradeEndTime;
    int highBarIndex;
    int lowBarIndex;
    double* priceData; 
    double maCurrent[1];
    double maPrevious[1];
    
    ENUM_SIGNAL CalcSignal();
    bool IsWithinTradeTime();
    bool IsPriceWithinMA();

protected:
public:
    ENUM_SIGNAL GetSignal();
    CBoxSignal(string symbol, double rangePerc, double maxRectSize, 
               string tradeStart, string tradeEnd, int highBar, int lowBar, double* prices);
    ~CBoxSignal() {}
    virtual bool ValidateInputs() { return true; }
};

CBoxSignal::CBoxSignal(string symbol, double rangePerc, double maxRectSize, 
                       string tradeStart, string tradeEnd, int highBar, int lowBar, double* prices)
{
    _prevSignal = SIGNAL_NEUTRAL;
    rangePercentage = rangePerc;
    maxRectangleSize = maxRectSize;
    tradeStartTime = tradeStart;
    tradeEndTime = tradeEnd;
    highBarIndex = highBar;
    lowBarIndex = lowBar;
    priceData = prices;
}

bool CBoxSignal::IsWithinTradeTime()
{
    datetime currentTime = TimeCurrent();
    datetime startTime = StringToTime(tradeStartTime);
    datetime endTime = StringToTime(tradeEndTime);
    return (currentTime > startTime && currentTime < endTime);
}

bool CBoxSignal::IsPriceWithinMA()
{
    return maCurrent[0] < priceData[highBarIndex] && maCurrent[0] > priceData[lowBarIndex];
}

ENUM_SIGNAL CBoxSignal::CalcSignal()
{
    if(rangePercentage <= maxRectangleSize && IsPriceWithinMA()) {
        
        if(!IsWithinTradeTime()) return SIGNAL_NEUTRAL;
        
        if (maCurrent[0] > maPrevious[0] && Ask > maCurrent[0]) {
            return SIGNAL_SELL;
        } 
        
        if (maCurrent[0] < maPrevious[0] && Bid < maCurrent[0]) {
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
        signalManager.RegisterSignal(new CBoxSignal(pSymbol));     
    }

    void RegisterSellSignals(CSignalManager *signalManager)
    {
        signalManager.RegisterSignal(new CBoxSignal(pSymbol));
    }

   void OnBuySignal()
    {
        double ask = SymbolInfoDouble(pSymbol, SYMBOL_ASK);
        if (_buyBasket.IsEmpty())
        {
            HandleTradeSignal(ask, ORDER_TYPE_BUY, _buyBasket, buyRecovery, "test buy");
        }
    }

    void OnSellSignal()
    {
        double bid = SymbolInfoDouble(pSymbol, SYMBOL_BID);
        if (_sellBasket.IsEmpty())
        {
            HandleTradeSignal(bid, ORDER_TYPE_SELL, _sellBasket, sellRecovery, "test sell");
        }
    }

    void HandleTradeSignal(double price, ENUM_ORDER_TYPE direction, Basket basket, Recovery recovery, string comment)
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