#include "IndicatorBase.mqh";

class CIndicatorMACD : public CIndicatorBase
{
protected:
    int mFastEMA;   // Typically 12
    int mSlowEMA;   // Typically 26
    int mSignalSMA; // Typically 9

public:
    CIndicatorMACD(string symbol, ENUM_TIMEFRAMES timeframe, int fastEMA = 12, int slowEMA = 26, int signalSMA = 9);
    ~CIndicatorMACD() {}

    // Overriding GetValue to cater for MACD's multiple buffers
#ifdef __MQL4__
    double GetValue(int bufferNumber, int index);
#endif
};

CIndicatorMACD::CIndicatorMACD(string symbol, ENUM_TIMEFRAMES timeframe, int fastEMA, int slowEMA, int signalSMA)
    : CIndicatorBase(symbol, timeframe),
      mFastEMA(fastEMA),
      mSlowEMA(slowEMA),
      mSignalSMA(signalSMA)
{
#ifdef __MQL5__
    mHandle = iMACD(symbol, timeframe, fastEMA, slowEMA, signalSMA, PRICE_CLOSE);
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
        result = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, PRICE_CLOSE, MODE_MAIN, index);
        break;
    case 1: // Signal Line
        result = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, PRICE_CLOSE, MODE_SIGNAL, index);
        break;
    default: // MACD Histogram (difference between MACD and Signal)
        double macd = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, PRICE_CLOSE, MODE_MAIN, index);
        double signal = iMACD(mSymbol, mTimeframe, mFastEMA, mSlowEMA, mSignalSMA, PRICE_CLOSE, MODE_SIGNAL, index);
        result = macd - signal;
        break;
    }

    return result;
}
#endif
