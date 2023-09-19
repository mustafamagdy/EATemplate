#include <Object.mqh>
#include "Common.mqh"
#include "Trade\TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";
#include "RiskManagement\NormalLotSizeCalculator.mqh";
#include "Trade\RecoveryManager.mqh"
#include "Trade\NormalTradingManager.mqh";
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

protected:
    bool _onInitCalled;

private:
    CConstants *_constants;
    CTradingBasket *_buyBasket;
    CTradingBasket *_sellBasket;
    
    CNormalLotSizeCalculator *_normalLotCalc;
    CLotSizeCalculator *_lotCalc;
    CTradingManager *buyRecovery;
    CTradingManager *sellRecovery;
    CSignalManager *_buySignalManager;
    CSignalManager *_sellSignalManager;
    CFilterManager *_filterManager;
    CFilterManager *_entryFiltersForBuys;
    CFilterManager *_exitFiltersForBuys;
    CFilterManager *_entryFiltersForSells;
    CFilterManager *_exitFiltersForSells;
    int _maxSpread;
    int _defaultSLPoints;
    int _defaultTPPoints;
    
    RecoveryOptions _recoveryOptions;
    RiskOptions _riskOptions;

protected:
   CReporter *_reporter;
   string _symbol;   
public:
    CSymbolExpert(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints, RecoveryOptions &options, RiskOptions &riskOptions);
    ~CSymbolExpert();

public:
    virtual void RegisterFilters(CFilterManager &filterManager) = NULL;
    virtual void RegisterBuySignals(CSignalManager &signalManager) = NULL;
    virtual void RegisterSellSignals(CSignalManager &signalManager) = NULL;
    virtual void RegisterEntryFiltersForBuys(CFilterManager &entryFilters) = NULL;
    virtual void RegisterEntryFiltersForSells(CFilterManager &entryFilters) = NULL;
    virtual void RegisterExitFiltersForBuys(CFilterManager &entryFilters) = NULL;
    virtual void RegisterExitFiltersForSells(CFilterManager &entryFilters) = NULL;
    int OnInit();
    bool ValidateInputs();
    void OnTick();
};

CSymbolExpert::CSymbolExpert(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints, RecoveryOptions &options, RiskOptions &riskOptions)
{
   _onInitCalled = false;
    _symbol = symbol;
    _maxSpread = maxSpread;
    _defaultSLPoints = defaultSLPoints;
    _defaultTPPoints = defaultTPPoints;
    _recoveryOptions = options;
    _riskOptions = riskOptions;
}

int CSymbolExpert::OnInit()
{
    _reporter = new CReporter();
    _constants = new CConstants();

    _filterManager = new CFilterManager();        
    RegisterFilters(_filterManager);

    _buySignalManager = new CSignalManager();
    RegisterBuySignals(_buySignalManager);
    
    _sellSignalManager = new CSignalManager();
    RegisterSellSignals(_sellSignalManager);   

    _buyBasket = new CTradingBasket(_symbol, 14324);
    _sellBasket = new CTradingBasket(_symbol, 45332);

    // Entry filters
    _entryFiltersForBuys = new CFilterManager();
    _entryFiltersForBuys.RegisterSignal(new CSpreadFilter(_symbol, _maxSpread));
    RegisterEntryFiltersForBuys(_entryFiltersForBuys);
    
    _entryFiltersForSells = new CFilterManager();
    _entryFiltersForSells.RegisterSignal(new CSpreadFilter(_symbol, _maxSpread));
    RegisterEntryFiltersForSells(_entryFiltersForSells);
   
    // Exit filters
    _exitFiltersForBuys = new CFilterManager();
    RegisterExitFiltersForBuys(_exitFiltersForBuys);
    _exitFiltersForSells = new CFilterManager();
    RegisterExitFiltersForSells(_exitFiltersForSells);

    _normalLotCalc = new CNormalLotSizeCalculator(_riskOptions.riskType, _riskOptions.fixedLot, _riskOptions.riskSource, _riskOptions.riskPercentage, 
                                                _riskOptions.xBalance, _riskOptions.lotPerXBalance);    
    _lotCalc = new CRecoveryLotSizeCalculator(_normalLotCalc, _recoveryOptions.lotMode, _recoveryOptions.fixedLot, _recoveryOptions.lotSeries,
                                                _recoveryOptions.lotMultiplier, _recoveryOptions.lotCustomMode);

    buyRecovery = new CRecoveryManager(_buyBasket, _reporter, _buySignalManager, _normalLotCalc, _lotCalc, _recoveryOptions, _entryFiltersForBuys, _exitFiltersForBuys);
    sellRecovery = new CRecoveryManager(_sellBasket, _reporter, _sellSignalManager, _normalLotCalc, _lotCalc, _recoveryOptions, _entryFiltersForSells, _exitFiltersForSells);

    if (!ValidateInputs())
    {
        return (INIT_PARAMETERS_INCORRECT);
    }

    _onInitCalled = true;
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

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
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
        double lots = _lotCalc.CalculateLotSize(_Symbol, price, slPrice, direction);
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
        double lots = _lotCalc.CalculateLotSize(_Symbol, price, slPrice, direction);
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


class FirstEA: public CSymbolExpert 
{

private:
    bool Check() {
        if(!_onInitCalled) {
            _reporter.ReportError("On init has not been called, or it failed during input validation");
            return (false);
        }

        return (true);
    }

public:
    FirstEA(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints, RecoveryOptions &options, RiskOptions &riskOptions)
        :CSymbolExpert(symbol, maxSpread, defaultSLPoints, defaultTPPoints, options, riskOptions) {}
    void RegisterFilters(CFilterManager &filterManager) {
        if(!Check()) return;
    }
    void RegisterBuySignals(CSignalManager &signalManager) {
        if(!Check()) return;
        signalManager.RegisterSignal(new CBandsSignal(_symbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, false));
    }
    void RegisterSellSignals(CSignalManager &signalManager) {
        if(!Check()) return;
        signalManager.RegisterSignal(new CBandsSignal(_symbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, false));
    }
    void RegisterEntryFiltersForBuys(CFilterManager &entryFilters) {
        if(!Check()) return;

    }
    void RegisterEntryFiltersForSells(CFilterManager &entryFilters) {
        if(!Check()) return;

    }
    void RegisterExitFiltersForBuys(CFilterManager &entryFilters) {
        if(!Check()) return;

    }
    void RegisterExitFiltersForSells(CFilterManager &entryFilters) {
        if(!Check()) return;

    }

};