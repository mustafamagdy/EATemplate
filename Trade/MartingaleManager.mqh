#include <Object.mqh>
#include ".\TradingBasket.mqh";
#include ".\TradingManager.mqh";
#include "TradingStatus.mqh"
#include "..\Enums.mqh";
#include "..\Constants.mqh";
#include "..\Options.mqh";
#include "..\Recovery\GridGapCalculator.mqh";
#include "..\Recovery\MartingaleLotSizeCalculator.mqh";
#include "..\Signals\SignalManager.mqh";
#include "..\RiskManagement\NormalLotSizeCalculator.mqh";
#include "..\UI\Reporter.mqh";
#include "..\Filters\FilterManager.mqh"
#include "..\UI\UIHelper.mqh"

class CMartingaleManager : public CTradingManager
{

private:    
    CNormalLotSizeCalculator *_normalLotCalc;
    CMartingaleLotSizeCalculator *_recoveryLotCalc;
    CGridGapCalculator *_gridGapCalc;
    CSignalManager *_signalManager;
    MartingaleOptions _options;
    double _recoveryAvgTPrice;
    double _recoverySLPrice;

public:
    CMartingaleManager::CMartingaleManager(CTradingBasket *basket, CConstants *constants, CReporter *reporter, CUIHelper *uiHelper, 
                                       CSignalManager *signalManager, CNormalLotSizeCalculator *normalLotCalc, CMartingaleLotSizeCalculator *recoveryLotCalc,
                                       CTradingStatusManager *tradingStatusManager, MartingaleOptions &options)
        : CTradingManager(constants, uiHelper, basket, reporter, tradingStatusManager)
    {      
        _options = options;
        _basket = basket;
        _signalManager = signalManager;
        _normalLotCalc = normalLotCalc;
        _recoveryLotCalc = recoveryLotCalc;
        _gridGapCalc = new CGridGapCalculator(_basket.Symbol(), constants, options.gridSizeMode, options.gridFixedSize, options.gridCustomSizeMode, options.gridGapCustomSeries,
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
    double NextLotSize(string symbol, int slPoints, double lastLot, double firstLot, ENUM_ORDER_TYPE direction);
    double CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction);
    double CalculateAvgSLPriceForMartingale(ENUM_ORDER_TYPE direction);
    string GetTPLineName();
    string GetSLLineName();
    string GetAVGOpenPriceLineName();
    string GetNextOrderLineName();
};

void CMartingaleManager::OnTick()
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
    double ask = _constants.Ask(symbol);
    double bid = _constants.Bid(symbol);
    double spread = ask - bid;
    double lastTradeSL = lastTrade.VirtualStopLoss();
    double directionFactor = (isItBuy ? -1 : 1);

    SetRecoveryPrices(firstTrade, directionFactor);

    double totalCommissionAndSwap = _basket.TotalCommission() + _basket.TotalSwap();
    double adjustmentPerPoint = (totalCommissionAndSwap / _basket.Volume()) / _constants.Point(_basket.Symbol());
    double adjustedTP = isItBuy ? (_recoveryAvgTPrice - adjustmentPerPoint) : (_recoveryAvgTPrice + adjustmentPerPoint);

    bool hitTP = isItBuy ? bid >= adjustedTP : ask <= adjustedTP;

    bool hitSL = CheckHitSL(firstTrade, directionFactor, isItBuy, bid, ask);

    if (_options.showSLLine && _recoverySLPrice > 0)
    {
        _uiHelper.DrawPriceLine(GetSLLineName(), _recoverySLPrice, clrIndianRed, STYLE_DASH);
    }

    _uiHelper.DrawPriceLine(GetNextOrderLineName(), lastTradeSL, clrPink, STYLE_DASH);

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

void CMartingaleManager::SetRecoveryPrices(Trade &firstTrade, double directionFactor)
{
    if (_basket.Count() == 1)
    {
        _recoveryAvgTPrice = firstTrade.VirtualTakeProfit();
        if (_options.recoverySLPoints > 0)
        {
            _recoverySLPrice = firstTrade.OpenPrice() + (directionFactor * (_options.recoverySLPoints * _constants.Point(_basket.Symbol())));
        }
    }
}

bool CMartingaleManager::CheckHitSL(Trade &firstTrade, double directionFactor, bool isItBuy, double bid, double ask)
{
    if (_options.recoverySLPoints == 0)
        return false;

    bool hitSL = false;
    switch (_options.basketSLMode)
    {
    case MAX_SL_MODE_AVERAGE:
    {
        double currentAvgOpenPrice = _basket.AverageOpenPrice();                                                           // Get the new average open price
        double distanceMoved = MathAbs(currentAvgOpenPrice - firstTrade.OpenPrice()) / _constants.Point(_basket.Symbol()); // Calculate the distance moved from the initial average open price
        double dynamicStopLossDistance = (_options.recoverySLPoints - distanceMoved);
        _recoverySLPrice = firstTrade.OpenPrice() + (directionFactor * dynamicStopLossDistance * _constants.Point(_basket.Symbol())); // Update the stop loss based on the dynamic distance
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
        double distance = MathAbs(firstTrade.OpenPrice() - (isItBuy ? bid : ask)) / _constants.Point(_basket.Symbol());
        _recoverySLPrice = firstTrade.OpenPrice() + (directionFactor * (_options.recoverySLPoints * _constants.Point(_basket.Symbol())));
        hitSL = _recoverySLPrice > 0 && (isItBuy ? bid <= _recoverySLPrice : ask >= _recoverySLPrice); // distance >= _options.recoverySLPoints;
        break;
    }
    }

    return hitSL;
}

void CMartingaleManager::HandleNextOrderOpen(Trade &lastTrade, string &symbol, double ask, double bid, bool isItBuy)
{
    double lastOpenPrice = lastTrade.OpenPrice();
    double firstTradeTp = lastTrade.TakeProfit();
    double lastLot = lastTrade.Volume();
    double firstLot = _basket.FirstOrderVolume();
    double lastTradeSL = lastTrade.VirtualStopLoss();

    //bool hitNextOrderOpen = isItBuy ? bid <= lastTradeSL : ask >= lastTradeSL;
    bool hitNextOrderOpen = isItBuy ? ask <= lastTradeSL : bid >= lastTradeSL;
    
    if (!hitNextOrderOpen)
        return;

    /*
        if(_basket.Count() == 1) {
            //reduce first order by closing 2/3 of it on loss and start recoving it
            _basket.ClosePartial(0.93);
        }
    */
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
    bool tradeOnlyNewBar = !_options.gridTradeOnlyNewBar || _constants.IsNewBar(symbol, _options.newBarTimeframe);

    if (tradeOnlyOnSignal && tradeOnlyNewBar)
    {
        ENUM_ORDER_TYPE orderType = lastTrade.OrderType();
        int nextGridGap = _gridGapCalc.CalculateNextOrderDistance(_basket.Count(), lastOpenPrice, firstTradeTp);
        string message;
        Trade trade;

        double nextSLPrice = 0;
        bool hasSignal = false;
        if (orderType == ORDER_TYPE_BUY && (!_options.gridTradeOnlyBySignal || signalBuy))
        {
            nextSLPrice = ask - NormalizeDouble(nextGridGap * _constants.Point(_basket.Symbol()), _Digits);
            hasSignal = true;
        }
        else if (orderType == ORDER_TYPE_SELL && (!_options.gridTradeOnlyBySignal || signalSell))
        {
            nextSLPrice = bid + NormalizeDouble(nextGridGap * _constants.Point(_basket.Symbol()), _Digits);
            hasSignal = true;
        }

        if (hasSignal)
        {
            double nextLot = NextLotSize(symbol, nextGridGap, lastLot, firstLot, orderType);
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
}

void CMartingaleManager::CleanUp()
{
    if (_basket.IsEmpty())
    {
        _uiHelper.RemoveLine(GetTPLineName());
        _uiHelper.RemoveLine(GetSLLineName());
        _uiHelper.RemoveLine(GetAVGOpenPriceLineName());
        _uiHelper.RemoveLine(GetNextOrderLineName());
    }
}

bool CMartingaleManager::OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message, Trade &newTrade)
{
    double slPrice = 0, tpPrice = 0;
    double ask = SymbolInfoDouble(_basket.Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(_basket.Symbol(), SYMBOL_BID);
    double spread = ask - bid;
    int spread_points = (int)MathRound(spread / _constants.Point(_basket.Symbol()));
    if (slPoints <= spread_points)
    {
        message = "SL points is less than the spread points";
        return (false);
    }

    if (orderType == ORDER_TYPE_BUY)
    {
        slPrice = slPoints > 0 ? price - (slPoints * _constants.Point(_basket.Symbol())) : 0;
        tpPrice = tpPoints > 0 ? price + (tpPoints * _constants.Point(_basket.Symbol())) : 0;
    }
    else
    {
        slPrice = slPoints > 0 ? price + (slPoints * _constants.Point(_basket.Symbol())) : 0;
        tpPrice = tpPoints > 0 ? price - (tpPoints * _constants.Point(_basket.Symbol())) : 0;
    }
    return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, comment, message, newTrade);
}

bool CMartingaleManager::OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string comment, string &message, Trade &newTrade)
{
    bool result = CTradingManager::OpenTradeWithPrice(volume, price, orderType, 0, 0, message, newTrade, slPrice, tpPrice, comment);
    if (result)
    {
        _recoveryAvgTPrice = CalculateAvgTPPriceForMartingale(orderType);
        _uiHelper.DrawPriceLine(GetAVGOpenPriceLineName(), _basket.AverageOpenPrice(), clrOrange, STYLE_DASH);

        if (_options.showTpLine && _recoveryAvgTPrice > 0)
        {
            _uiHelper.DrawPriceLine(GetTPLineName(), _recoveryAvgTPrice, clrGreen, STYLE_SOLID, 2);
            //TODO: Remove standrad TP, SL line for the original order if exist
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
string CMartingaleManager::GetTPLineName()
{
    return StringFormat("avg_tp_%d", _basket.MagicNumber());
}

string CMartingaleManager::GetSLLineName()
{
    return StringFormat("avg_sl_%d", _basket.MagicNumber());
}

string CMartingaleManager::GetAVGOpenPriceLineName()
{
    return StringFormat("avg_open_%d", _basket.MagicNumber());
}

string CMartingaleManager::GetNextOrderLineName()
{
    return StringFormat("next_order_%d", _basket.MagicNumber());
}

double CMartingaleManager::CalculateAvgTPPriceForMartingale(ENUM_ORDER_TYPE direction)
{
    double avgOpenPrice = _basket.AverageOpenPrice();
    return NormalizeDouble(avgOpenPrice + (((direction == ORDER_TYPE_BUY) ? 1 : -1) * _options.recoveryTpPoints * _constants.Point(_basket.Symbol())), _Digits);
}

double CMartingaleManager::CalculateAvgSLPriceForMartingale(ENUM_ORDER_TYPE direction)
{
    double avgOpenPrice = _basket.AverageOpenPrice();
    return NormalizeDouble(avgOpenPrice + (((direction == ORDER_TYPE_BUY) ? -1 : 1) * _options.recoverySLPoints * _constants.Point(_basket.Symbol())), _Digits);
}

double CMartingaleManager::NextLotSize(string symbol, int slPoints, double lastLot, double firstLot, ENUM_ORDER_TYPE direction)
{
    int basketCount = _basket.LastOrderCount();
    double lotSize = 0;
    lotSize = _basket.IsEmpty()
                  ? _normalLotCalc.CalculateLotSize(symbol, slPoints, lastLot, firstLot, basketCount, direction)
                  : _recoveryLotCalc.CalculateLotSize(symbol, slPoints, lastLot, firstLot, basketCount, direction);
    lotSize = _options.maxGridLots > 0 ? MathMin(lotSize, _options.maxGridLots) : lotSize;
    return _normalLotCalc.NormalizeLot(symbol, lotSize);
}
