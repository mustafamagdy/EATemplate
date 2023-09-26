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

   _prevSignal = SIGNAL_NUTURAL;
}

ENUM_SIGNAL CEMASignal::CalcSignal()
{
   double currentSlope = _indi.GetValue(MAIN_LINE, 0) - _indi.GetValue(MAIN_LINE, 5);

   if (currentSlope > _threshold)
   {
      return SIGNAL_BUY;
   }
   else if (currentSlope < -_threshold)
   {
      return SIGNAL_SELL;
   }
   else
   {
      return SIGNAL_NUTURAL;
   }
}

ENUM_SIGNAL CEMASignal::GetSignal(void)
{
   ENUM_SIGNAL signal = CalcSignal();

   if (_prevSignal != signal)
   {
      _prevSignal = signal;
      return signal;
   }

   return SIGNAL_NUTURAL;
}
