#include <Object.mqh>
#include "..\Trade\TradingBasket.mqh"
#include "..\Enums.mqh"
#include "..\Constants.mqh"
#include "..\RiskManagement\NormalLotSizeCalculator.mqh";
#include "RecoveryLotSizeCalculator.mqh";
#include "GridGapCalculator.mqh";

class CRecoveryManager : CObject
{

private:
    CConstants *constants;
    CTradingBasket *_basket;
    CNormalLotSizeCalculator *_normalLotCalc;
    CGridGapCalculator *_gridGapCalc;
    CRecoveryLotSizeCalculator *_recoveryLotCalc;
    ENUM_RECOVERY_MODE _recoveryMode;
    double _recoveryTpPoints;
    double _recoveryAvgTPrice;
    int _maxGridOrderCount;

public:
    CRecoveryManager::CRecoveryManager(CTradingBasket *basket, CNormalLotSizeCalculator *normalLotCalc, int maxGridOrderCount, ENUM_RECOVERY_MODE recoveryMode,
                                       double recoveryTpPoints, ENUM_GRID_SIZE_MODE gridSizeMode, int gridFixedSize,
                                       ENUM_GRID_FIXED_CUSTOM_MODE gridCustomSizeMode, string gridCustomSeries,
                                       int gridATRPeriod, ENUM_VALUE_ACTION gridATRValueAction, double gridATRValue,
                                       int gridATRMin, int _gridATRMax)
    {
        _basket = basket;
        _maxGridOrderCount = maxGridOrderCount;
        _normalLotCalc = normalLotCalc;
        _recoveryMode = recoveryMode;
        _recoveryTpPoints = recoveryTpPoints;
        _recoveryLotCalc = new CRecoveryLotSizeCalculator(normalLotCalc);
        _gridGapCalc = new CGridGapCalculator(gridSizeMode, gridFixedSize, gridCustomSizeMode, gridCustomSeries,
                                              gridATRPeriod, gridATRValueAction, gridATRValue, gridATRMin, _gridATRMax);
    }

public:
    void OnTick();

private:
    double _NextLotSize(string symbol, int slPoints, double lastLot, ENUM_ORDER_TYPE direction);
};

void CRecoveryManager::OnTick()
{
    if (_basket.Status() != BASKET_OPEN || _basket.IsEmpty())
    {
        return;
    }

    Trade firstTrade;
    _basket.FirstTrade(firstTrade);
    Trade lastTrade;
    _basket.LastTrade(lastTrade);

    if (_basket.Count() == 1)
    {
        _recoveryAvgTPrice = firstTrade.TakeProfit();
    }

    double lastLot = lastTrade.Volume();
    double lastOpenPrice = lastTrade.OpenPrice();
    double firstOpenPrice = firstTrade.OpenPrice();
    double firstTradeTp = firstTrade.TakeProfit();
    double lastTradeSL = firstTrade.StopLoss();

    string symbol = _basket.Symbol();
    double price = constants.Ask(symbol);

    if (price > _recoveryAvgTPrice)
    {
        _basket.CloseBasketOrders();
        return;
    }
    else if (price < lastTradeSL)
    {
        if (_maxGridOrderCount != 0 && _basket.Count() >= _maxGridOrderCount)
        {
            // Attempt to close all trades as reaching out max orders
            _basket.CloseBasketOrders();
            return;
        }

        ENUM_ORDER_TYPE orderType = lastTrade.OrderType();
        int nextGridGap = _gridGapCalc.CalculateNextOrderDistance(_basket.Count(), lastOpenPrice, firstTradeTp);
        string message;

        // Check the recovery type here to know the next direction
        if (_recoveryMode == RECOVERY_MARTINGALE)
        {
            double nextSLPrice = firstTradeTp - NormalizeDouble(nextGridGap * _Point, _Digits);
            double nextLot = _NextLotSize(symbol, nextGridGap, lastLot, orderType);
            if (!_basket.AddTradeWithPrice(nextLot, price, orderType, nextSLPrice, 0, StringFormat("RM: Order %d", _basket.Count() + 1), message))
            {
                // Failed to open a recovery trade
            }
        }
        else if (_recoveryMode == RECOVERY_HEDGING)
        {
            double nextSLPrice = price + NormalizeDouble(nextGridGap * _Point, _Digits);
            double nextLot = _NextLotSize(symbol, nextGridGap, lastLot, orderType);
            if (!_basket.AddTradeWithPrice(nextLot, price, orderType, nextSLPrice, 0, StringFormat("RM: Order %d", _basket.Count() + 1), message))
            {
                // Failed to open a recovery trade
            }
        }
    }
}

double CRecoveryManager::_NextLotSize(string symbol, int slPoints, double lastLot, ENUM_ORDER_TYPE direction)
{
    int basketCount = _basket.Count();
    if (_recoveryMode == RECOVERY_MARTINGALE)
    {
        return _basket.IsEmpty()
                   ? _normalLotCalc.CalculateLotSize(symbol, slPoints, lastLot, basketCount, direction)
                   : _recoveryLotCalc.CalculateLotSize(symbol, slPoints, lastLot, basketCount, direction);
    }
    else if (_recoveryMode == RECOVERY_HEDGING)
    {
        double lotSize = 0;
        double sellLots = _basket.Volume(ORDER_TYPE_SELL);
        double buyLots = _basket.Volume(ORDER_TYPE_BUY);
        if (direction == ORDER_TYPE_BUY)
        {
            lotSize = MathAbs((sellLots * ((_recoveryTpPoints + slPoints) / (double)_recoveryTpPoints)) - buyLots);
        }
        else
        {
            lotSize = MathAbs((buyLots * ((_recoveryTpPoints + slPoints) / (double)_recoveryTpPoints)) - sellLots);
        }

        lotSize = MathCeil(lotSize / constants.LotStep(symbol)) * constants.LotStep(symbol);
        return _normalLotCalc.NormalizeLot(symbol, lotSize);
    }
    else
    {
        return constants.MinLot(symbol);
    }
}
