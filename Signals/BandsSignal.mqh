#include "SignalBase.mqh";
#include "..\Indicators\IndicatorIBands.mqh";

#ifdef __MQL4__
#define UPPER_BAND MODE_UPPER
#define LOWER_BAND MODE_LOWER
#endif

class CBandsSignal : public CSignalBase
{

private:
   CIndicatorIBands *_indi;
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;
   bool _reverseSignal;

   ENUM_SIGNAL _prevSignal;

private:
   ENUM_SIGNAL CalcSignal();

protected:
public:
   ENUM_SIGNAL GetSignal();

public:
   CBandsSignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation, ENUM_APPLIED_PRICE appliedPrice, bool reverseSignal = false);
   ~CBandsSignal()
   {
      delete _indi;
   }
   virtual bool ValidateInputs()
   {
      // TODO
      return true;
   }
};

CBandsSignal::CBandsSignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation, ENUM_APPLIED_PRICE appliedPrice, bool reverseSignal)
{
   _indi = new CIndicatorIBands(symbol, timeframe, period, deviation, appliedPrice);
   _symbol = symbol;
   _timeframe = timeframe;
   _reverseSignal = reverseSignal;

   _prevSignal = SIGNAL_NUTURAL;
}

ENUM_SIGNAL CBandsSignal::CalcSignal()
{
#ifdef __MQL4__
   double upperBand = _indi.GetValue(UPPER_BAND, 0);
   double lowerBand = _indi.GetValue(LOWER_BAND, 0);
#endif
#ifdef __MQL5__
   double upperBand = _indi.GetValue(UPPER_BAND, 0);
   double lowerBand = _indi.GetValue(LOWER_BAND, 0);
#endif

   double high = iHigh(_symbol, _timeframe, 0);
   double low = iLow(_symbol, _timeframe, 0);

   if (high >= upperBand)
   {
      return _reverseSignal ? SIGNAL_BUY : SIGNAL_SELL;
   }
   else if (low <= lowerBand)
   {
      return _reverseSignal ? SIGNAL_SELL : SIGNAL_BUY;
   }
   else
   {
      return SIGNAL_NUTURAL;
   }
}

ENUM_SIGNAL CBandsSignal::GetSignal(void)
{

   ENUM_SIGNAL signal = CalcSignal();

   if (_prevSignal != signal)
   {
      _prevSignal = signal;
      return signal;
   }

   return SIGNAL_NUTURAL;
}