#include "Trade\TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";
#include "RiskManagement\NormalLotSizeCalculator.mqh";
#include "Trade\RecoveryManager.mqh"
#include "Trade\NormalTradingManager.mqh";
#include "UI\Reporter.mqh";
#include "UI\EADialog.mqh"

#include "Signals\BandsSignal.mqh"
#include "Signals\SignalManager.mqh"
#include "Filters\FilterManager.mqh"
#include "Filters\AtrFilter.mqh"

CEADialog ExtDialog;

CConstants *_constants;
CTradingBasket *_basket1;
CReporter *_reporter;
CNormalLotSizeCalculator *_normalLotCalc;
CLotSizeCalculator *_lotCalc;
CTradingManager *manager;
CSignalManager *_signalManager;
CFilterManager *_filterManager;

int m_maxRecoveryOrderCount = 100;
int m_recoveryTpPoints = 100;
int m_gridFixedSize = 200;
double _riskPercent = 0.05;

datetime targetTime;

int OnInit()
{
    string symbol = _Symbol;

    _constants = new CConstants();
    _filterManager = new CFilterManager();
    _filterManager.RegisterSignal(new CATRFilter(symbol, PERIOD_M5, 5, 0, 100, 0));

    _signalManager = new CSignalManager();
    _signalManager.RegisterSignal(new CBandsSignal(symbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE));

    if (!ExtDialog.Create(0, "Controls", 0, 20, 20, 320, 310))
        return (INIT_FAILED);

    _basket1 = new CTradingBasket(symbol, 14324);
    _reporter = new CReporter();

    _normalLotCalc = new CNormalLotSizeCalculator(RISK_TYPE_PERCENTAGE, 0, RISK_PERCENTAGE_FROM_BALANCE, _riskPercent, 0, 0);
    _lotCalc = new CRecoveryLotSizeCalculator(_normalLotCalc, RECOVERY_LOT_MULTIPLIER, 0.1, "", 1.5, RECOVERY_LOT_CUSTOM_SERIES);
    RecoveryOptions options;
    options.gridFixedSize = 200;
    options.gridSizeMode = GRID_SIZE_ATR;

    options.gridATRMin = 0;
    options.gridATRMax = 0;
    options.gridATRPeriod = 20;
    options.gridATRTimeframe = PERIOD_H1;
    options.gridATRValueAction = ATR_ACTION_NONE;

    options.gridTradeOnlyBySignal = false;
    options.gridTradeOnlyNewBar = true;
    options.maxGridOrderCount = 20;
    options.newBarTimeframe = PERIOD_H1;
    options.recoveryMode = RECOVERY_MARTINGALE;
    options.showTpLine = true;
    options.useVirtualSLTP = true;
    options.recoveryTpPoints = 150;

    manager = new CRecoveryManager(_basket1, _reporter, _signalManager, _normalLotCalc, _lotCalc, options);

    // manager = new CNormalTradingManager(_basket1, _reporter);

    targetTime = TimeCurrent();
    int hours = 13; // 24-hour format
    int minutes = 25;

    // Convert hours and minutes to seconds and add them to targetTime.
    targetTime += hours * 3600 + minutes * 60;
    return INIT_SUCCEEDED;
}

void OnTick()
{
    manager.OnTick();

    // if (_constants.IsNewBar(_Symbol, PERIOD_CURRENT) && TimeCurrent() > targetTime && _basket1.IsEmpty())
    //{
    if (!_basket1.IsEmpty())
    {
        return;
    }

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool buySignal = _signalManager.GetSignalWithAnd(SIGNAL_BUY);
    bool sellSignal = _signalManager.GetSignalWithAnd(SIGNAL_SELL);

    if ((!buySignal && !sellSignal) || !_filterManager.CanTradeWithAnd())
    {
        return;
    }

    ENUM_ORDER_TYPE direction = buySignal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    double price = direction == ORDER_TYPE_BUY ? ask : bid;

    int slPoints = 200;
    int tpPoints = 200;

    double slPrice = price + (((direction == ORDER_TYPE_BUY ? 1 : -1) * slPoints) * _Point);
    double lots = _lotCalc.CalculateLotSize(_Symbol, price, slPrice, direction);
    string message;
    Trade trade;
    if (!manager.OpenTradeWithPoints(lots, price, direction, slPoints, tpPoints, "test sell", message, trade))
    {
        PrintFormat("Failed to open sell trade: %s", message);
    }
    //}

    string comment = "";
    comment += StringFormat("%d orders (buy basket), total volume= %.2f, avg price= %f", _basket1.Count(), _basket1.Volume(), _basket1.AverageOpenPrice());
    Comment(comment);
}

void OnDeinit(const int reason)
{
    //--- destroy dialog
    ExtDialog.Destroy(reason);

    delete _constants;
    delete _basket1;
    delete _reporter;
    delete _normalLotCalc;
    delete _lotCalc;
    delete manager;
    delete _signalManager;
    delete _filterManager;
    ;
}

void OnChartEvent(const int id,         // event ID
                  const long &lparam,   // event parameter of the long type
                  const double &dparam, // event parameter of the double type
                  const string &sparam) // event parameter of the string type
{
    ExtDialog.ChartEvent(id, lparam, dparam, sparam);
}