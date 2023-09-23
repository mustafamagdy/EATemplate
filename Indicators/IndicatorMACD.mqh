#include "IndicatorBase.mqh";

class CIndicatorMACD : public CIndicatorBase
{
protected:
    int _fastEMA;   // Typically 12
    int _slowEMA;   // Typically 26
    int _signalSMA; // Typically 9
    ENUM_APPLIED_PRICE _appliedPrice;

public:
    CIndicatorMACD(string symbol, ENUM_TIMEFRAMES timeframe, int fastEMA = 12, int slowEMA = 26, int signalSMA = 9, ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE);
    ~CIndicatorMACD() {}

    // Overriding GetValue to cater for MACD's multiple buffers
#ifdef __MQL4__
    double GetValue(int bufferNumber, int index);
#endif
};

CIndicatorMACD::CIndicatorMACD(string symbol, ENUM_TIMEFRAMES timeframe, int fastEMA, int slowEMA, int signalSMA, ENUM_APPLIED_PRICE appliedPrice)
    : CIndicatorBase(symbol, timeframe),
      _fastEMA(fastEMA),
      _slowEMA(slowEMA),
      _signalSMA(signalSMA),
      _appliedPrice(appliedPrice)
{
#ifdef __MQL5__
    mHandle = iMACD(symbol, timeframe, fastEMA, slowEMA, signalSMA, _appliedPrice);
    HideIndicators();
#endif
}

#ifdef __MQL4__
double CIndicatorMACD::GetValue(int bufferNumber, int index)
{
    double result;

    switch (bufferNumber)
    {
    case 0: // MACD Line
        result = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, _appliedPrice, MODE_MAIN, index);
        break;
    case 1: // Signal Line
        result = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, _appliedPrice, MODE_SIGNAL, index);
        break;
    default: // MACD Histogram (difference between MACD and Signal)
        double macd = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, _appliedPrice, MODE_MAIN, index);
        double signal = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, _appliedPrice, MODE_SIGNAL, index);
        result = macd - signal;
        break;
    }

    return result;
}
#endif
