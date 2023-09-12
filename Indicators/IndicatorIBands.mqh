#property strict

#include "IndicatorBase.mqh";

class CIndicatorIBands : public CIndicatorBase {

private:
   int                  mPeriod;
   double               mDeviation;
   ENUM_APPLIED_PRICE   mAppliedPrice;

protected:

public:
  CIndicatorIBands(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation, ENUM_APPLIED_PRICE appliedPrice);
  ~CIndicatorIBands() {}

  #ifdef __MQL4__
    double GetValue(int bufferNumber, int index);
  #endif
};

CIndicatorIBands::CIndicatorIBands(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation, ENUM_APPLIED_PRICE appliedPrice)
      : CIndicatorBase(symbol, timeframe) {
  mPeriod = period;
  mDeviation = deviation;
  mAppliedPrice = appliedPrice;
   
  #ifdef __MQL5__
    mHandle = iBands( mSymbol, (ENUM_TIMEFRAMES)mTimeframe, period,0, deviation, appliedPrice );
    
    HideIndicators();
  #endif
}


#ifdef __MQL4__  
  double CIndicatorIBands::GetValue(int bufferNumber, int index) {
    double result = iBands(mSymbol, mTimeframe, mPeriod, mDeviation, 0, mAppliedPrice, bufferNumber, index);
    return result;
  }
#endif
