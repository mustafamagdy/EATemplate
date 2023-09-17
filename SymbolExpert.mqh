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

private:
    CConstants *_constants;
    CTradingBasket *_buyBasket;
    CTradingBasket *_sellBasket;
    CReporter *_reporter;
    CNormalLotSizeCalculator *_normalLotCalc;
    CLotSizeCalculator *_lotCalc;
    CTradingManager *buyRecovery;
    CTradingManager *sellRecovery;
    CSignalManager *_buySignalManager;
    CSignalManager *_sellSignalManager;
    CFilterManager *_filterManager;
    CFilterManager *pEntryFiltersForBuys;
    CFilterManager *pExitFiltersForBuys;
    CFilterManager *pEntryFiltersForSells;
    CFilterManager *pExitFiltersForSells;
    int _maxSpread;
    int _defaultSLPoints;
    int _defaultTPPoints;
    string _symbol;
    RecoveryOptions _recoveryOptions;
    RiskOptions _riskOptions;

public:
    CSymbolExpert(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints, RecoveryOptions &options, RiskOptions &riskOptions);
    ~CSymbolExpert();

public:
    int OnInit();
    bool ValidateInputs();
    void OnTick();
};

CSymbolExpert::CSymbolExpert(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints, RecoveryOptions &options, RiskOptions &riskOptions)
{
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
    //_filterManager.RegisterSignal(new CATRFilter(symbol, PERIOD_M5, 5, 0, 100, 0));
    _filterManager.RegisterSignal(new CSpreadFilter(_symbol, _maxSpread));

    _buySignalManager = new CSignalManager();
    _buySignalManager.RegisterSignal(new CBandsSignal(_symbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, true));
    //_buySignalManager.RegisterSignal(new CZigZagSignal(_symbol, PERIOD_M15, 12, 5, 3, false));
    _sellSignalManager = new CSignalManager();
    _sellSignalManager.RegisterSignal(new CBandsSignal(_symbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, true));
    //_sellSignalManager.RegisterSignal(new CZigZagSignal(_symbol, PERIOD_M15, 12, 5, 3, false));

    _buyBasket = new CTradingBasket(_symbol, 14324);
    _sellBasket = new CTradingBasket(_symbol, 45332);

    // Entry filters
    pEntryFiltersForBuys = new CFilterManager();
    pEntryFiltersForBuys.RegisterSignal(new CSpreadFilter(_symbol, _maxSpread));
    // pEntryFiltersForBuys.RegisterSignal(new CPnLFilter(_symbol, _constants, _buyBasket, InpMaxLossType, InpMaxLossValue, InpMaxProfitType, InpMaxProfitValue));
    pEntryFiltersForSells = new CFilterManager();
    pEntryFiltersForSells.RegisterSignal(new CSpreadFilter(_symbol, _maxSpread));
    // pEntryFiltersForSells.RegisterSignal(new CPnLFilter(_symbol, _constants, _sellBasket, InpMaxLossType, InpMaxLossValue, InpMaxProfitType, InpMaxProfitValue));

    // Exit filters
    pExitFiltersForBuys = new CFilterManager();
    pExitFiltersForSells = new CFilterManager();

    _normalLotCalc = new CNormalLotSizeCalculator(_riskOptions.riskType, _riskOptions.fixedLot, _riskOptions.riskSource, _riskOptions.riskPercentage, _riskOptions.xBalance, _riskOptions.lotPerXBalance);
    //_normalLotCalc = new CNormalLotSizeCalculator(RISK_TYPE_FIXED_LOT, 0.02, RISK_PERCENTAGE_FROM_BALANCE, _riskPercent, 0, 0);
    _lotCalc = new CRecoveryLotSizeCalculator(_normalLotCalc, RECOVERY_LOT_MULTIPLIER, 0, "", _recoveryOptions.lotMultiplier, RECOVERY_LOT_CUSTOM_SERIES);

    buyRecovery = new CRecoveryManager(_buyBasket, _reporter, _buySignalManager, _normalLotCalc, _lotCalc, _recoveryOptions, pEntryFiltersForBuys, pExitFiltersForBuys);
    sellRecovery = new CRecoveryManager(_sellBasket, _reporter, _sellSignalManager, _normalLotCalc, _lotCalc, _recoveryOptions, pEntryFiltersForSells, pExitFiltersForSells);

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
