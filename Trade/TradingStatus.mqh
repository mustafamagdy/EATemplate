#include <Object.mqh>
#include "..\UI\Reporter.mqh"
#include "..\Common.mqh"

enum ENUM_TRADING_STATUS
{
    TRADING_STATUS_ALLOWED = 0,
    TRADING_STATUS_PAUDED_EXPIRY = 1,
    TRADING_STATUS_PAUSED_RESTART = 2
};

enum ENUM_TRADING_PAUSED_LEVEL
{
    TRADING_PAUSED_BASKET = 0,
    TRADING_PAUSED_SYMBOL = 1,
    TRADING_PAUSED_ACCOUNT = 2,
};

class CTradingStatus : public CObject
{
private:
    ENUM_TRADING_STATUS _tradingStatus;
    ENUM_TRADING_PAUSED_LEVEL _pausedLevel;
    ENUM_ORDER_TYPE _basketType;
    datetime _expiryDateTime;
    string _reason;
    string _symbol;

public:
    ENUM_TRADING_STATUS TradingStatus() const { return _tradingStatus; }
    ENUM_TRADING_PAUSED_LEVEL PausedLevel() const { return _pausedLevel; }
    bool ISBasketType() const { return _basketType != NULL; }
    ENUM_ORDER_TYPE BasketType() const { return _basketType; }
    datetime ExpiryDateTime() const { return _expiryDateTime; }
    string Reason() const { return _reason; }
    string Symbol() const { return _symbol; }

public:
    CTradingStatus() { ResumeTrading(); }
    void PauseTradingUntilExpiry(ENUM_TRADING_PAUSED_LEVEL level, string reason, datetime expiryDateTime, string symbol, ENUM_ORDER_TYPE basketType = NULL);
    void PauseTradingUntilRestart(ENUM_TRADING_PAUSED_LEVEL level, string reason, string symbol, ENUM_ORDER_TYPE basketType = NULL);
    void ResumeTrading();
};

void CTradingStatus::PauseTradingUntilExpiry(ENUM_TRADING_PAUSED_LEVEL level, string reason, datetime expiryDateTime, string symbol, ENUM_ORDER_TYPE basketType = NULL)
{
    _tradingStatus = TRADING_STATUS_PAUDED_EXPIRY;
    _pausedLevel = level;
    _basketType = basketType;
    _expiryDateTime = expiryDateTime;
    _reason = reason;
    _symbol = symbol;
}

void CTradingStatus::PauseTradingUntilRestart(ENUM_TRADING_PAUSED_LEVEL level, string reason, string symbol, ENUM_ORDER_TYPE basketType = NULL)
{
    _tradingStatus = TRADING_STATUS_PAUSED_RESTART;
    _pausedLevel = level;
    _basketType = basketType;
    _reason = reason;
    _symbol = symbol;
    _expiryDateTime = 0;
}

void CTradingStatus::ResumeTrading()
{
    _tradingStatus = TRADING_STATUS_ALLOWED;
    _pausedLevel = TRADING_PAUSED_ACCOUNT;
    _basketType = NULL;
    _reason = "";
    _symbol = "";
    _expiryDateTime = 0;
}

///////////////////////////////////////////////////////
class CTradingStatusManager : public CObject
{
private:
    CReporter *_reporter;
    CTradingStatus _rules[];

private:
    bool FindAccountRule(CTradingStatus &status);
    bool FindSymbolRule(string symbol, CTradingStatus &status);
    bool FindBasketRule(string symbol, ENUM_ORDER_TYPE basketType, CTradingStatus &status);
    void EvaluateRule(CTradingStatus &status, string symbol, datetime time, ENUM_ORDER_TYPE basketType = NULL);

public:
    CTradingStatusManager(CReporter *reproter) {
        ArrayResize(_rules, 0);
        _reporter = reproter;
    }

    void OnTick(string symbol, datetime time, ENUM_ORDER_TYPE basketType = NULL);
    int AddNewRule(CTradingStatus &rule);
    bool IsTradingAllowed(string symbol, datetime time, ENUM_ORDER_TYPE basketType = NULL);
};

int CTradingStatusManager::AddNewRule(CTradingStatus &rule)
{
    if (rule.ISBasketType() && rule.Symbol() == "")
    {
        _reporter.ReportError("Symbol is required for basket type trading rules");
        return ERR_INVALID_PARAMETER;
    }

    switch (rule.TradingStatus())
    {
    case TRADING_STATUS_ALLOWED:
    {
        if (rule.Symbol() != "")
        {
            for (int i = 0; i < ArraySize(_rules); i++)
            {
                if (_rules[i].Symbol() == rule.Symbol() &&
                    (_rules[i].BasketType() == rule.BasketType() || !rule.ISBasketType()))
                {
                    // Found a matching rule, remove it from the array
                    for (int j = i; j < ArraySize(_rules) - 1; j++)
                    {
                        _rules[j] = _rules[j + 1];
                    }
                    ArrayResize(_rules, ArraySize(_rules) - 1);
                    i--; // Adjust loop counter since we removed an element
                }
            }
        }
        else
        {
            // If it's a general rule (not symbol or basket-specific), clear all rules
            ArrayResize(_rules, 0);
        }
        break;
    }
    case TRADING_STATUS_PAUDED_EXPIRY:
    case TRADING_STATUS_PAUSED_RESTART:
    {
        int newSize = ArraySize(_rules) + 1;
        ArrayResize(_rules, newSize);
        _rules[newSize - 1] = rule;
        break;
    }
    }

    return 0;
}

bool CTradingStatusManager::FindAccountRule(CTradingStatus &status)
{
    for (int i = 0; i < ArraySize(_rules); i++)
    {
        if (_rules[i].PausedLevel() == TRADING_PAUSED_ACCOUNT)
        {
            status = _rules[i];
            return (true);
        }
    }
    return (false);
}

bool CTradingStatusManager::FindSymbolRule(string symbol, CTradingStatus &status)
{
    for (int i = 0; i < ArraySize(_rules); i++)
    {
        if (_rules[i].Symbol() != "" && _rules[i].Symbol() == symbol)
        {
            status = _rules[i];
            return (true);
        }
    }
    return (false);
}

bool CTradingStatusManager::FindBasketRule(string symbol, ENUM_ORDER_TYPE basketType, CTradingStatus &status)
{
    for (int i = 0; i < ArraySize(_rules); i++)
    {
        if (_rules[i].Symbol() != "" && _rules[i].Symbol() == symbol && _rules[i].BasketType() == basketType)
        {
            status = _rules[i];
            return (true);
        }
    }
    return (false);
}

void CTradingStatusManager::OnTick(string symbol, datetime time, ENUM_ORDER_TYPE basketType = NULL)
{
    // evaluate the rules from broader to specific
    CTradingStatus accountStatus;
    if (FindAccountRule(accountStatus))
    {
        EvaluateRule(accountStatus, symbol, time, basketType);
    }

    CTradingStatus symbolStatus;
    if (FindSymbolRule(symbol, symbolStatus))
    {
        EvaluateRule(symbolStatus, symbol, time, basketType);
    }

    CTradingStatus basketStatus;
    if (FindBasketRule(symbol, basketType, basketStatus))
    {
        EvaluateRule(basketStatus, symbol, time, basketType);
    }
}

bool CTradingStatusManager::IsTradingAllowed(string symbol, datetime time, ENUM_ORDER_TYPE basketType = NULL)
{
    // Here we evaluate rules from specific to broader
    if (symbol != "" && basketType != NULL)
    {
        // baslet level
        CTradingStatus basketStatus;
        if (FindBasketRule(symbol, basketType, basketStatus))
        {
            bool basketAllowed = basketStatus.TradingStatus() == TRADING_STATUS_ALLOWED;
            if (!basketAllowed && (basketStatus.ExpiryDateTime() == 0 || basketStatus.ExpiryDateTime() > time))
            {
                return false;
            }
        }
    }
    else if (symbol != "")
    {
        // symbol level
        CTradingStatus symbolStatus;
        if (FindSymbolRule(symbol, symbolStatus))
        {
            bool symbolAllowed = symbolStatus.TradingStatus() == TRADING_STATUS_ALLOWED;
            if (!symbolAllowed && (symbolStatus.ExpiryDateTime() == 0 || symbolStatus.ExpiryDateTime() > time))
            {
                return false;
            }
        }
    }
    else
    {
        // account level
        CTradingStatus accountStatus;
        if (FindAccountRule(accountStatus))
        {
            bool accountAllowed = accountStatus.TradingStatus() == TRADING_STATUS_ALLOWED;
            if (!accountAllowed && (accountStatus.ExpiryDateTime() == 0 || accountStatus.ExpiryDateTime() > time))
            {
                return false;
            }
        }
    }

    return true;
}

void CTradingStatusManager::EvaluateRule(CTradingStatus &status, string symbol, datetime time, ENUM_ORDER_TYPE basketType = NULL)
{
    bool allowed = status.TradingStatus() == TRADING_STATUS_ALLOWED;
    if (!allowed && status.ExpiryDateTime() > 0 && status.ExpiryDateTime() < time)
    {
        status.ResumeTrading();
        AddNewRule(status);
    }
}