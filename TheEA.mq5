#include "Trade\TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";
#include "RiskManagement\NormalLotSizeCalculator.mqh";
#include "Trade\RecoveryManager.mqh"
#include "Trade\NormalTradingManager.mqh";
#include "UI\Reporter.mqh";
#include "UI\EADialog.mqh"
#include "Enums.mqh"

#include "Signals\BandsSignal.mqh"
#include "Signals\ZigZagSignal.mqh"
#include "Signals\SignalManager.mqh"
#include "Filters\FilterManager.mqh"
#include "Filters\AtrFilter.mqh"
#include "Filters\SpreadFilter.mqh"

CEADialog ExtDialog;

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

input static string _g_main;                                   // ==== Main Settings ====
input double InpXBalance = 25000;                              // xBalance
input double InpLotForXBalance = 0.01;                         // Lot per xBalance
input double InpLotMultiplier = 1.68;                          // Grid Multiplier
input int InpGridFixedGap = 500;                               // Fixed Grid Gap (Points)
input ENUM_BASKET_MAX_SLTP_MODE InpMaxSLMode;                  // Basket SL Mode
input int InpMaxLossPoints = 0;                                // Max Average SL (Points, 0=Disabled)
input static string _g_pnl;                                    // ==== PnL Settings ====
input ENUM_BASKET_PNL_TYPE InpPnlType;                         // PnL Type
input double InpPnlValue = 0;                                  // PnL Value (Currency/Percentage, 0=Disabled)
input ENUM_BASKET_PNL_RESET_MODE InpPnlReset = RESET_24_HOURS; // PnL Reset After
input static string _g_filters;                                // ==== Filter Settings ====
input int InpMaxSpread = 100;                                  // Max Spread (Points, 0=Disabled)
input static string _g_ui;                                     // ==== UI Settings ====
input static bool InpShowUI = false;                           // Show UI

datetime targetTime;

int OnInit()
{
    string symbol = _Symbol;

    _constants = new CConstants();
    _filterManager = new CFilterManager();
    //_filterManager.RegisterSignal(new CATRFilter(symbol, PERIOD_M5, 5, 0, 100, 0));
    _filterManager.RegisterSignal(new CSpreadFilter(symbol, InpMaxSpread));

    _buySignalManager = new CSignalManager();
    _buySignalManager.RegisterSignal(new CBandsSignal(symbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, true));
    //_buySignalManager.RegisterSignal(new CZigZagSignal(symbol, PERIOD_M15, 12, 5, 3, false));
    _sellSignalManager = new CSignalManager();
    _sellSignalManager.RegisterSignal(new CBandsSignal(symbol, PERIOD_M5, 20, 2.680, PRICE_CLOSE, true));
    //_sellSignalManager.RegisterSignal(new CZigZagSignal(symbol, PERIOD_M15, 12, 5, 3, false));

    if (InpShowUI)
    {
        if (!ExtDialog.Create(0, "Controls", 0, 20, 20, 320, 310))
            return (INIT_FAILED);
    }

    _buyBasket = new CTradingBasket(symbol, 14324);
    _sellBasket = new CTradingBasket(symbol, 45332);
    _reporter = new CReporter();

    _normalLotCalc = new CNormalLotSizeCalculator(RISK_TYPE_PER_XBALANCE, 0, RISK_PERCENTAGE_FROM_BALANCE, 0, InpXBalance, InpLotForXBalance);
    //_normalLotCalc = new CNormalLotSizeCalculator(RISK_TYPE_FIXED_LOT, 0.02, RISK_PERCENTAGE_FROM_BALANCE, _riskPercent, 0, 0);
    _lotCalc = new CRecoveryLotSizeCalculator(_normalLotCalc, RECOVERY_LOT_MULTIPLIER, 0, "", InpLotMultiplier, RECOVERY_LOT_CUSTOM_SERIES);
    RecoveryOptions options;
    options.gridFixedSize = InpGridFixedGap;
    options.gridSizeMode = GRID_SIZE_ATR;
    options.gridFixedSize = 1350;

    options.gridATRMin = 1450;
    options.gridATRMax = 0;
    options.gridATRPeriod = 5;
    options.gridATRTimeframe = PERIOD_H1;
    options.gridATRValueAction = ATR_ACTION_MULTIPLY;
    options.gridATRActionValue = 2;

    options.gridTradeOnlyBySignal = false;
    options.gridTradeOnlyNewBar = false;
    options.maxGridOrderCount = 13;
    options.basketMaxOrderBehaviour = MAX_ORDER_CLOSE_FIRST_ORDER;
    options.maxGridLots = 50;
    options.newBarTimeframe = PERIOD_M5;
    options.recoveryMode = RECOVERY_MARTINGALE;
    options.showTpLine = true;
    options.showSLLine = true;
    options.useVirtualSLTP = true;
    options.recoveryTpPoints = 100;
    options.recoverySLPoints = InpMaxLossPoints;
    options.basketSLMode = MAX_SL_MODE_GAP_FROM_FIRST;

    buyRecovery = new CRecoveryManager(_buyBasket, _reporter, _buySignalManager, _normalLotCalc, _lotCalc, options);
    sellRecovery = new CRecoveryManager(_sellBasket, _reporter, _sellSignalManager, _normalLotCalc, _lotCalc, options);

    targetTime = TimeCurrent();
    int hours = 13; // 24-hour format
    int minutes = 25;

    // Convert hours and minutes to seconds and add them to targetTime.
    targetTime += hours * 3600 + minutes * 60;
    return INIT_SUCCEEDED;
}

void OnTick()
{
    buyRecovery.OnTick();
    sellRecovery.OnTick();

    // if (_constants.IsNewBar(_Symbol, PERIOD_CURRENT) && TimeCurrent() > targetTime && _basket1.IsEmpty())
    //{

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool sellSignal = _sellSignalManager.GetSignalWithAnd(SIGNAL_SELL);
    bool buySignal = _buySignalManager.GetSignalWithAnd(SIGNAL_BUY);

    if ((!buySignal && !sellSignal) || !_filterManager.CanTradeWithAnd())
    {
        return;
    }

    int slPoints = 300;
    int tpPoints = 500;

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
    //}

    string comment = "";
    comment += StringFormat("%d orders (buy basket), total volume= %.2f, avg price= %f", _buyBasket.Count(), _buyBasket.Volume(), _buyBasket.AverageOpenPrice());
    comment += StringFormat("%d orders (sell basket), total volume= %.2f, avg price= %f", _sellBasket.Count(), _sellBasket.Volume(), _sellBasket.AverageOpenPrice());
    Comment(comment);
}

void OnDeinit(const int reason)
{
    if (InpShowUI)
    {
        //--- destroy dialog
        ExtDialog.Destroy(reason);
    }

    delete _constants;
    delete _buyBasket;
    delete _sellBasket;
    delete _reporter;
    delete _normalLotCalc;
    delete _lotCalc;
    delete buyRecovery;
    delete sellRecovery;
    delete _buySignalManager;
    delete _sellSignalManager;
    delete _filterManager;
}

void OnChartEvent(const int id,         // event ID
                  const long &lparam,   // event parameter of the long type
                  const double &dparam, // event parameter of the double type
                  const string &sparam) // event parameter of the string type
{
    if (InpShowUI)
    {
        ExtDialog.ChartEvent(id, lparam, dparam, sparam);
    }
}