#property strict
#include "IndicatorBase.mqh";

class CIndicatorATR : public CIndicatorBase
{

protected:
  int mPeriod;
  int mShift;

public:
  CIndicatorATR(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift);
  ~CIndicatorATR() {}

#ifdef __MQL4__
  double GetValue(int bufferNumber, int index);
#endif
};

CIndicatorATR::CIndicatorATR(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift)
    : CIndicatorBase()
{
  mSymbol = symbol;
  mTimeframe = timeframe;
  mPeriod = period;
  mShift = shift;

#ifdef __MQL5__
  mHandle = iATR(symbol, timeframe, period);
  CIndicatorATR::HideIndicators();
#endif
}

#ifdef __MQL4__
double CIndicatorATR::GetValue(int bufferNumber, int index)
{
  double result = iATR(mSymbol, mTimeframe, mPeriod, index);
  return result;
}
#endif
