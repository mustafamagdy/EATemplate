#include "SignalBase.mqh";
#include "..\Indicators\IndicatorMA.mqh";

#ifdef __MQL4__
#define MAIN_LINE 0
#endif

class CEMASignal : public CSignalBase
{

private:
   CIndicatorMA *_indi;
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
   CEMASignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, int method, int priceType, double threshold);
   ~CEMASignal()
   {
      delete _indi;
   }
   virtual bool ValidateInputs()
   {
      // TODO
      return true;
   }
};

CEMASignal::CEMASignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, int method, int priceType, double threshold)
{
   _indi = new CIndicatorMA(symbol, timeframe, period, method, priceType, 0);
   _symbol = symbol;
   _timeframe = timeframe;
   _threshold = threshold;

   _prevSignal = SIGNAL_NEUTRAL;
}

ENUM_SIGNAL CEMASignal::CalcSignal()
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


ENUM_SIGNAL CEMASignal::GetSignal(void)
{
   ENUM_SIGNAL signal = CalcSignal();

   if (_prevSignal != signal)
   {
      _prevSignal = signal;
      return signal;
   }

   return SIGNAL_NEUTRAL;
}
