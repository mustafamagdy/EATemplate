#property strict

#include "FilterBase.mqh"
#include "..\Indicators\IndicatorATR.mqh"
#include "..\Constants.mqh"

class CATRFilter : public CFilterBase
{
private:
    CConstants *_constnats;
    string pSymbol;
    CIndicatorATR *_atr;
    double _minValue;
    double _maxValue;

public:
    CATRFilter(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift, double minValue, double maxValue, CConstants *constants)
    {
        pSymbol = symbol;
        _atr = new CIndicatorATR(symbol, timeframe, period, shift);
        _constnats = constants;
        _minValue = minValue;
        _maxValue = maxValue;
    }
    ~CATRFilter()
    {
        delete _atr;
    }

    virtual bool ValidateInputs()
    {
        // TODO
        return true;
    }

    virtual bool GetValue()
    {
        double atrValue = _atr.GetValue(0) / _constnats.Point(pSymbol);
        return (_minValue == 0 || atrValue >= _minValue) && (_maxValue == 0 || atrValue <= _maxValue);
    }
};