#include "SignalBase.mqh";
#include "..\Indicators\IndicatorZigZag.mqh";

class CZigZagSignal : public CSignalBase
{

private:
   CIndicatorZigZag *_indi;
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;
   bool _reverseSignal;

   ENUM_SIGNAL _prevSignal;

private:
   bool ValidateInputs();
   ENUM_SIGNAL CalcSignal();
   int GetPreviousZigZagBar(int bar, double zValue);

protected:
public:
   ENUM_SIGNAL GetSignal();

public:
   CZigZagSignal(string symbol, ENUM_TIMEFRAMES timeframe, int depth, int deviation, int backstep, bool reverseSignal = false);
   ~CZigZagSignal()
   {
      delete _indi;
   }
};

CZigZagSignal::CZigZagSignal(string symbol, ENUM_TIMEFRAMES timeframe, int depth, int deviation, int backstep, bool reverseSignal)
{
   _indi = new CIndicatorZigZag(symbol, timeframe, depth, deviation, backstep);
   _symbol = symbol;
   _timeframe = timeframe;
   _reverseSignal = reverseSignal;

   _prevSignal = SIGNAL_NUTURAL;
}

ENUM_SIGNAL CZigZagSignal::CalcSignal()
{
   int zCurrentBar = GetPreviousZigZagBar(1, 0);
   double zCurrentValue = _indi.GetValue(zCurrentBar);
   int z1Bar = GetPreviousZigZagBar(zCurrentBar, zCurrentValue);
   double z1Value = _indi.GetValue(z1Bar);
   int z2Bar = GetPreviousZigZagBar(z1Bar, z1Value);
   double z2Value = _indi.GetValue(z2Bar);

   ENUM_SIGNAL signal = SIGNAL_NUTURAL;

   if (z1Value < z2Value)
   {
      signal = _reverseSignal ? SIGNAL_SELL : SIGNAL_BUY;
   }
   else if (z1Value > z2Value)
   {
      signal = _reverseSignal ? SIGNAL_BUY : SIGNAL_SELL;
   }

   return signal;
}

int CZigZagSignal::GetPreviousZigZagBar(int bar, double zValue)
{
#ifdef __MQL4__
   for (int i = bar; i < Bars; i++)
   {
#endif
#ifdef __MQL5__
      for (int i = bar; i < Bars(_symbol, _timeframe); i++)
      {
#endif
         double prevZigZag = _indi.GetValue(i);
         if (prevZigZag != 0 && prevZigZag != zValue)
         {
            return i;
         }
      }

      return 0;
   }

   ENUM_SIGNAL CZigZagSignal::GetSignal(void)
   {
      ENUM_SIGNAL signal = CalcSignal();

      if (_prevSignal != signal)
      {
         _prevSignal = signal;
         return signal;
      }

      return SIGNAL_NUTURAL;
   }

   bool CZigZagSignal::ValidateInputs()
   {
      // You'll need to implement this method to validate the inputs based on your requirements
      return true;
   }
