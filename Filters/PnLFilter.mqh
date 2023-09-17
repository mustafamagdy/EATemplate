#property strict
#include "..\Enums.mqh"
#include "FilterBase.mqh"
#include "..\Trade\TradingBasket.mqh"
#include "..\Constants.mqh"

class CPnLFilter : public CFilterBase
{
private:
    ENUM_BASKET_PNL_TYPE _maxLossType;
    ENUM_BASKET_PNL_TYPE _maxProfitType;
    double _maxLoss;
    double _maxProfit;
    string _symbol;
    CTradingBasket *_basket;
    CConstants *_constants;

public:
    CPnLFilter(string symbol, CConstants *constants, CTradingBasket *basket, ENUM_BASKET_PNL_TYPE maxLossType, double maxLoss,
               ENUM_BASKET_PNL_TYPE maxProfitType, double maxProfit)
    {
        _symbol = symbol;
        _basket = basket;
        _maxLoss = maxLoss;
        _maxLossType = maxLossType;
        _maxProfit = maxProfit;
        _maxProfitType = maxProfitType;
        _constants = constants;
    }
    ~CPnLFilter()
    {
    }

    virtual bool ValidateInputs() { return true; }
    virtual bool GetValue()
    {
        double profit = _basket.Profit();
        double equity = _constants.AccountEquity();

        if (_maxLoss > 0 && profit < 0)
        {
            double maxLoss = (_maxLossType == MAX_PNL_CURRENCY_PER_PAIR) ? _maxLoss : (_maxLoss * equity / 100.0);
            if (MathAbs(profit) > maxLoss)
            {
                return false;
            }
        }

        if (_maxProfit > 0 && profit > 0)
        {
            double maxProfit = (_maxProfitType == MAX_PNL_CURRENCY_PER_PAIR) ? _maxProfit : (_maxProfit * equity / 100.0);
            if (profit > maxProfit)
            {
                return false;
            }
        }

        return true;
    }
};