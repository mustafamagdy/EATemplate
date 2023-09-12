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

protected:
public:
   ENUM_SIGNAL GetSignal();

public:
   CZigZagSignal(string symbol, ENUM_TIMEFRAMES timeframe, int depth, int deviation, int backstep, bool reverseSignal = false);
   ~CZigZagSignal() {
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
   double currentZigZag = _indi.GetValue(0);
   double previousZigZag = _indi.GetValue(1);

   if (currentZigZag > previousZigZag)
   {
      return _reverseSignal ? SIGNAL_SELL : SIGNAL_BUY;
   }
   else if (currentZigZag < previousZigZag)
   {
      return _reverseSignal ? SIGNAL_BUY : SIGNAL_SELL;
   }
   else
   {
      return SIGNAL_NUTURAL;
   }
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
