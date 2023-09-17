#property strict

#include "FilterBase.mqh"

class CSpreadFilter : public CFilterBase
{
private:
    int _maxValue;
    string _symbol;

public:
    CSpreadFilter(string symbol, int maxValue)
    {
        _maxValue = maxValue;
        _symbol = symbol;
    }
    ~CSpreadFilter()
    {
    }

    virtual bool ValidateInputs()
    {
        // TODO
        return true;
    }

    virtual bool GetValue()
    {
        double ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
        double spread = ask - bid;
        int spread_points = (int)MathRound(spread / SymbolInfoDouble(_symbol, SYMBOL_POINT));
        return (_maxValue == 0 || spread_points <= _maxValue);
    }
};