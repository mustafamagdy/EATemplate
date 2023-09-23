#property strict

#include <Trade\PositionInfo.mqh>
#include ".\TrailingBase.mqh"
#include "..\Constants.mqh"

class CFixedTrailing : public CTrailingBase
{
private:
    double _trailingStep;
    CConstants *_constants;
    string pSymbol;

public:
    CFixedTrailing(string symbol, CConstants *constants, double trailingStop, double trailingStep)
        : CTrailingBase(symbol, trailingStop)
    {
        pSymbol = symbol;
        _trailingStep = trailingStep;
        _constants = constants;
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
    delta = _trailingStop * _constants.Point(pSymbol);
    if (price - base > delta)
    {
        slPrice = price - delta;
        if (_trailingStep != 0)
            tpPrice = price + _trailingStep * _constants.Point(pSymbol);
    }

    return (slPrice != EMPTY_VALUE);
}
