#property strict

#include "IndicatorBase.mqh";

#ifdef __MQL4__
#define _Indicator "Indicators\\ZigZag.ex4"
#endif
#ifdef __MQL5__
#define _Indicator "Indicators\\Examples\\ZigZag.ex5"
#endif
#resource "\\" + _Indicator

class CIndicatorZigZag : public CIndicatorBase
{

protected:
  int mDepth;
  int mDeviation;
  int mBackstep;

public:
  CIndicatorZigZag(string symbol, ENUM_TIMEFRAMES timeframe, int depth, int deviation, int backstep);
  ~CIndicatorZigZag() {}

#ifdef __MQL4__
  double GetValue(int bufferNumber, int index);
#endif
};

CIndicatorZigZag::CIndicatorZigZag(string symbol, ENUM_TIMEFRAMES timeframe, int depth, int deviation, int backstep)
    : CIndicatorBase(symbol, timeframe)
{
  mDepth = depth;
  mDeviation = deviation;
  mBackstep = backstep;

#ifdef __MQL5__
  mHandle = iCustom(mSymbol, (ENUM_TIMEFRAMES)mTimeframe, "::" + _Indicator, mDepth, mDeviation, mBackstep);

  HideIndicators();
#endif
}

#ifdef __MQL4__
double CIndicatorZigZag::GetValue(int bufferNumber, int index)
{
  double result = iCustom(mSymbol, mTimeframe, "::" + _Indicator, mDepth, mDeviation, mBackstep, bufferNumber, index);
  return result;
}
#endif
