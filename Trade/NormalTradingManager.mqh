#include "TradingManager.mqh"
#include "TradingStatus.mqh"
#include "..\UI\Reporter.mqh"
#include "..\Filters\FilterManager.mqh"
#include "..\Constants.mqh"
#include "..\UI\UIHelper.mqh"

class CNormalTradingManager : public CTradingManager
{

public:
    CNormalTradingManager(CTradingBasket *basket, CConstants *constants, CReporter *reporter, CUIHelper *uiHelper, CTradingStatusManager *tradingStatusManager)
        : CTradingManager(constants, uiHelper, basket, reporter, tradingStatusManager)
    {
    }

private:
   void CleanUp();
   bool CheckHitSL(Trade &firstTrade, double directionFactor, bool isItBuy, double bid, double ask);
   
public:
    void OnTick();
};

void CNormalTradingManager::CleanUp()
{
    if (_basket.IsEmpty())
    {
        _uiHelper.RemoveLine(_basket.GetTpLineName());        
    }
}

void CNormalTradingManager::OnTick()
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

    double totalCommissionAndSwap = _basket.TotalCommission() + _basket.TotalSwap();
    double swapCommPerTrade = (totalCommissionAndSwap / _basket.Volume()) / _constants.Point(_basket.Symbol());
    double basketAvgOpenPrice = _basket.AverageOpenPrice();
    double defaultTP = 200 * _constants.Point(_basket.Symbol());
    double adjustedTP = isItBuy ? (basketAvgOpenPrice - swapCommPerTrade + defaultTP) : (basketAvgOpenPrice + swapCommPerTrade - defaultTP);

    bool hitTP = isItBuy ? bid >= adjustedTP : ask <= adjustedTP;

    bool hitSL = CheckHitSL(firstTrade, directionFactor, isItBuy, bid, ask);

    if (hitTP || hitSL)
    {
        _basket.CloseBasketOrders();
    }
    
    CleanUp();
    CTradingManager::OnTick();
}


bool CNormalTradingManager::CheckHitSL(Trade &firstTrade, double directionFactor, bool isItBuy, double bid, double ask)
{
    double defaultSLPoints = 200 * _constants.Point(_basket.Symbol());
    bool hitSL = false;
     
    double basketAvgOpenPrice = _basket.AverageOpenPrice();
    double slPrice = (defaultSLPoints * directionFactor) + basketAvgOpenPrice;
    hitSL = slPrice > 0 && (isItBuy ? bid <= slPrice : ask >= slPrice);
    
    return hitSL;
}