#property strict

#include "FilterBase.mqh"
#include "..\Indicators\IndicatorATR.mqh"

class CSpreadFilter : public CFilterBase
{
private:
    int _maxValue;
string _symbol;
public:
    CSpreadFilter(string symbol, int maxValue)
    {
        _maxValue = maxValue;
        _symbol=  symbol;
    }
    ~CSpreadFilter()
    {
    }

    virtual bool ValidateInputs() { return true; }
    virtual bool CanTrade()
    {
        double ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
        double spread = ask - bid;
        return (_maxValue == 0 || spread <= _maxValue);
    }
};