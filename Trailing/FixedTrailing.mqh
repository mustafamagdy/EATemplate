#property strict

#include <Trade\PositionInfo.mqh>
#include ".\TrailingBase.mqh"

class CFixedTrailing : public CTrailingBase
{
private:
    double _trailingStep;

public:
    CFixedTrailing(string symbol, double trailingStop, double trailingStep)
        : CTrailingBase(symbol, trailingStop)
    {
        _trailingStep = trailingStep;
    }
    ~CFixedTrailing() {}

public:
    bool CheckTrailing(CPositionInfo *position, double &slPrice, double &tpPrice);
    bool CheckTrailing(double originalSlPrice, double openPrice, ENUM_POSITION_TYPE positionType, double &slPrice, double &tpPrice);
};

bool CFixedTrailing::CheckTrailing(CPositionInfo *position, double &slPrice, double &tpPrice)
{
    if (position == NULL)
        return (false);

    return CheckTrailing(position.StopLoss(), position.PriceOpen(), position.PositionType(), slPrice, tpPrice);
}

bool CFixedTrailing::CheckTrailing(double originalSlPrice, double openPrice, ENUM_POSITION_TYPE positionType, double &slPrice, double &tpPrice)
{

    if (_trailingStop == 0)
        return (false);

    double delta;
    double base = (originalSlPrice == 0.0) ? openPrice : originalSlPrice;
    double price = positionType == POSITION_TYPE_SELL ? SymbolInfoDouble(_symbol, SYMBOL_BID) : SymbolInfoDouble(_symbol, SYMBOL_ASK);

    slPrice = EMPTY_VALUE;
    tpPrice = EMPTY_VALUE;
    delta = _trailingStop * _Point;
    if (price - base > delta)
    {
        slPrice = price - delta;
        if (_trailingStep != 0)
            tpPrice = price + _trailingStep * _Point;
    }

    return (slPrice != EMPTY_VALUE);
}
