
#include <Object.mqh>

class CConstants : public CObject
{

public:
    static const string Separator() { return ","; }

    static const double AccountEquity() { return AccountInfoDouble(ACCOUNT_EQUITY); }
    static const double AccountFreeMargin() { return AccountInfoDouble(ACCOUNT_MARGIN_FREE); }
    static const int AccountLeverage() { return (int)AccountInfoInteger(ACCOUNT_LEVERAGE); }
#ifdef __MQL5__
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
#else
    double MarginRequired(string symbol)
    {
        double lotSize = 1.0;
        double askPrice = MarketInfo(symbol, MODE_ASK);
        double requiredMargin = MarketInfo(symbol, MODE_MARGINREQUIRED) * lotSize;

        // If the calculation fails or returns an invalid value
        if (requiredMargin <= 0)
        {
            return 0.0;
        }

        return requiredMargin;
    }
#endif
    static const double AccountBalance()
    {
        return AccountInfoDouble(ACCOUNT_BALANCE);
    }

    static const double Point(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_POINT); }
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