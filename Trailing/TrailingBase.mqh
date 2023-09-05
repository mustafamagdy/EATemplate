#property strict

#include <Object.mqh>
#include <Trade\PositionInfo.mqh>

class CTrailingBase : public CObject
{
protected:
    string _symbol;
    double _trailingStop;

public:
    CTrailingBase(string symbol, double trailingStop)
    {
        _symbol = symbol;
        _trailingStop = trailingStop;
    }
    ~CTrailingBase() {}

public:
    bool virtual CheckTrailing(CPositionInfo *position, double &slPrice, double &tpPrice) = NULL;
};