#include <Object.mqh>
#include ".\TradingBasket.mqh";
#include ".\TradingManager.mqh";
#include "..\Enums.mqh";
#include "..\Constants.mqh";
#include "..\Options.mqh";
#include "..\Recovery\GridGapCalculator.mqh";
#include "..\Recovery\RecoveryLotSizeCalculator.mqh";
#include "..\Signals\SignalManager.mqh";
#include "..\RiskManagement\NormalLotSizeCalculator.mqh";
#include "..\UI\Reporter.mqh";

class CRecoveryManager : public CTradingManager
{

private:
    CNormalLotSizeCalculator *_normalLotCalc;
    CRecoveryLotSizeCalculator *_recoveryLotCalc;
    CGridGapCalculator *_gridGapCalc;
    CSignalManager *_signalManager;
    RecoveryOptions _options;
    double _recoveryAvgTPrice;

public:
    CRecoveryManager::CRecoveryManager(CTradingBasket *basket, CReporter *reporter, CSignalManager *signalManager, CNormalLotSizeCalculator *normalLotCalc,
                                       CRecoveryLotSizeCalculator *recoveryLotCalc, RecoveryOptions &options)
        : CTradingManager(basket, reporter)
    {
        _options = options;
        _basket = basket;
        _signalManager = signalManager;
        _normalLotCalc = normalLotCalc;
        _recoveryLotCalc = recoveryLotCalc;
        _gridGapCalc = new CGridGapCalculator(_basket.Symbol(), options.gridSizeMode, options.gridFixedSize, options.gridCustomSizeMode, options.gridCustomSeries,
                                              options.gridATRPeriod, options.newBarTimeframe, options.gridATRValueAction, options.gridATRValue, options.gridATRMin, options.gridATRMax);
    }

public:
    void OnTick();
    virtual bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message, Trade &newTrade)
    {
        double slPrice = 0, tpPrice = 0;
        double ask = SymbolInfoDouble(_basket.Symbol(), SYMBOL_ASK);
        double bid = SymbolInfoDouble(_basket.Symbol(), SYMBOL_BID);
        double spread = ask - bid;
        int spread_points = (int)MathRound(spread / SymbolInfoDouble(_basket.Symbol(), SYMBOL_POINT));
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
            if (_options.showTpLine)
            {
                _DrawPriceLine(_GetTPLineName(), _recoveryAvgTPrice, clrBlue, STYLE_DASH);
                _DrawPriceLine(_GetAVGOpenPriceLineName(), _basket.AverageOpenPrice(), clrOrange, STYLE_DASH);
            }

            if (_options.useVirtualSLTP)
            {
                _basket.SetTradeToVirtualSLTP(newTrade.Ticket(), slPrice, _recoveryAvgTPrice);
            }
            else
            {
                // TODO: set trades individual SL/TP
            }
        }
        return result;
    }

private:
    double _NextLotSize(string symbol, int slPoints, double lastLot, ENUM_ORDER_TYPE direction);
    double _CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction);
    void _DrawPriceLine(string name, double price, color clr, ENUM_LINE_STYLE style);
    string _GetTPLineName();
    string _GetAVGOpenPriceLineName();
    void _RemovePriceLine(string name);
};

void CRecoveryManager::OnTick()
{
    if (_basket.Status() == BASKET_OPEN && !_basket.IsEmpty())
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
        double ask = constants.Ask(symbol);
        double bid = constants.Bid(symbol);

        bool hitTP = lastTrade.OrderType() == ORDER_TYPE_BUY ? bid >= _recoveryAvgTPrice : ask <= _recoveryAvgTPrice;
        bool hitSL = lastTrade.OrderType() == ORDER_TYPE_BUY ? bid <= lastTradeSL : ask >= lastTradeSL;

        if (hitTP)
        {
            _basket.CloseBasketOrders();
        }
        else if (hitSL)
        {
            if (_options.maxGridOrderCount != 0 && _basket.Count() >= _options.maxGridOrderCount)
            {
                // Do nothing as we reached the max grid order count
                _reporter.ReportWarning(StringFormat("RM: Reached max grid order count %d", _options.maxGridOrderCount));
            }
            else
            {
                bool signalBuy = _signalManager.GetSignalWithAnd(SIGNAL_BUY);
                bool signalSell = _signalManager.GetSignalWithAnd(SIGNAL_SELL);

                bool tradeOnlyOnSignal = !_options.gridTradeOnlyBySignal || signalBuy || signalSell;
                bool tradeOnlyNewBar = !_options.gridTradeOnlyNewBar || constants.IsNewBar(symbol, _options.newBarTimeframe);

                if (tradeOnlyOnSignal && tradeOnlyNewBar)
                {
                    ENUM_ORDER_TYPE orderType = lastTrade.OrderType();
                    int nextGridGap = _gridGapCalc.CalculateNextOrderDistance(_basket.Count(), lastOpenPrice, firstTradeTp);
                    string message;
                    Trade trade;

                    // Check the recovery type here to know the next direction
                    if (_options.recoveryMode == RECOVERY_MARTINGALE)
                    {
                        double nextSLPrice = 0;
                        bool hasSingal = false;
                        if (orderType == ORDER_TYPE_BUY && (!_options.gridTradeOnlyBySignal || _signalManager.GetSignalWithAnd(SIGNAL_BUY)))
                        {
                            nextSLPrice = ask - NormalizeDouble(nextGridGap * _Point, _Digits);
                            hasSingal = true;
                        }
                        else if (orderType == ORDER_TYPE_SELL && (!_options.gridTradeOnlyBySignal || _signalManager.GetSignalWithAnd(SIGNAL_SELL)))
                        {
                            nextSLPrice = bid + NormalizeDouble(nextGridGap * _Point, _Digits);
                            hasSingal = true;
                        }

                        if (hasSingal)
                        {
                            double nextLot = _NextLotSize(symbol, nextGridGap, lastLot, orderType);
                            if (OpenTradeWithPrice(nextLot, ask, orderType, nextSLPrice, 0, StringFormat("RM: Order %d", _basket.Count() + 1), message, trade))
                            {
                                // Done
                            }
                            else
                            {
                                // Failed to open a recovery trade
                            }
                        }
                    }
                    else if (_options.recoveryMode == RECOVERY_HEDGING)
                    {
                        double nextSLPrice = ask + NormalizeDouble(nextGridGap * _Point, _Digits);
                        ENUM_ORDER_TYPE newOrderType = orderType == ORDER_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                        double nextLot = _NextLotSize(symbol, nextGridGap, lastLot, newOrderType);
                        if (OpenTradeWithPrice(nextLot, ask, newOrderType, nextSLPrice, _recoveryAvgTPrice, StringFormat("RM: Order %d", _basket.Count() + 1), message, trade))
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
        }
    }

    if (_basket.IsEmpty())
    {
        _RemovePriceLine(_GetTPLineName());
        _RemovePriceLine(_GetAVGOpenPriceLineName());
    }

    // execute base class OnTick
    CTradingManager::OnTick();
}

////////////////////////////////////////////////////
string CRecoveryManager::_GetTPLineName()
{
    return StringFormat("avg_tp_%d", _basket.MagicNumber());
}

string CRecoveryManager::_GetAVGOpenPriceLineName()
{
    return StringFormat("avg_open_%d", _basket.MagicNumber());
}

void CRecoveryManager::_RemovePriceLine(string name)
{
    if (ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);
}

void CRecoveryManager::_DrawPriceLine(string name, double price, color clr, ENUM_LINE_STYLE style)
{
    if (ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);
    if (!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
    {
        // utils.LogError(__FUNCTION__, "ObjectCreate(" + name + ",RECT) failed: ");
    }

    // Change the color
    if (!ObjectSetInteger(0, name, OBJPROP_COLOR, clr))
    {
        // utils.LogError(__FUNCTION__, "ObjectSet(" + name + ",color   ) [3] failed: ");
    }

    // Change the color
    if (!ObjectSetInteger(0, name, OBJPROP_STYLE, style))
    {
        // utils.LogError(__FUNCTION__, "ObjectSet(" + name + ",color   ) [3] failed: ");
    }
}

double CRecoveryManager::_CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction)
{
    double avgOpenPrice = _basket.AverageOpenPrice();
    return NormalizeDouble(avgOpenPrice + (((direction == ORDER_TYPE_BUY) ? 1 : -1) * _options.recoveryTpPoints * _Point), _Digits);
}

double CRecoveryManager::_NextLotSize(string symbol, int slPoints, double lastLot, ENUM_ORDER_TYPE direction)
{
    int basketCount = _basket.Count();
    double lotSize = 0;
    if (_options.recoveryMode == RECOVERY_MARTINGALE)
    {
        lotSize = _basket.IsEmpty()
                      ? _normalLotCalc.CalculateLotSize(symbol, slPoints, lastLot, basketCount, direction)
                      : _recoveryLotCalc.CalculateLotSize(symbol, slPoints, lastLot, basketCount, direction);
    }
    else if (_options.recoveryMode == RECOVERY_HEDGING)
    {
        double sellLots = _basket.Volume(ORDER_TYPE_SELL);
        double buyLots = _basket.Volume(ORDER_TYPE_BUY);
        if (direction == ORDER_TYPE_BUY)
        {
            lotSize = MathAbs((sellLots * ((_options.recoveryTpPoints + slPoints) / (double)_options.recoveryTpPoints)) - buyLots);
        }
        else
        {
            lotSize = MathAbs((buyLots * ((_options.recoveryTpPoints + slPoints) / (double)_options.recoveryTpPoints)) - sellLots);
        }

        lotSize = MathCeil(lotSize / constants.LotStep(symbol)) * constants.LotStep(symbol);
    }
    else
    {
        lotSize = constants.MinLot(symbol);
    }

    return _normalLotCalc.NormalizeLot(symbol, lotSize);
}
