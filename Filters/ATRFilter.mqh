#property strict

#include "FilterBase.mqh"
#include "..\Indicators\IndicatorATR.mqh"

class CATRFilter : public CFilterBase
{
private:
    CIndicatorATR *_atr;
    double _minValue;
    double _maxValue;

public:
    CATRFilter(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift, double minValue, double maxValue)
    {
        _atr = new CIndicatorATR(symbol, timeframe, period, shift);
        _minValue = minValue;
        _maxValue = maxValue;
    }
    ~CATRFilter()
    {
        delete _atr;
    }

    virtual bool ValidateInputs() { return true; }
    virtual bool CanTrade()
    {
        double atrValue = _atr.GetValue(0) / _Point;
        return (_minValue == 0 || atrValue >= _minValue) && (_maxValue == 0 || atrValue <= _maxValue);
    }
};