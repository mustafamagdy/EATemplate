#property strict
#include "IndicatorBase.mqh";

class CIndicatorMA : public CIndicatorBase
{

protected:
  int mPeriod;
  int mShift;
  int mMethod;             
  int mPriceType;          

public:
  CIndicatorMA(string symbol, ENUM_TIMEFRAMES timeframe, int period, int method, int priceType, int shift);
  ~CIndicatorMA() {}

#ifdef __MQL4__
  double GetValue(int bufferNumber, int index);
#endif
};

CIndicatorMA::CIndicatorMA(string symbol, ENUM_TIMEFRAMES timeframe, int period, int method, int priceType, int shift)
    : CIndicatorBase(symbol, timeframe)
{
  mPeriod = period;
  mShift = shift;
  mMethod = method;
  mPriceType = priceType;

#ifdef __MQL5__
  mHandle = iMA(symbol, timeframe, period, shift, (ENUM_MA_METHOD)method, priceType);
  CIndicatorMA::HideIndicators();
#endif
}

#ifdef __MQL4__
double CIndicatorMA::GetValue(int bufferNumber, int index)
{
  double result = iMA(mSymbol, mTimeframe, mPeriod, mShift, mMethod, mPriceType, index);
  return result;
}
#endif
