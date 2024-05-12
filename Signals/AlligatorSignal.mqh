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
   ENUM_SIGNAL _prevSignal;

private:
   ENUM_SIGNAL CalcSignal();

protected:
public:
   ENUM_SIGNAL GetSignal();

public:
   CAlligatorSignal(string symbol, ENUM_TIMEFRAMES timeframe, int jawsPeriod, int jawsPeriodShift, int teethPeriod, int teethPeriodShift, 
                        int lipsPeriod, int lipsPeriodShift, int method, int priceType);
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
                        int lipsPeriod, int lipsPeriodShift, int method, int priceType)
{
   _indi = new CIndicatorAlligator(symbol, timeframe, jawsPeriod, jawsPeriodShift, teethPeriod, teethPeriodShift, lipsPeriod, lipsPeriodShift, 
                                   method, priceType);
   _symbol = symbol;
   _timeframe = timeframe;
   
   _prevSignal = SIGNAL_NEUTRAL;
}

ENUM_SIGNAL CAlligatorSignal::CalcSignal()
{
   int bar = 1;
   double jaw = _indi.GetValue(0, bar);
   double teeth = _indi.GetValue(1, bar);
   double lip = _indi.GetValue(2, bar);
   double close1 = iClose(_symbol, _timeframe, bar);
   double close2 = iClose(_symbol, _timeframe, bar+1);
   double close3 = iClose(_symbol, _timeframe, bar+2);
   
   static string last_premise = "";
   if(lip > teeth && teeth > jaw) {
      last_premise = "buy";
   } else if(lip < teeth && teeth < jaw) {
      last_premise = "sell";
   }
   
   Comment(StringFormat("Signal is %s", last_premise));
   
   
   if(last_premise == "buy") {
      if(close2 < lip && close1 > lip) {
         return SIGNAL_BUY;
      }
   } else if(last_premise == "sell") {
      if(close2 > lip && close1 < lip) {
         return SIGNAL_SELL;
      }
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
