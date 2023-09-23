#include <Object.mqh>
#include "..\Common.mqh"
#include "..\Enums.mqh"
#include "..\Trade\TradingBasket.mqh"
#include "..\Candles\CandleTypes.mqh"
#include "..\RiskManagement\NormalLotSizeCalculator.mqh"
#include "..\Trade\RecoveryManager.mqh"
#include "..\Trade\NormalTradingManager.mqh"
#include "..\Trade\TradingStatus.mqh"
#include "..\Trade\PnLManager.mqh"
#include "..\UI\Reporter.mqh"

#include "..\Signals\BandsSignal.mqh"
#include "..\Signals\ZigZagSignal.mqh"
#include "..\Signals\MACDSignal.mqh"
#include "..\Signals\SignalManager.mqh"
#include "..\Filters\FilterManager.mqh"
#include "..\Filters\AtrFilter.mqh"
#include "..\Filters\SpreadFilter.mqh"
#include "..\Filters\PnLFilter.mqh"

class CExpertBase : public CObject
{

private:
    CPnLManager *_pnlManager;
    CTradingStatusManager *_tradingStatusManager;

    CSignalManager *_buySignalManager;
    CSignalManager *_sellSignalManager;

    CNormalLotSizeCalculator *_normalLotCalc;
    CFilterManager *_filterManager;
    int _maxSpread;

    RecoveryOptions _recoveryOptions;
    RiskOptions _riskOptions;

protected:
    CConstants *_constants;
    int _defaultSLPoints;
    int _defaultTPPoints;
    CReporter *_reporter;
    CTradingManager *buyRecovery;
    CTradingBasket *_buyBasket;

    CTradingManager *sellRecovery;
    CTradingBasket *_sellBasket;

    CLotSizeCalculator *_lotCalc;

    string pSymbol;

public:
    CExpertBase(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
                RecoveryOptions &options, RiskOptions &riskOptions, CPnLManager *pnlManager, CTradingStatusManager *tradingStatusManager);
    ~CExpertBase();

public:
    virtual void RegisterFilters(CFilterManager *filterManager) = 0;
    virtual void RegisterBuySignals(CSignalManager *signalManager) = 0;
    virtual void RegisterSellSignals(CSignalManager *signalManager) = 0;
    virtual void OnBuySignal() = 0;
    virtual void OnSellSignal() = 0;

    int OnInit();
    bool ValidateInputs();
    void OnTick();
};

CExpertBase::CExpertBase(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
                         RecoveryOptions &options, RiskOptions &riskOptions, CPnLManager *pnlManager, CTradingStatusManager *tradingStatusManager)
{
    pSymbol = symbol;
    _maxSpread = maxSpread;
    _defaultSLPoints = defaultSLPoints;
    _defaultTPPoints = defaultTPPoints;
    _recoveryOptions = options;
    _riskOptions = riskOptions;
    _pnlManager = pnlManager;
    _tradingStatusManager = tradingStatusManager;
}

int CExpertBase::OnInit()
{
    _reporter = new CReporter();
    _constants = new CConstants();

    _filterManager = new CFilterManager();
    RegisterFilters(_filterManager);

    _buySignalManager = new CSignalManager();
    RegisterBuySignals(_buySignalManager);

    _sellSignalManager = new CSignalManager();
    RegisterSellSignals(_sellSignalManager);

    _buyBasket = new CTradingBasket(pSymbol, 14324, _reporter, _constants);
    _sellBasket = new CTradingBasket(pSymbol, 45332, _reporter, _constants);

    _pnlManager.RegisterBasket(_buyBasket);
    _pnlManager.RegisterBasket(_sellBasket);

    _normalLotCalc = new CNormalLotSizeCalculator(_constants, _riskOptions.riskType, _riskOptions.fixedLot, _riskOptions.riskSource, _riskOptions.riskPercentage,
                                                  _riskOptions.xBalance, _riskOptions.lotPerXBalance);

    _lotCalc = new CRecoveryLotSizeCalculator(_constants, _normalLotCalc, _recoveryOptions.lotMode, _recoveryOptions.fixedLot, _recoveryOptions.gridLotSeries,
                                              _recoveryOptions.lotMultiplier, _recoveryOptions.lotCustomMode);

    buyRecovery = new CRecoveryManager(_buyBasket, _constants, _reporter, _buySignalManager, _normalLotCalc, _lotCalc, _tradingStatusManager, _recoveryOptions);
    sellRecovery = new CRecoveryManager(_sellBasket, _constants, _reporter, _sellSignalManager, _normalLotCalc, _lotCalc, _tradingStatusManager, _recoveryOptions);

    if (!ValidateInputs())
    {
        return (INIT_PARAMETERS_INCORRECT);
    }

    return INIT_SUCCEEDED;
}

bool CExpertBase::ValidateInputs()
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

void CExpertBase::OnTick()
{
    buyRecovery.OnTick();
    sellRecovery.OnTick();

    bool sellSignal = _sellSignalManager.GetSignalWithAnd(SIGNAL_SELL);
    bool buySignal = _buySignalManager.GetSignalWithAnd(SIGNAL_BUY);

    if ((!buySignal && !sellSignal) || !_filterManager.AllAgree())
    {
        return;
    }

    if (buySignal)
    {
        OnBuySignal();
    }

    if (sellSignal)
    {
        OnSellSignal();
    }
}

void CExpertBase::~CExpertBase()
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