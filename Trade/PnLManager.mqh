#include <Object.mqh>
#include "..\Enums.mqh"
#include "TradingStatus.mqh"
#include "TradingBasket.mqh"
#include "..\Options.mqh"

class CPnLManager : public CObject
{
private:
    PnLOptions _options;
    CTradingStatusManager *_tradingStatusManager;
    CTradingBasket *_baskets[];

public:
    void OnTick();

public:
    CPnLManager(PnLOptions &options)
    {
        _options = options;
        ArrayResize(_baskets, 0);
    }

    void RegisterBasket(CTradingBasket *basket)
    {
        ArrayResize(_baskets, ArraySize(_baskets) + 1);
        _baskets[ArraySize(_baskets) - 1] = basket;
    }

    double SumAccountProfit()
    {
        double result = 0;
        for (int i = 0; i < ArraySize(_baskets); i++)
        {
            result += _baskets[i].Profit();
        }
        return (result);
    }
};

void CPnLManager::OnTick()
{
    datetime time = TimeCurrent();
    if (_options.maxLossForAllPairs <= 0)
    {
        return; // There is not limitation
    }
    double accountProfit = SumAccountProfit();
    if (accountProfit < 0 && MathAbs(accountProfit) > _options.maxLossForAllPairs)
    {
        // 1- Adding rule to prevent future trading until either restart or expiry
        CTradingStatus rule = new CTradingStatus();
        string reason = StringFormat("Loss reached %.2f and configured max value is %.2f", MathAbs(accountProfit), _options.maxLossForAllPairs);
        if (_options.resetMode == RESET_24_HOURS)
        {
            datetime expiryTime = time + (24 * 60 * 60);
            rule.PauseTradingUntilExpiry(TRADING_PAUSED_ACCOUNT, reason, expiryTime, "", NULL);
        }
        else
        {
            rule.PauseTradingUntilRestart(TRADING_PAUSED_ACCOUNT, reason, "", NULL);
        }

        for (int i = 0; i < ArraySize(_baskets); i++)
        {
            _baskets[i].CloseBasketOrders();
        }
    }
}