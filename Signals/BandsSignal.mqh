#include "SignalBase.mqh";
#include "..\Indicators\IndicatorIBands.mqh";

class CBandsSignal : public CSignalBase
{

private:
   CIndicatorIBands *_indi;
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;

private:
   bool ValidateInputs();
   ENUM_SIGNAL CalcSignal();

protected:
public:
   ENUM_SIGNAL GetSignal();

public:
   CBandsSignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation, ENUM_APPLIED_PRICE appliedPrice);
   ~CBandsSignal() {}
};

CBandsSignal::CBandsSignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation, ENUM_APPLIED_PRICE appliedPrice)
{
   _indi = new CIndicatorIBands(symbol, timeframe, period, deviation, appliedPrice);
   _symbol = symbol;
   _timeframe = timeframe;
}

ENUM_SIGNAL CBandsSignal::CalcSignal(void)
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
      return SIGNAL_SELL;
   }
   else if (low <= lowerBand)
   {
      return SIGNAL_BUY;
   }
   else
   {
      return SIGNAL_NUTURAL;
   }
}

ENUM_SIGNAL CBandsSignal::GetSignal(void)
{

   static ENUM_SIGNAL prevSignal = CalcSignal();
   ENUM_SIGNAL signal = CalcSignal();

   if (prevSignal != signal)
   {
      prevSignal = signal;
      return signal;
   }

   return SIGNAL_NUTURAL;
}