#include "IndicatorBase.mqh"

class CIndicatorAlligator : public CIndicatorBase
{
protected:
    int mJawsPeriod;
    int mJawsPeriodShift;
    int mTeethPeriod;
    int mTeethPeriodShift;
    int mLipsPeriod;
    int mLipsPeriodShift;
    int mMethod;
    int mPriceType;

public:
    CIndicatorAlligator(string symbol, ENUM_TIMEFRAMES timeframe, int jawsPeriod, int jawsPeriodShift, int teethPeriod, int teethPeriodShift, 
                        int lipsPeriod, int lipsPeriodShift, int method, int priceType);
    ~CIndicatorAlligator() {}

#ifdef __MQL4__
    double GetValue(int bufferNumber, int index);
#endif
};

CIndicatorAlligator::CIndicatorAlligator(string symbol, ENUM_TIMEFRAMES timeframe, int jawsPeriod, int jawsPeriodShift, int teethPeriod, int teethPeriodShift, 
                        int lipsPeriod, int lipsPeriodShift, int method, int priceType)
    : CIndicatorBase(symbol, timeframe)
{
    mJawsPeriod = jawsPeriod;
    mJawsPeriodShift = jawsPeriodShift;
    mTeethPeriod = teethPeriod;
    mTeethPeriodShift = teethPeriodShift;
    mLipsPeriod = lipsPeriod;
    mLipsPeriodShift = lipsPeriodShift;
    mMethod = method;
    mPriceType = priceType;

#ifdef __MQL5__
    mHandle = iAlligator(symbol, timeframe, jawsPeriod, jawsPeriodShift, teethPeriod, teethPeriodShift, lipsPeriod, lipsPeriodShift, (ENUM_MA_METHOD)method, priceType);
    CIndicatorAlligator::HideIndicators();
#endif
}

#ifdef __MQL4__
double CIndicatorAlligator::GetValue(int bufferNumber, int index)
{
    double result = iAlligator(mSymbol, mTimeframe, mJawsPeriod, mJawsPeriodShift, mTeethPeriod, mTeethPeriodShift, mLipsPeriod, mLipsPeriodShift, mMethod, mPriceType, index);
    return result;
}
#endif
