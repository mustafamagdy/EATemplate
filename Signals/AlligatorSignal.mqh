#include "SignalBase.mqh";
#include "..\Indicators\IndicatorAlligator.mqh";

#ifdef __MQL4__
#define MAIN_LINE 0
#endif

class CAlligatorSignal : public CSignalBase
{

private:
   CIndicatorAlligator *_indi;
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;
   double _threshold; // Threshold for slope to consider trend
   ENUM_SIGNAL _prevSignal;

private:
   ENUM_SIGNAL CalcSignal();

protected:
public:
   ENUM_SIGNAL GetSignal();

public:
   CAlligatorSignal(string symbol, ENUM_TIMEFRAMES timeframe, int jawsPeriod, int jawsPeriodShift, int teethPeriod, int teethPeriodShift, 
                        int lipsPeriod, int lipsPeriodShift, int method, int priceType, double threshold);
   ~CAlligatorSignal()
   {
      delete _indi;
   }
   virtual bool ValidateInputs()
   {
      // TODO
      return true;
   }
};

CAlligatorSignal::CAlligatorSignal(string symbol, ENUM_TIMEFRAMES timeframe, int jawsPeriod, int jawsPeriodShift, int teethPeriod, int teethPeriodShift, 
                        int lipsPeriod, int lipsPeriodShift, int method, int priceType, double threshold)
{
   _indi = new CIndicatorAlligator(symbol, timeframe, jawsPeriod, jawsPeriodShift, teethPeriod, teethPeriodShift, lipsPeriod, lipsPeriodShift, 
                                   method, priceType);
   _symbol = symbol;
   _timeframe = timeframe;
   _threshold = threshold;

   _prevSignal = SIGNAL_NEUTRAL;
}

ENUM_SIGNAL CAlligatorSignal::CalcSignal()
{
    double currentSlope = _indi.GetValue(MAIN_LINE, 0) - _indi.GetValue(MAIN_LINE, 5);

    double emaBar1 = _indi.GetValue(MAIN_LINE, 1);
    double closeBar1 = iClose(_symbol, _timeframe, 1);
    double highBar1 = iHigh(_symbol, _timeframe, 1);
    double lowBar1 = iLow(_symbol, _timeframe, 1);

    double openBar2 = iOpen(_symbol, _timeframe, 0);
    double closeBar2 = iClose(_symbol, _timeframe, 0);

    double thresholdPips = 50 * _Point;  

    if (currentSlope < _threshold && 
        fabs(highBar1 - emaBar1) <= thresholdPips && 
        closeBar1 < emaBar1 && 
        closeBar2 < openBar2)
    {
        return SIGNAL_SELL;
    }
    else if (currentSlope > _threshold && 
             fabs(lowBar1 - emaBar1) <= thresholdPips && 
             closeBar1 > emaBar1 && 
             closeBar2 > openBar2)
    {
        return SIGNAL_BUY;
    }

    return SIGNAL_NEUTRAL; 
}


ENUM_SIGNAL CAlligatorSignal::GetSignal(void)
{
   ENUM_SIGNAL signal = CalcSignal();

   if (_prevSignal != signal)
   {
      _prevSignal = signal;
      return signal;
   }

   return SIGNAL_NEUTRAL;
}
