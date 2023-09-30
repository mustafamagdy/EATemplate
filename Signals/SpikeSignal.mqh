#include "SignalBase.mqh"

class CSpikeTraderSignal : public CSignalBase
{
private:
    string _symbol;
    int BarsNumber;
    double PercentageDifference;
    double ThirdOrHalf;

public:
    CSpikeTraderSignal(string symbol, int barsNumber, double percentageDifference, double thirdOrHalf);
    ~CSpikeTraderSignal();
    virtual bool ValidateInputs()
    {
        // TODO
        return true;
    }
    
    virtual ENUM_SIGNAL GetSignal();
    bool CheckSellEntry(MqlRates &rates[]);
    bool CheckBuyEntry(MqlRates &rates[]);
};

CSpikeTraderSignal::CSpikeTraderSignal(string symbol, int barsNumber, double percentageDifference, double thirdOrHalf)
{
    _symbol = symbol;
    BarsNumber = barsNumber;
    PercentageDifference = percentageDifference;
    ThirdOrHalf = thirdOrHalf;
}

CSpikeTraderSignal::~CSpikeTraderSignal()
{
    // Destructor logic if any
}

ENUM_SIGNAL CSpikeTraderSignal::GetSignal()
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(_symbol, _Period, 1, BarsNumber + 1, rates);
    if (copied != BarsNumber + 1)
        Print("Error copying price data ", GetLastError());

    // Check Sell and Buy Entry conditions
    if (CheckSellEntry(rates))
        return SIGNAL_SELL;
    if (CheckBuyEntry(rates))
        return SIGNAL_BUY;

    return SIGNAL_NEUTRAL;
}

bool CSpikeTraderSignal::CheckSellEntry(MqlRates &rates[])
{
    // If the bar isn't higher than at least one of the previous bars - return false.
    for (int i = 1; i < BarsNumber + 1; i++)
        if (rates[0].high <= rates[i].high)
            return false;

    // If not higher than the previous bar by required percentage difference - return false.
    if ((rates[0].high - rates[1].high) / rates[1].high < PercentageDifference)
        return false;

    // If closed above the lower third/half - return false.
    if ((rates[0].close - rates[0].low) / (rates[0].high - rates[0].low) > ThirdOrHalf)
        return false;

    return true;
}

bool CSpikeTraderSignal::CheckBuyEntry(MqlRates &rates[])
{
    // If the bar isn't lower than at least one of the previous bars - return false.
    for (int i = 1; i < BarsNumber + 1; i++)
        if (rates[0].low >= rates[i].low)
            return false;

    // If not lower than the previous bar by required percentage difference - return false.
    if ((rates[1].low - rates[0].low) / rates[1].low < PercentageDifference)
        return false;

    // If closed below the upper third/half - return false.
    if ((rates[0].high - rates[0].close) / (rates[0].high - rates[0].low) > ThirdOrHalf)
        return false;

    return true;
}
