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
#include "..\Filters\FilterManager.mqh"

class CRecoveryManager : public CTradingManager
{

private:
    CNormalLotSizeCalculator *_normalLotCalc;
    CRecoveryLotSizeCalculator *_recoveryLotCalc;
    CGridGapCalculator *_gridGapCalc;
    CSignalManager *_signalManager;
    RecoveryOptions _options;
    double _recoveryAvgTPrice;
    double _recoverySLPrice;

public:
    CRecoveryManager::CRecoveryManager(CTradingBasket *basket, CReporter *reporter, CSignalManager *signalManager,
                                       CNormalLotSizeCalculator *normalLotCalc, CRecoveryLotSizeCalculator *recoveryLotCalc,
                                       RecoveryOptions &options, CFilterManager &entryFilters, CFilterManager &exitFilters)
        : CTradingManager(basket, reporter, entryFilters, exitFilters)
    {
        _options = options;
        _basket = basket;
        _signalManager = signalManager;
        _normalLotCalc = normalLotCalc;
        _recoveryLotCalc = recoveryLotCalc;
        _gridGapCalc = new CGridGapCalculator(_basket.Symbol(), options.gridSizeMode, options.gridFixedSize, options.gridCustomSizeMode, options.gridCustomSeries,
                                              options.gridATRPeriod, options.newBarTimeframe, options.gridATRValueAction, options.gridATRActionValue, options.gridATRMin, options.gridATRMax);
    }

public:
    void OnTick();
    virtual bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string comment, string &message, Trade &newTrade);
    virtual bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message, Trade &newTrade);

private:
    void SetRecoveryPrices(Trade &firstTrade, double directionFactor);
    bool CheckHitSL(Trade &firstTrade, double directionFactor, bool isItBuy, double bid, double ask);
    void HandleNextOrderOpen(Trade &lastTrade, string &symbol, double ask, double bid, bool isItBuy);
    void CleanUp();
    double NextLotSize(string symbol, int slPoints, double lastLot, ENUM_ORDER_TYPE direction);
    double CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction);
    double CalculateAvgSLPriceForMartingale(ENUM_ORDER_TYPE direction);
    void DrawPriceLine(string name, double price, color clr, ENUM_LINE_STYLE style);
    void RemovePriceLine(string name);
    string GetTPLineName();
    string GetSLLineName();
    string GetAVGOpenPriceLineName();
};

void CRecoveryManager::OnTick()
{
    if (_basket.Status() != BASKET_OPEN || _basket.IsEmpty())
    {
        CleanUp();
        CTradingManager::OnTick();
        return;
    }

    Trade firstTrade, lastTrade;
    _basket.FirstTrade(firstTrade);
    _basket.LastTrade(lastTrade);

    string symbol = _basket.Symbol();
    bool isItBuy = lastTrade.OrderType() == ORDER_TYPE_BUY;
    double ask = constants.Ask(symbol);
    double bid = constants.Bid(symbol);
    double spread = ask - bid;
    double lastTradeSL = lastTrade.VirtualStopLoss();
    double directionFactor = (isItBuy ? -1 : 1);

    SetRecoveryPrices(firstTrade, directionFactor);

    bool hitTP = isItBuy ? bid >= _recoveryAvgTPrice : ask <= _recoveryAvgTPrice;
    bool hitSL = CheckHitSL(firstTrade, directionFactor, isItBuy, bid, ask);

    if (_options.showSLLine && _recoverySLPrice > 0)
    {
        DrawPriceLine(GetSLLineName(), _recoverySLPrice, clrIndianRed, STYLE_DASH);
    }

    if (hitTP || hitSL)
    {
        _basket.CloseBasketOrders();
    }
    else
    {
        HandleNextOrderOpen(lastTrade, symbol, ask, bid, isItBuy);
    }

    CleanUp();
    CTradingManager::OnTick();
}

void CRecoveryManager::SetRecoveryPrices(Trade &firstTrade, double directionFactor)
{
    if (_basket.Count() == 1)
    {
        _recoveryAvgTPrice = firstTrade.VirtualTakeProfit();
        if (_options.recoverySLPoints > 0)
        {
            _recoverySLPrice = firstTrade.OpenPrice() + (directionFactor * (_options.recoverySLPoints * _Point));
        }
    }
}

bool CRecoveryManager::CheckHitSL(Trade &firstTrade, double directionFactor, bool isItBuy, double bid, double ask)
{
    if (_options.recoverySLPoints == 0)
        return false;

    bool hitSL = false;
    switch (_options.basketSLMode)
    {
    case MAX_SL_MODE_AVERAGE:
    {
        double currentAvgOpenPrice = _basket.AverageOpenPrice();                               // Get the new average open price
        double distanceMoved = MathAbs(currentAvgOpenPrice - firstTrade.OpenPrice()) / _Point; // Calculate the distance moved from the initial average open price
        double dynamicStopLossDistance = (_options.recoverySLPoints - distanceMoved);
        _recoverySLPrice = firstTrade.OpenPrice() + (directionFactor * dynamicStopLossDistance * _Point); // Update the stop loss based on the dynamic distance
        hitSL = _recoverySLPrice > 0 && (isItBuy ? bid <= _recoverySLPrice : ask >= _recoverySLPrice);
        break;
    }
    case MAX_SL_MODE_INDIVIDUAL:
    {
        // should be handled on each order inside the basket
        break;
    }
    case MAX_SL_MODE_GAP_FROM_FIRST:
    {
        double distance = MathAbs(firstTrade.OpenPrice() - (isItBuy ? bid : ask)) / _Point;
        _recoverySLPrice = firstTrade.OpenPrice() + (directionFactor * (_options.recoverySLPoints * _Point));
        hitSL = _recoverySLPrice > 0 && (isItBuy ? bid <= _recoverySLPrice : ask >= _recoverySLPrice); // distance >= _options.recoverySLPoints;
        break;
    }
    }

    return hitSL;
}

void CRecoveryManager::HandleNextOrderOpen(Trade &lastTrade, string &symbol, double ask, double bid, bool isItBuy)
{
    double lastOpenPrice = lastTrade.OpenPrice();
    double firstTradeTp = lastTrade.TakeProfit();
    double lastLot = lastTrade.Volume();
    double lastTradeSL = lastTrade.VirtualStopLoss();

    bool hitNextOrderOpen = isItBuy ? bid <= lastTradeSL : ask >= lastTradeSL;

    if (!hitNextOrderOpen)
        return;

    if ((!isItBuy && bid <= lastTradeSL) || (isItBuy && ask >= lastTradeSL))
    {
        _reporter.ReportWarning("Spread is too wide, cannot open any orders now.");
        return;
    }

    if (_options.maxGridOrderCount != 0 && _basket.Count() >= _options.maxGridOrderCount)
    {
        if (_options.basketMaxOrderBehaviour == MAX_ORDER_STOP_ADDING_GRID)
        {
            _reporter.ReportWarning(StringFormat("RM: Reached max grid order count %d", _options.maxGridOrderCount));
            return;
        }
    }

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
            bool hasSignal = false;
            if (orderType == ORDER_TYPE_BUY && (!_options.gridTradeOnlyBySignal || signalBuy))
            {
                nextSLPrice = ask - NormalizeDouble(nextGridGap * _Point, _Digits);
                hasSignal = true;
            }
            else if (orderType == ORDER_TYPE_SELL && (!_options.gridTradeOnlyBySignal || signalSell))
            {
                nextSLPrice = bid + NormalizeDouble(nextGridGap * _Point, _Digits);
                hasSignal = true;
            }

            if (hasSignal)
            {
                double nextLot = NextLotSize(symbol, nextGridGap, lastLot, orderType);
                if (OpenTradeWithPrice(nextLot, ask, orderType, nextSLPrice, 0, StringFormat("RM: Order %d", _basket.Count() + 1), message, trade))
                {
                    _reporter.ReportTradeOpen(orderType, nextLot);
                    if (_options.maxGridOrderCount != 0 && _basket.Count() > _options.maxGridOrderCount)
                    {
                        if (_options.basketMaxOrderBehaviour == MAX_ORDER_CLOSE_FIRST_ORDER)
                        {
                            _basket.CloseFirstOrder();
                        }
                    }
                }
                else
                {
                    _reporter.ReportError("Failed to open grid order");
                }
            }
        }
        else if (_options.recoveryMode == RECOVERY_HEDGING)
        {
            double nextSLPrice = ask + NormalizeDouble(nextGridGap * _Point, _Digits);
            ENUM_ORDER_TYPE newOrderType = orderType == ORDER_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            double nextLot = NextLotSize(symbol, nextGridGap, lastLot, newOrderType);
            if (OpenTradeWithPrice(nextLot, ask, newOrderType, nextSLPrice, _recoveryAvgTPrice, StringFormat("RM: Order %d", _basket.Count() + 1), message, trade))
            {
                _reporter.ReportTradeOpen(orderType, nextLot);
                if (_options.maxGridOrderCount != 0 && _basket.Count() > _options.maxGridOrderCount)
                {
                    if (_options.basketMaxOrderBehaviour == MAX_ORDER_CLOSE_FIRST_ORDER)
                    {
                        _basket.CloseFirstOrder();
                    }
                }
            }
            else
            {
                _reporter.ReportError("Failed to open grid order");
            }
        }
    }
}

void CRecoveryManager::CleanUp()
{
    if (_basket.IsEmpty())
    {
        RemovePriceLine(GetTPLineName());
        RemovePriceLine(GetSLLineName());
        RemovePriceLine(GetAVGOpenPriceLineName());
    }
}

bool CRecoveryManager::OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message, Trade &newTrade)
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

bool CRecoveryManager::OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string comment, string &message, Trade &newTrade)
{
    bool result = CTradingManager::OpenTradeWithPrice(volume, price, orderType, 0, 0, message, newTrade, slPrice, tpPrice, comment);
    if (result)
    {
        _recoveryAvgTPrice = CalculateAvgTPPriceForMartingale(orderType);
        DrawPriceLine(GetAVGOpenPriceLineName(), _basket.AverageOpenPrice(), clrOrange, STYLE_DASH);

        if (_options.showTpLine && _recoveryAvgTPrice > 0)
        {
            DrawPriceLine(GetTPLineName(), _recoveryAvgTPrice, clrBlue, STYLE_DASH);
        }

        if (_options.useVirtualSLTP)
        {
            _basket.SetTradeToVirtualSLTP(newTrade.Ticket(), slPrice, _recoveryAvgTPrice);
        }
        else
        {
            _basket.UpdateSLTP(_options.recoverySLPoints, _recoveryAvgTPrice);
        }
    }
    return result;
}

////////////////////////////////////////////////////
string CRecoveryManager::GetTPLineName()
{
    return StringFormat("avg_tp_%d", _basket.MagicNumber());
}

string CRecoveryManager::GetSLLineName()
{
    return StringFormat("avg_sl_%d", _basket.MagicNumber());
}

string CRecoveryManager::GetAVGOpenPriceLineName()
{
    return StringFormat("avg_open_%d", _basket.MagicNumber());
}

void CRecoveryManager::RemovePriceLine(string name)
{
    if (ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);
}

void CRecoveryManager::DrawPriceLine(string name, double price, color clr, ENUM_LINE_STYLE style)
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

double CRecoveryManager::CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction)
{
    double avgOpenPrice = _basket.AverageOpenPrice();
    return NormalizeDouble(avgOpenPrice + (((direction == ORDER_TYPE_BUY) ? 1 : -1) * _options.recoveryTpPoints * _Point), _Digits);
}

double CRecoveryManager::CalculateAvgSLPriceForMartingale(ENUM_ORDER_TYPE direction)
{
    double avgOpenPrice = _basket.AverageOpenPrice();
    return NormalizeDouble(avgOpenPrice + (((direction == ORDER_TYPE_BUY) ? -1 : 1) * _options.recoverySLPoints * _Point), _Digits);
}

double CRecoveryManager::NextLotSize(string symbol, int slPoints, double lastLot, ENUM_ORDER_TYPE direction)
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

    lotSize = _options.maxGridLots > 0 ? MathMin(lotSize, _options.maxGridLots) : lotSize;
    return _normalLotCalc.NormalizeLot(symbol, lotSize);
}
