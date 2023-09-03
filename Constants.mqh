
class CConstants
{

public:
    static const string Separator() { return ";"; }

    static const double AccountEquity() { return AccountInfoDouble(ACCOUNT_EQUITY); }
    static const double AccountFreeMargin() { return AccountInfoDouble(ACCOUNT_MARGIN_FREE); }
    static const int AccountLeverage() { return (int)AccountInfoInteger(ACCOUNT_LEVERAGE); }
    static const double MarginRequired(string symbol)
    {
        double rate = 0;
        ENUM_ORDER_TYPE any = ORDER_TYPE_BUY;
        double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        if (!OrderCalcMargin(any, symbol, 1.0, price, rate))
        {
            return (0.0);
        }

        return (rate);
    }
    static const double AccountBalance() { return AccountInfoDouble(ACCOUNT_BALANCE); }

    static const double MinLot(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN); }
    static const double MaxLot(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX); }
    static const double LotStep(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP); }
    static const double Ask(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_ASK); }
    static const double Bid(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_BID); }

    static const bool IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT)
    {
        datetime currentTime = iTime(symbol, timeframe, 0);
        static datetime previousTime = 0;
        if (currentTime == previousTime)
            return false;
        previousTime = currentTime;
        return true;
    }
};