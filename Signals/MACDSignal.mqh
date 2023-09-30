#include "..\Indicators\IndicatorMACD.mqh"
#include "SignalBase.mqh"

enum ENUM_MACD_SIGNAL_TYPE
{
    MACD_SIGNAL_LINE, // Based on MACD line and Signal line
    MACD_HISTOGRAM    // Based on MACD Histogram
};

class CMACDSignal : public CSignalBase
{
private:
    CIndicatorMACD *_indi;
    string _symbol;
    ENUM_TIMEFRAMES _timeframe;
    bool _reverseSignal;
    ENUM_MACD_SIGNAL_TYPE _signalType;

    ENUM_SIGNAL _prevSignal;

private:
    ENUM_SIGNAL CalcSignal();

public:
    ENUM_SIGNAL GetSignal();

public:
    CMACDSignal(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_MACD_SIGNAL_TYPE signalType, int fastEMA = 12, int slowEMA = 26, int signalSMA = 9, bool reverseSignal = false);
    ~CMACDSignal()
    {
        delete _indi;
    }
    virtual bool ValidateInputs()
    {
        // TODO
        return true;
    }
};

CMACDSignal::CMACDSignal(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_MACD_SIGNAL_TYPE signalType, int fastEMA, int slowEMA, int signalSMA, bool reverseSignal)
{
    _indi = new CIndicatorMACD(symbol, timeframe, fastEMA, slowEMA, signalSMA);
    _symbol = symbol;
    _timeframe = timeframe;
    _signalType = signalType;
    _reverseSignal = reverseSignal;
    _prevSignal = SIGNAL_NEUTRAL;
}

ENUM_SIGNAL CMACDSignal::CalcSignal()
{
    double macd = _indi.GetValue(0, 0);
    double signal = _indi.GetValue(1, 0);

    switch (_signalType)
    {
    case MACD_SIGNAL_LINE:
    {
        if (macd > signal)
        {
            return _reverseSignal ? SIGNAL_SELL : SIGNAL_BUY;
        }
        else if (macd < signal)
        {
            return _reverseSignal ? SIGNAL_BUY : SIGNAL_SELL;
        }
        break;
    }

    case MACD_HISTOGRAM:
    {
        double histogram = macd - signal;
        if (histogram > 0)
        {
            return _reverseSignal ? SIGNAL_SELL : SIGNAL_BUY;
        }
        else if (histogram < 0)
        {
            return _reverseSignal ? SIGNAL_BUY : SIGNAL_SELL;
        }
        break;
    }
    }

    return SIGNAL_NEUTRAL;
}

ENUM_SIGNAL CMACDSignal::GetSignal(void)
{
    ENUM_SIGNAL signal = CalcSignal();

    if (_prevSignal != signal)
    {
        _prevSignal = signal;
        return signal;
    }

    return SIGNAL_NEUTRAL;
}
