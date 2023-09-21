#include <Object.mqh>
#include "..\Enums.mqh"
#include "TradingStatus.mqh"
#include "TradingBasket.mqh"
#include "..\Options.mqh"
#include "..\UI\Reporter.mqh"

class CPnLManager : public CObject
{
private:
    CReporter *_reporter;
    PnLOptions _options;
    CTradingStatusManager *_tradingStatusManager;
    CTradingBasket *_baskets[];

public:
    void OnTick();
    bool ValidateInput();

public:
    CPnLManager(PnLOptions &options, CReporter *reporter, CTradingStatusManager *tradingStatusManager)
    {
        _options = options;
        _reporter = reporter;
        _tradingStatusManager = tradingStatusManager;
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

bool CPnLManager::ValidateInput()
{
    if (_options.maxLossForAllPairs == 0 || _options.maxProfitForAllPairs == 0)
    {
        return (true);
    }

    if (_options.resetMode == RESET_AFTER_N_MINUTES && _options.resetAfterNMinutes <= 0)
    {
        _reporter.ReportError("Reset after minutes must be a positive number");
        return (false);
    }

    return (true);
}

void CPnLManager::OnTick()
{
    if (_options.maxLossForAllPairs <= 0)
    {
        return; // There is not limitation
    }
    double accountProfit = SumAccountProfit();
    if (accountProfit < 0 && MathAbs(accountProfit) > _options.maxLossForAllPairs)
    {
        datetime time = TimeCurrent();
        CTradingStatus *rule = new CTradingStatus();
        string reason = StringFormat("Loss reached %.2f and configured max value is %.2f", MathAbs(accountProfit), _options.maxLossForAllPairs);
        if (_options.resetMode == RESET_AFTER_N_MINUTES)
        {
            datetime expiryTime = time + (_options.resetAfterNMinutes * 60);
            rule.PauseTradingUntilExpiry(TRADING_PAUSED_ACCOUNT, reason, expiryTime, "", NULL);
        }
        else
        {
            rule.PauseTradingUntilRestart(TRADING_PAUSED_ACCOUNT, reason, "", NULL);
        }

        // 1- Adding rule to prevent future trading until either restart or expiry
        _tradingStatusManager.AddNewRule(rule);
        
        // 2- Closing all orders in all baskets
        for (int i = 0; i < ArraySize(_baskets); i++)
        {
            _reporter.ReportWarning("Closing all orders in basket due to exceeding max loss");
            _baskets[i].CloseBasketOrders();
        }
    }
}