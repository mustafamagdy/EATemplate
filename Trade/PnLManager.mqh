#include <Object.mqh>
#include "..\Enums.mqh"
#include "TradingStatus.mqh"
#include "..\Options.mqh"


class CPnLManager : public CObject
{
private:
    PnLOptions _options;
    CTradingStatusManager *_tradingStatusManager;

public:
    CPnLManager(PnLOptions &options)
    {
        _options = options;
    }

    bool CheckPnLRules(string symbol, datetime time, double accountProfit);
};

bool CPnLManager::CheckPnLRules(string symbol, datetime time, double accountProfit)
{
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

        // 2- returning false for the basket to close the trades now
        return (false);
    }
    return (true);
}