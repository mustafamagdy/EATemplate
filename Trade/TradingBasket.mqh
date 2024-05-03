#ifdef __MQL5__
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\DealInfo.mqh>
#else
#include "Trade_mql4.mqh"
#include "PositionInfo.mqh"
#endif
#include <Object.mqh>
#include "Trade.mqh"
#include "..\UI\Reporter.mqh"
#include "..\Common.mqh"
#include "..\Constants.mqh"

enum ENUM_BASKET_STATUS
{
    BASKET_OPEN = 0,
    BASKET_CLOSING = 1,
    BASKET_CLOSED = 2,
};

class CTradingBasket : public CObject
{
private:
    CReporter *_reporter;
    CConstants *_constants;

    Trade _trades[];
    ENUM_BASKET_STATUS _basketStatus;
    long _magicNumber;
    string pSymbol;
    double basketAvgTpPrice;
    double basketAvgSlPrice;
    int lastOrderCount;
    double firstOrderVolume;
    double profit;
    double totalCommission;

public:
    CTradingBasket(string symbol, long magicNumber, CReporter *reporter, CConstants *constants);
    ~CTradingBasket();

public:
    double Volume();
    double Volume(ENUM_ORDER_TYPE orderType);
    long MagicNumber() { return _magicNumber; }
    double AverageOpenPrice();
    double Profit() { return profit; }
    void ResetPnL() { profit = 0; }
    int Count();
    string Symbol();
    bool HasOpenedTrades();
    bool IsEmpty();
    ENUM_BASKET_STATUS Status();
    bool FirstTrade(Trade &trade);
    bool LastTrade(Trade &trade);
    int LastOrderCount() { return lastOrderCount; }
    double FirstOrderVolume() { return firstOrderVolume; }

public:
    void SetBasketAvgTpPrice(double tpPrice);

// The MQL5 (MetaQuotes Language 5) is a programming language used for developing trading strategies, indicators, scripts, and function libraries for the MetaTrader 5 trading platform. The language is used to create automated trading systems, commonly known as Expert Advisors (EAs).
// 
// The function `OpenTradeWithPoints` is not a standard function in MQL5; it seems like a custom function that might have been written by a user for a specific trading strategy. Since the function is not part of the standard MQL5 library, I'll create a hypothetical example of what this function might look like and explain how it could work.
// 

// Hypothetical example of a custom function to open a trade with a specific number of points
bool OpenTradeWithPoints(string symbol, ENUM_ORDER_TYPE orderType, double lotSize, int points, int slippage, double stopLoss, double takeProfit) {
    // Calculate the desired entry price based on the order type and number of points
    double entryPrice;
    if (orderType == ORDER_TYPE_BUY) {
        entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK) + points * _Point;
    } else if (orderType == ORDER_TYPE_SELL) {
        entryPrice = SymbolInfoDouble(symbol, SYMBOL_BID) - points * _Point;
    } else {
        // Unsupported order type
        return false;
    }

    // Create a request structure for the trade operation
    MqlTradeRequest request;
    ZeroMemory(request);
    request.action = TRADE_ACTION_DEAL; // Immediate execution
    request.symbol = symbol; // Trading symbol
    request.volume = lotSize; // Volume in lots
    request.type = orderType; // Order type (buy or sell)
    request.price = entryPrice; // Entry price
    request.sl = stopLoss; // Stop loss price
    request.tp = takeProfit; // Take profit price
    request.deviation = slippage; // Maximum price slippage in points
    request.magic = 0; // Magic number to identify trades from this EA
    request.comment = "Trade opened with points"; // Comment for the trade

    // Send the trade request
    MqlTradeResult result;
    if (!OrderSend(request, result)) {
        // If the trade request failed, print the error
        PrintFormat("Trade failed: error code %d", result.retcode);
        return false;
    }

    // Trade was successful
    return true;
}

// 
// In this hypothetical `OpenTradeWithPoints` function, the following parameters are used:
// 
// - `symbol`: The trading symbol (currency pair, stock, etc.) for the trade.
// - `orderType`: The type of order to be placed (buy or sell).
// - `lotSize`: The size of the trade in lots.
// - `points`: The number of points to add or subtract from the current price to determine the entry price.
// - `slippage`: The maximum price slippage allowed for the trade.
// - `stopLoss`: The stop loss price.
// - `takeProfit`: The take profit price.
// 
// The function calculates the entry price by adding or subtracting the specified number of points from the current ask or bid price, depending on whether it's a buy or sell order. It then creates a trade request structure (`MqlTradeRequest`) and sends the trade request using the `OrderSend` function. If the trade is successful, the function returns `true`; otherwise, it prints an error message and returns `false`.
// 
// Please note that this is a hypothetical example, and the actual `OpenTradeWithPoints` function in your context may work differently. It's essential to understand the specific implementation details of any custom function in MQL5 to use it correctly.
// 
    bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string &message, Trade &newTrade, int virtualSLPoints, int virtualTPPoints, string comment);
// The function signature you've provided for `OpenTradeWithPoints` seems to be a custom function that is not part of the standard MQL5 library. However, I can explain what this function might do based on the parameters and typical MQL5 conventions.
// 
// The `OpenTradeWithPoints` function appears to be designed to open a trade with a specified volume, price, order type, and to set stop loss (SL) and take profit (TP) levels based on points, rather than price levels. Additionally, it seems to support virtual stop loss and take profit levels, which might be used for internal monitoring rather than actual order levels set on the broker's server. The function returns a boolean value indicating success or failure and also provides a message and a `Trade` object as output parameters.
// 
// Here's a breakdown of the parameters:
// 
// - `double volume`: The amount of lots to trade.
// - `double price`: The entry price for the trade.
// - `ENUM_ORDER_TYPE orderType`: The type of order to place (e.g., `ORDER_TYPE_BUY` or `ORDER_TYPE_SELL`).
// - `int slPoints`: The number of points away from the entry price to set the stop loss.
// - `int tpPoints`: The number of points away from the entry price to set the take profit.
// - `string &message`: A reference to a string variable that will be used to store any message generated by the function (e.g., error messages).
// - `Trade &newTrade`: A reference to a `Trade` object that will be used to store information about the new trade if it is successfully opened.
// - `int virtualSLPoints`: The number of points away from the entry price to set a virtual stop loss (not sent to the broker).
// - `int virtualTPPoints`: The number of points away from the entry price to set a virtual take profit (not sent to the broker).
// - `string comment`: A comment to attach to the trade for identification or other purposes.
// 
// Here's an example of how the function might be implemented in MQL5, assuming that `Trade` is a custom class:
// 

//bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string &message, Trade &newTrade, int virtualSLPoints, int virtualTPPoints, string comment) {
    // Calculate the actual price levels for SL and TP based on the entry price and points
//    double slPrice = (orderType == ORDER_TYPE_BUY) ? price - slPoints * _Point : price + slPoints * _Point;
//    double tpPrice = (orderType == ORDER_TYPE_BUY) ? price + tpPoints * _Point : price - tpPoints * _Point;

    // Open the trade using the MQL5 OrderSend function or similar
    // ...

    // Check for errors and set the message accordingly
    // ...

    // If the trade is opened successfully, set the newTrade object's properties
    // ...

    // Return true if the trade was opened successfully, false otherwise
    //return tradeOpenedSuccessfully;
//}

// 
// Please note that this is a hypothetical implementation. The actual implementation would depend on the details of the `Trade` class and the specific requirements of the trading strategy. Additionally, error checking and handling would be necessary to ensure that the function behaves correctly in all scenarios.
// 

    bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string &message, Trade &newTrade, double virtualSLPrice, double virtualTPPrice, string comment);
    void SetBasketSlPrice(double slPrice);
    void SwitchTradeToVirtualSLTP(ulong ticket);
    void SetTradeToVirtualSLTP(ulong ticket, double slPrice, double tpPrice);
    bool GetTradeByIndex(int index, Trade &trade);
    bool RemoveTradeByIndex(int index);
    void CloseBasketOrders();
    bool UpdateSLTP(int recoverySLPoints, double tpPrice);
    void CloseFirstOrder();
    void ClosePartial(double ratioToClose);
    double CTradingBasket::TotalCommission() { return 0; /*return totalCommission; */ }
    double TotalSwap();
    void OnTick();

private:
    void CheckPnL();
    void UpdateAvgTpForBasketTrades();
    void UpdateVirtualSlForBasketTrades();
    void UpdateCurrentTrades();
};

CTradingBasket::CTradingBasket(string symbol, long magicNumber, CReporter *reporter, CConstants *constants)
{
    pSymbol = symbol;
    _magicNumber = magicNumber;
    _reporter = reporter;
    _constants = constants;
    _basketStatus = BASKET_CLOSED;
    ArrayResize(_trades, 0);
}

CTradingBasket::~CTradingBasket()
{
    ArrayFree(_trades);
}

void CTradingBasket::SetBasketAvgTpPrice(double tpPrice)
{
    basketAvgTpPrice = tpPrice;
    CTradingBasket::UpdateAvgTpForBasketTrades();
}

void CTradingBasket::SetBasketSlPrice(double slPrice)
{
    if (IsEmpty())
        return;

    CPositionInfo _position;
    CTrade _trade;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, slPrice, _position.TakeProfit());
        }
    }
}

void CTradingBasket::SetTradeToVirtualSLTP(ulong ticket, double slPrice, double tpPrice)
{
    CPositionInfo _position;
    CTrade _trade;
    for (int i = Count() - 1; i >= 0; i--)
    {
        if (_trades[i].Ticket() != ticket)
            continue;

        _trades[i].SwitchToVirtualSLTP(slPrice, tpPrice);
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, 0, 0);
        }
    }
}

void CTradingBasket::CloseFirstOrder()
{
    CPositionInfo _position;
    CTrade _trade;
    if (ArraySize(_trades) > 0)
    {
        ulong ticket = _trades[0].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            double commission = _position.Commission();
            if (_trade.PositionClose(ticket, ULONG_MAX))
            {
                totalCommission -= commission;
                ArrayRemove(_trades, 0, 1);
                // Do we need to update profit?
            }
            else
            {
                _reporter.ReportError("Failed to close first order of the basket");
            }
        }
        else
        {
            _reporter.ReportError("Failed to close first order of the basket");
        }
    }
}

void CTradingBasket::ClosePartial(double ratioToClose)
{
    if (ratioToClose <= 0 || ratioToClose >= 1)
    {
        Print("Invalid ratio provided. Should be between 0 and 1.");
        return;
    }

    CTrade _trade;
    CPositionInfo _position;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            double currentVolume = _position.Volume();
            double volumeToClose = currentVolume * ratioToClose;
            double totalCommissionForPosition = _position.Commission();
            double commissionClosedPortion = totalCommissionForPosition * (volumeToClose / currentVolume);

            if (_trade.PositionClosePartial(ticket, volumeToClose, ULONG_MAX))
            {
                totalCommission -= commissionClosedPortion;
                ArrayRemove(_trades, i, 1);
            }
            else
            {
                PrintFormat("Failed to close position %d", ticket);
            }
        }
    }
}

double CTradingBasket::TotalSwap()
{
return 0;
    double totalSwap = 0.0;
    CPositionInfo _position;
    for (int i = 0; i < Count(); i++)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            totalSwap += _position.Swap();
        }
    }
    return totalSwap;
}
bool CTradingBasket::UpdateSLTP(int recoverySLPoints, double tpPrice)
{
    CTrade _trade;
    CPositionInfo _position;
    double avgOpenPrice = AverageOpenPrice();
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            double slPrice = 0;
            if (_position.PositionType() == POSITION_TYPE_BUY)
            {
                slPrice = recoverySLPoints == 0 ? 0 : avgOpenPrice - (recoverySLPoints * SymbolInfoDouble(pSymbol, SYMBOL_POINT));
            }
            else if (_position.PositionType() == POSITION_TYPE_SELL)
            {
                slPrice = recoverySLPoints == 0 ? 0 : avgOpenPrice + (recoverySLPoints * SymbolInfoDouble(pSymbol, SYMBOL_POINT));
            }

            if (!_trade.PositionModify(ticket, slPrice, tpPrice))
            {
                return (false);
            }
        }
    }

    return (true);
}

bool CTradingBasket::GetTradeByIndex(int index, Trade &trade)
{
    if (index > Count() || index < 0)
        return (false);
    trade = _trades[index];
    return (true);
}

bool CTradingBasket::RemoveTradeByIndex(int index)
{
    if (index > Count() || index < 0)
        return (false);
    ArrayRemove(_trades, index, 1);
    return (true);
}
void CTradingBasket::SwitchTradeToVirtualSLTP(ulong ticket)
{
    if (IsEmpty())
        return;

    CPositionInfo _position;
    CTrade _trade;
    for (int i = Count() - 1; i >= 0; i--)
    {
        if (_trades[i].Ticket() != ticket)
        {
            continue;
        }
        Trade trade = _trades[i];
        trade.SwitchToVirtualSLTP();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, trade.StopLoss(), trade.TakeProfit());
        }
    }
}

bool CTradingBasket::OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string &message, Trade &newTrade, int virtualSLPoints, int virtualTPPoints, string comment)
{
    double slPrice = 0, tpPrice = 0;
    double ask = SymbolInfoDouble(pSymbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(pSymbol, SYMBOL_BID);
    double spread = ask - bid;
    int spread_points = (int)MathRound(spread / _constants.Point(pSymbol));
    if (slPoints <= spread_points)
    {
        message = "SL points is less than the spread points";
        return (false);
    }

    if (orderType == ORDER_TYPE_BUY)
    {
        slPrice = slPoints > 0 ? price - (slPoints * _constants.Point(pSymbol)) : 0;
        tpPrice = tpPoints > 0 ? price + (tpPoints * _constants.Point(pSymbol)) : 0;
    }
    else
    {
        slPrice = slPoints > 0 ? price + (slPoints * _constants.Point(pSymbol)) : 0;
        tpPrice = tpPoints > 0 ? price - (tpPoints * _constants.Point(pSymbol)) : 0;
    }

    return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, message, newTrade, virtualSLPoints, virtualTPPoints, comment);
}

bool CTradingBasket::OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice,
                                        string &message, Trade &newTrade, double virtualSLPrice, double virtualTPPrice, string comment)
{
    if (Count() == 0)
    {
        firstOrderVolume = volume;
    }

    if (_basketStatus == BASKET_CLOSING)
    {
        // TODO: error reporting
        message = StringFormat("Basket is %s, cannot receive orders now", EnumToString(_basketStatus));
        return (false);
    }

    MqlTradeResult result;
    CTrade _trade;
    CDealInfo _deal;
    _trade.SetExpertMagicNumber((int)_magicNumber);
    _trade.PositionOpen(pSymbol, orderType, volume, price, slPrice, tpPrice, comment);
    _trade.Result(result);

    if (result.retcode > 0)
    {
        Trade trade;
        trade.Init(result.order, _trade.RequestMagic(), _trade.RequestSymbol(), orderType,
                   result.price, result.volume, 0, _trade.RequestSL(), _trade.RequestTP(),
                   virtualSLPrice, virtualTPPrice, result.comment);

        ArrayResize(_trades, ArraySize(_trades) + 1);
        _trades[ArraySize(_trades) - 1] = trade;
        newTrade = trade;
        _basketStatus = BASKET_OPEN;
        lastOrderCount++;
        totalCommission += _deal.Commission();
    }
    else
    {
        // TODO
        message = StringFormat("Order failed: %s", result.retcode);
        return (false);
    }

    return (true);
}

double CTradingBasket::Volume()
{
    double totalVolume = 0.0;
    for (int i = 0; i < ArraySize(_trades); i++)
    {
        totalVolume += _trades[i].Volume();
    }
    return totalVolume;
}

double CTradingBasket::Volume(ENUM_ORDER_TYPE orderType)
{
    double totalVolume = 0.0;
    for (int i = 0; i < ArraySize(_trades); i++)
    {
        if (_trades[i].OrderType() == orderType)
            totalVolume += _trades[i].Volume();
    }
    return totalVolume;
}

double CTradingBasket::AverageOpenPrice()
{
    double totalPrice = 0.0;
    double totalVolume = 0.0;
    for (int i = 0; i < Count(); i++)
    {
        totalVolume += _trades[i].Volume();
        totalPrice += _trades[i].OpenPrice() * _trades[i].Volume();
    }

    if (IsEmpty() || totalVolume == 0)
        return 0;
    double avgPrice = totalPrice / totalVolume;
    return avgPrice;
}

int CTradingBasket::Count() { return ArraySize(_trades); }
string CTradingBasket::Symbol() { return pSymbol; }
bool CTradingBasket::HasOpenedTrades() { return Count() > 0; }
bool CTradingBasket::IsEmpty() { return Count() == 0; }
ENUM_BASKET_STATUS CTradingBasket::Status() { return _basketStatus; }

bool CTradingBasket::FirstTrade(Trade &trade)
{
    if (Count() > 0)
    {
        trade = _trades[0];
        return (true);
    }
    return (false);
}

bool CTradingBasket::LastTrade(Trade &trade)
{
    if (Count() > 0)
    {
        trade = _trades[Count() - 1];
        return (true);
    }
    return (false);
}

void CTradingBasket::CloseBasketOrders()
{
    CTrade _trade;
    CPositionInfo _position;
    _basketStatus = BASKET_CLOSING;
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            double commission = _position.Commission();
            if (_trade.PositionClose(ticket, ULONG_MAX))
            {
                totalCommission -= commission;
                ArrayRemove(_trades, i, 1);
            }
            else
            {
                PrintFormat("Failed to close position %d", ticket);
            }
        }
    }

    if (IsEmpty())
    {
        _basketStatus = BASKET_CLOSED;
        profit = 0;
        totalCommission = 0;
    }
}

void CTradingBasket::UpdateCurrentTrades()
{
    CPositionInfo _position;
    profit = 0;
    // Cleanup the basket
    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (!_position.SelectByTicket(ticket))
        {
            ArrayRemove(_trades, i, 1);
        }
        else
        {
            profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
    }

    if (ArraySize(_trades) == 0)
    {
        _basketStatus = BASKET_CLOSED;
        lastOrderCount = 0;
    }
}

void CTradingBasket::OnTick()
{
    if (_basketStatus == BASKET_CLOSING)
    {
        CTradingBasket::CloseBasketOrders();
    }

    CTradingBasket::UpdateCurrentTrades();
}

/**********************************************/

void CTradingBasket::UpdateAvgTpForBasketTrades()
{
    if (IsEmpty())
        return;
    CPositionInfo _position;
    CTrade _trade;

    for (int i = Count() - 1; i >= 0; i--)
    {
        ulong ticket = _trades[i].Ticket();
        if (_position.SelectByTicket(ticket))
        {
            _trade.PositionModify(ticket, _position.StopLoss(), basketAvgTpPrice);
        }
    }
}

void CTradingBasket::UpdateVirtualSlForBasketTrades()
{
    if (IsEmpty())
        return;
}