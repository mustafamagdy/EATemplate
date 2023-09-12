#include "IndicatorBase.mqh"

class CIndicatorZigZag : public CIndicatorBase {

private:
    int mDepth;
    int mDeviation;
    int mBackstep;

protected:

public:
    CIndicatorZigZag(string symbol, ENUM_TIMEFRAMES timeframe, int depth, int deviation, int backstep);
    ~CIndicatorZigZag() {}

    #ifdef __MQL4__
      double GetValue(int bufferNumber, int index);
    #endif
};

CIndicatorZigZag::CIndicatorZigZag(string symbol, ENUM_TIMEFRAMES timeframe, int depth, int deviation, int backstep)
        : CIndicatorBase() {
    mSymbol = symbol;
    mTimeframe = timeframe;
    mDepth = depth;
    mDeviation = deviation;
    mBackstep = backstep;
    
    #ifdef __MQL5__
        mHandle = iZigZag(mSymbol, mTimeframe, mDepth, mDeviation, mBackstep);
        
        HideIndicators();
    #endif
}


#ifdef __MQL4__  
    double CIndicatorZigZag::GetValue(int bufferNumber, int index) {
        double result = iCustom(mSymbol, mTimeframe, "ZigZag", mDepth, mDeviation, mBackstep, bufferNumber, index);
        return result;
    }
#endif
