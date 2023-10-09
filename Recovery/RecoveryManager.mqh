#include "..\Constants.mqh";
#include "..\Enums.mqh";
#include "..\Options.mqh";
#include "..\Trade\TradingManager.mqh";
#include "..\Trade\TradingBasket.mqh";

/*
    - main basket contains all the original orders, and manual orders opened after that
    - if locking is enabled, we will have a locking basket, contains positions
        opened to lock all opened positions in the main basket
    - recovery basket, contains all the current recovery orders (average orders)
 */
class CRecoveryManager : CTradingManager
{

private:
    bool useLocking;
    double DDValue;
    double DDValueType;

    CTradingBasket *lockingBasket;
    CTradingBasket *recoveryBasket;

public:
    bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice,
                            string &message, Trade &newTrade, double virtualSLPrice = 0, double virtualTPPrice = 0, string comment = "");
    void OpenLockingPosition(Trade &trade);

public:
    CRecoveryManager::CRecoveryManager(RecoveryOptions &options, CConstants *constnats, CTradingBasket *basket,
                                       CReporter *reporter, CTradingStatusManager *tradingStatusManager)
        : CTradingManager(constnats, basket, reporter, tradingStatusManager)
    {
        useLocking = options.useLocking;
        DDValue = options.DDValue;
        DDValueType = options.DDValueType;
    }
};

bool CRecoveryManager::OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice,
                                          string &message, Trade &newTrade, double virtualSLPrice = 0, double virtualTPPrice = 0, string comment = "")
{
    bool result = CTradingManager::OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade,
                                                      virtualSLPrice, virtualTPPrice, comment);

    if (useLocking)
    {
        OpenLockingPosition(newTrade);
    }

    return result;
}

void CRecoveryManager::OpenLockingPosition(Trade &trade)
{
    string message;
    Trade newTrade;
    string comment = StringFormat("Locking for #%g", trade.Ticket());
    ENUM_ORDER_TYPE orderType;
    double price;
    if (trade.OrderType() == ORDER_TYPE_BUY)
    {
        orderType = ORDER_TYPE_SELL;
        price = _constants.Bid(trade.Symbol());
    }
    else
    {
        orderType = ORDER_TYPE_BUY;
        price = _constants.Ask(trade.Symbol());
    }
    bool success = _basket.OpenTradeWithPrice(trade.Volume(), price, orderType, 0, 0, message, newTrade, 0, 0, comment);
    if (success)
    {
        _reporter.ReportTradeOpen(orderType);
    }
    else
    {
        _reporter.ReportError("Failed to open locking order");
    }
}
