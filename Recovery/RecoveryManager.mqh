#include <Object.mqh>
#include "..\Trade\TradingBasket.mqh"
#include "..\Trade\TradingManager.mqh"
#include "..\Enums.mqh"
#include "..\Constants.mqh"
#include "..\RiskManagement\NormalLotSizeCalculator.mqh";
#include "RecoveryLotSizeCalculator.mqh";
#include "GridGapCalculator.mqh";

class CRecoveryManager : public CTradingManager
{

private:
    CNormalLotSizeCalculator *_normalLotCalc;
    CRecoveryLotSizeCalculator *_recoveryLotCalc;
    CGridGapCalculator *_gridGapCalc;
    ENUM_RECOVERY_MODE _recoveryMode;
    double _recoveryTpPoints;
    double _recoveryAvgTPrice;
    int _maxGridOrderCount;

public:
    CRecoveryManager::CRecoveryManager(CTradingBasket *basket, CNormalLotSizeCalculator *normalLotCalc, CRecoveryLotSizeCalculator *recoveryLotCalc,
                                       int maxGridOrderCount, ENUM_RECOVERY_MODE recoveryMode, double recoveryTpPoints,
                                       ENUM_GRID_SIZE_MODE gridSizeMode, int gridFixedSize, ENUM_GRID_FIXED_CUSTOM_MODE gridCustomSizeMode,
                                       string gridCustomSeries, int gridATRPeriod, ENUM_VALUE_ACTION gridATRValueAction, double gridATRValue,
                                       int gridATRMin, int _gridATRMax) : CTradingManager(basket)
    {
        _basket = basket;
        _normalLotCalc = normalLotCalc;
        _recoveryLotCalc = recoveryLotCalc;
        _maxGridOrderCount = maxGridOrderCount;
        _recoveryMode = recoveryMode;
        _recoveryTpPoints = recoveryTpPoints;

        _gridGapCalc = new CGridGapCalculator(gridSizeMode, gridFixedSize, gridCustomSizeMode, gridCustomSeries,
                                              gridATRPeriod, gridATRValueAction, gridATRValue, gridATRMin, _gridATRMax);
    }

public:
    void OnTick();
    virtual bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message, Trade &newTrade)
    {
        double slPrice = 0, tpPrice = 0;
        double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        double spread = ask - bid;
        int spread_points = (int)MathRound(spread / SymbolInfoDouble(Symbol(), SYMBOL_POINT));
        if (slPoints <= spread_points)
        {
            message = "SL points is less than the spread points";
            return (false);
        }

        if (orderType == ORDER_TYPE_BUY)
        {
            slPrice = slPoints > 0 ? price - (slPoints * _Point) : 0;
            tpPrice = tpPoints > 0 ? price + (tpPoints * _Point) : 0;
        }
        else
        {
            slPrice = slPoints > 0 ? price + (slPoints * _Point) : 0;
            tpPrice = tpPoints > 0 ? price - (tpPoints * _Point) : 0;
        }
        return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, comment, message, newTrade);
    }

    virtual bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string comment, string &message, Trade &newTrade)
    {
        bool result = CTradingManager::OpenTradeWithPrice(volume, price, orderType, 0, 0, comment, message, newTrade);
        if (result)
        {
            _recoveryAvgTPrice = _CalculateAvgTPPriceForMartingale(orderType);
            _basket.SetTradeToVirtualSLTP(newTrade.Ticket(), slPrice, _recoveryAvgTPrice);
        }
        return result;
    }

private:
    double _NextLotSize(string symbol, int slPoints, double lastLot, ENUM_ORDER_TYPE direction);
    double _CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction);
};

void CRecoveryManager::OnTick()
{
    if (_basket.Status() != BASKET_OPEN || _basket.IsEmpty())
    {
        // Do nothing, basket is empty or closed
    }
    else
    {
        Trade firstTrade;
        _basket.FirstTrade(firstTrade);
        Trade lastTrade;
        _basket.LastTrade(lastTrade);

        if (_basket.Count() == 1)
        {
            _recoveryAvgTPrice = firstTrade.VirtualTakeProfit();
        }

        double lastLot = lastTrade.Volume();
        double lastOpenPrice = lastTrade.OpenPrice();
        double firstOpenPrice = firstTrade.OpenPrice();
        double firstTradeTp = firstTrade.TakeProfit();
        double lastTradeSL = lastTrade.VirtualStopLoss();

        string symbol = _basket.Symbol();
        double price = constants.Ask(symbol);

        if (price > _recoveryAvgTPrice)
        {
            _basket.CloseBasketOrders();
        }
        else if (price <= lastTradeSL)
        {
            if (_maxGridOrderCount != 0 && _basket.Count() >= _maxGridOrderCount)
            {
                // Do nothing as we reached the max grid order count
            }
            else
            {
                ENUM_ORDER_TYPE orderType = lastTrade.OrderType();
                int nextGridGap = _gridGapCalc.CalculateNextOrderDistance(_basket.Count(), lastOpenPrice, firstTradeTp);
                string message;
                Trade trade;

                // Check the recovery type here to know the next direction
                if (_recoveryMode == RECOVERY_MARTINGALE)
                {
                    double nextSLPrice = price - NormalizeDouble(nextGridGap * _Point, _Digits);
                    double nextLot = _NextLotSize(symbol, nextGridGap, lastLot, orderType);                   
                    if (OpenTradeWithPrice(nextLot, price, orderType, nextSLPrice, 0, StringFormat("RM: Order %d", _basket.Count() + 1), message, trade))
                    {
                        // Done
                    }
                    else
                    {
                        // Failed to open a recovery trade
                    }
                }
                else if (_recoveryMode == RECOVERY_HEDGING)
                {
                    double nextSLPrice = price + NormalizeDouble(nextGridGap * _Point, _Digits);
                    double nextLot = _NextLotSize(symbol, nextGridGap, lastLot, orderType);
                    if (OpenTradeWithPrice(nextLot, price, orderType, nextSLPrice, _recoveryAvgTPrice, StringFormat("RM: Order %d", _basket.Count() + 1), message, trade))
                    {
                        // Done
                    }
                    else
                    {
                        // Failed to open a recovery trade
                    }
                }
            }
        }
        else
        {
            // TODO
        }
    }
    CTradingManager::OnTick();
}

////////////////////////////////////////////////////
double CRecoveryManager::_CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction)
{
    double avgOpenPrice = _basket.AverageOpenPrice();
    return NormalizeDouble(avgOpenPrice + (((direction == ORDER_TYPE_BUY) ? 1 : -1) * _recoveryTpPoints * _Point), _Digits);
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
