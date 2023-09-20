#include <Object.mqh>
#include "Common.mqh"
#include "Trade\TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";
#include "RiskManagement\NormalLotSizeCalculator.mqh";
#include "Trade\RecoveryManager.mqh"
#include "Trade\NormalTradingManager.mqh";
#include "Trade\TradingStatus.mqh";
#include "UI\Reporter.mqh";
#include "Enums.mqh"

#include "Signals\BandsSignal.mqh"
#include "Signals\ZigZagSignal.mqh"
#include "Signals\SignalManager.mqh"
#include "Filters\FilterManager.mqh"
#include "Filters\AtrFilter.mqh"
#include "Filters\SpreadFilter.mqh"
#include "Filters\PnLFilter.mqh"

class CSymbolExpert : public CObject
{

private:
    CConstants *_constants;
    CPnLManager *_pnlManager;
    CTradingStatusManager *_tradingStatusManager;

    CTradingBasket *_buyBasket;
    CTradingBasket *_sellBasket;

    CNormalLotSizeCalculator *_normalLotCalc;
    CLotSizeCalculator *_lotCalc;
    CTradingManager *buyRecovery;
    CTradingManager *sellRecovery;
    CSignalManager *_buySignalManager;
    CSignalManager *_sellSignalManager;
    CFilterManager *_filterManager;
    int _maxSpread;
    int _defaultSLPoints;
    int _defaultTPPoints;

    RecoveryOptions _recoveryOptions;
    RiskOptions _riskOptions;
    PnLOptions _pnlOptions;

protected:
    CReporter *_reporter;
    string pSymbol;

public:
    CSymbolExpert(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
                  RecoveryOptions &options, RiskOptions &riskOptions, PnLOptions &PnLOptions);
    ~CSymbolExpert();

public:
    virtual void RegisterFilters(CFilterManager *filterManager) = 0;
    virtual void RegisterBuySignals(CSignalManager *signalManager) = 0;
    virtual void RegisterSellSignals(CSignalManager *signalManager) = 0;

    int OnInit();
    bool ValidateInputs();
    void OnTick();
};

CSymbolExpert::CSymbolExpert(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
                             RecoveryOptions &options, RiskOptions &riskOptions, PnLOptions &pnLOptions)
{
    pSymbol = symbol;
    _maxSpread = maxSpread;
    _defaultSLPoints = defaultSLPoints;
    _defaultTPPoints = defaultTPPoints;
    _recoveryOptions = options;
    _riskOptions = riskOptions;
    _pnlOptions = pnLOptions;
}

int CSymbolExpert::OnInit()
{
    _reporter = new CReporter();
    _constants = new CConstants();
    _pnlManager = new CPnLManager(_pnlOptions);
    _tradingStatusManager = new CTradingStatusManager();

    _filterManager = new CFilterManager();
    RegisterFilters(_filterManager);

    _buySignalManager = new CSignalManager();
    RegisterBuySignals(_buySignalManager);

    _sellSignalManager = new CSignalManager();
    RegisterSellSignals(_sellSignalManager);

    _buyBasket = new CTradingBasket(pSymbol, 14324, _reporter, _pnlManager);
    _sellBasket = new CTradingBasket(pSymbol, 45332, _reporter, _pnlManager);

    _normalLotCalc = new CNormalLotSizeCalculator(_riskOptions.riskType, _riskOptions.fixedLot, _riskOptions.riskSource, _riskOptions.riskPercentage,
                                                  _riskOptions.xBalance, _riskOptions.lotPerXBalance);

    _lotCalc = new CRecoveryLotSizeCalculator(_normalLotCalc, _recoveryOptions.lotMode, _recoveryOptions.fixedLot, _recoveryOptions.gridLotSeries,
                                              _recoveryOptions.lotMultiplier, _recoveryOptions.lotCustomMode);

    buyRecovery = new CRecoveryManager(_buyBasket, _reporter, _buySignalManager, _normalLotCalc, _lotCalc, _tradingStatusManager, _recoveryOptions);
    sellRecovery = new CRecoveryManager(_sellBasket, _reporter, _sellSignalManager, _normalLotCalc, _lotCalc, _tradingStatusManager, _recoveryOptions);

    if (!ValidateInputs())
    {
        return (INIT_PARAMETERS_INCORRECT);
    }

    return INIT_SUCCEEDED;
}

bool CSymbolExpert::ValidateInputs()
{
    bool isValid = true;
    if (_defaultSLPoints <= 0)
    {
        isValid = false;
        _reporter.ReportError("Default SL Points must be greater than 0");
    }
    if (_defaultTPPoints <= 0)
    {
        isValid = false;
        _reporter.ReportError("Default TP Points must be greater than 0");
    }

    if (_recoveryOptions.recoverySLPoints < 0)
    {
        isValid = false;
        _reporter.ReportError("Max Loss Points must be greater than or equal to 0");
    }

    isValid &= _filterManager.ValidateFilters();
    isValid &= _buySignalManager.ValidateSignals();
    isValid &= _sellSignalManager.ValidateSignals();

    return isValid;
}

void CSymbolExpert::OnTick()
{
    buyRecovery.OnTick();
    sellRecovery.OnTick();

    double ask = SymbolInfoDouble(pSymbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(pSymbol, SYMBOL_BID);
    bool sellSignal = _sellSignalManager.GetSignalWithAnd(SIGNAL_SELL);
    bool buySignal = _buySignalManager.GetSignalWithAnd(SIGNAL_BUY);

    if ((!buySignal && !sellSignal) || !_filterManager.AllAgree())
    {
        return;
    }

    int slPoints = _defaultSLPoints;
    int tpPoints = _defaultTPPoints;

    if (buySignal && _buyBasket.IsEmpty())
    {
        ENUM_ORDER_TYPE direction = ORDER_TYPE_BUY;
        double price = ask;

        double slPrice = price + (slPoints * _Point);
        double lots = _lotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
        string message;
        Trade trade;
        if (!buyRecovery.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test buy"))
        {
            PrintFormat("Failed to open sell trade: %s", message);
        }
    }

    if (sellSignal && _sellBasket.IsEmpty())
    {
        ENUM_ORDER_TYPE direction = ORDER_TYPE_SELL;
        double price = bid;

        double slPrice = price + (slPoints * _Point);
        double lots = _lotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
        string message;
        Trade trade;
        if (!sellRecovery.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test sell"))
        {
            PrintFormat("Failed to open sell trade: %s", message);
        }
    }
}

void CSymbolExpert::~CSymbolExpert()
{
    SafeDeletePointer(_constants);
    SafeDeletePointer(_buyBasket);
    SafeDeletePointer(_sellBasket);
    SafeDeletePointer(_reporter);
    SafeDeletePointer(_normalLotCalc);
    SafeDeletePointer(_lotCalc);
    SafeDeletePointer(buyRecovery);
    SafeDeletePointer(sellRecovery);
    SafeDeletePointer(_buySignalManager);
    SafeDeletePointer(_sellSignalManager);
    SafeDeletePointer(_filterManager);
}

class FirstEA : public CSymbolExpert
{

public:
    FirstEA(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
            RecoveryOptions &options, RiskOptions &riskOptions, PnLOptions &pnLOptions)
        : CSymbolExpert(symbol, maxSpread, defaultSLPoints, defaultTPPoints, options, riskOptions, pnLOptions) {}

protected:
    void RegisterFilters(CFilterManager *filterManager)
    {
    }

    void RegisterBuySignals(CSignalManager *signalManager)
    {
        signalManager.RegisterSignal(new CBandsSignal(pSymbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, false));
    }

    void RegisterSellSignals(CSignalManager *signalManager)
    {
        signalManager.RegisterSignal(new CBandsSignal(pSymbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, false));
    }
};