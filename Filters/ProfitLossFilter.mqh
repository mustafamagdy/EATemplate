#property strict

#include "FilterBase.mqh"

class CProfitLossFilter : public CFilterBase
{
private:
    double _maxLoss;
    double _maxProfit;
    string _symbol;

public:
    CProfitLossFilter(string symbol)
    {
        _symbol = symbol;
    }
    ~CProfitLossFilter()
    {
    }

    virtual bool ValidateInputs() { return true; }
    virtual bool CanTrade()
    {
        double ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
        double spread = ask - bid;
        int spread_points = (int)MathRound(spread / SymbolInfoDouble(_symbol, SYMBOL_POINT));
        // return (_maxValue == 0 || spread_points <= _maxValue);
        return (false);
    }
};