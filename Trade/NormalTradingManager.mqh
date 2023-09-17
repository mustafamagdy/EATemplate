#include "TradingManager.mqh"
#include "..\UI\Reporter.mqh"
#include "..\Filters\FilterManager.mqh"

class CNormalTradingManager : public CTradingManager
{

public:
    CNormalTradingManager(CTradingBasket *basket, CReporter *reporter, CFilterManager &entryFilters, CFilterManager &exitFilters)
        : CTradingManager(basket, reporter, entryFilters, exitFilters)
    {
    }

public:
    void OnTick();
};

void CNormalTradingManager::OnTick()
{
    //  Close orders and remove them if SL/TP hit
    for (int i = _basket.Count() - 1; i >= 0; i--)
    {
        Trade trade;
        if (!_basket.GetTradeByIndex(i, trade))
            continue;

        ulong ticket = trade.Ticket();
        if (!PositionSelectByTicket(ticket))
        {
            continue;
        }

        // check virtual SL/TP if either, close and remove
        string symbol = PositionGetString(POSITION_SYMBOL);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double bidPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
        double askPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double takeProfit = trade.VirtualTakeProfit();
        double stopLoss = trade.VirtualStopLoss();
        bool closed = false;

        if ((type == POSITION_TYPE_BUY && bidPrice >= takeProfit) ||
            (type == POSITION_TYPE_SELL && askPrice <= takeProfit))
        {
            closed = _trade.PositionClose(ticket, ULONG_MAX);
        }
        else if ((type == POSITION_TYPE_BUY && bidPrice <= stopLoss) ||
                 (type == POSITION_TYPE_SELL && askPrice >= stopLoss))
        {
            closed = _trade.PositionClose(ticket, ULONG_MAX);
        }

        if (closed)
        {
            _basket.RemoveTradeByIndex(i);
        }
    }

    CTradingManager::OnTick();
}