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
#include "Filters\PnLFilter.mqh"

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
CFilterManager *pEntryFiltersForBuys;
CFilterManager *pExitFiltersForBuys;
CFilterManager *pEntryFiltersForSells;
CFilterManager *pExitFiltersForSells;

datetime targetTime;

input string _g_main = "==== Main Settings ====";                                               //
input double InpXBalance = 25000;                                                               // xBalance
input double InpLotForXBalance = 0.01;                                                          // Lot per xBalance
input double InpLotMultiplier = 1.68;                                                           // Grid Multiplier
input ENUM_BASKET_MAX_SLTP_MODE InpMaxSLMode;                                                   // Basket SL Mode
input int InpMaxLossPoints = 0;                                                                 // Max Average SL (Points, 0=Disabled)
input static string _g_pnl = "==== PnL Settings ====";                                          //
input int InpDefaultSLPoints = 0;                                                               // Default SL (Main order) (Points)
input int InpDefaultTPPoints = 0;                                                               /// Default TP (Main order) (Points)
input ENUM_BASKET_PNL_TYPE InpMaxProfitType;                                                    // Max Profit Type (Currency/Percentage)
input double InpMaxProfitValue = 0;                                                             // Max Profit Value (Currency/Percentage, 0=Disabled)
input ENUM_BASKET_PNL_TYPE InpMaxLossType;                                                      // Max Loss Type (Currency/Percentage)
input double InpMaxLossValue = 0;                                                               // Max Loss Value (Currency/Percentage, 0=Disabled)
input ENUM_BASKET_PNL_RESET_MODE InpPnlReset = RESET_24_HOURS;                                  // PnL Reset After
input static string _g_filters = "==== Filter Settings ====";                                   //
input int InpMaxSpread = 100;                                                                   // Max Spread (Points, 0=Disabled)
input static string _g_loss_grid = "==== Loss Grid Settings ====";                              //
input bool InpShowTpLine = true;                                                                // Show TP Line
input bool InpShowSLLine = true;                                                                // Show SL Line
input bool InpUseVirtualSLTP = true;                                                            // Use Virtual SLTP
input double InpRecoveryTpPoints = 100;                                                         // Recovery TP Points
input int InpMaxGridOrderCount = 6;                                                             // Max Grid Order Count
input ENUM_BASKET_MAX_ORDER_BEHAVIOUR InpBasketMaxOrderBehaviour = MAX_ORDER_CLOSE_FIRST_ORDER; // Basket Max Order Behaviour
input double InpMaxGridLots = 50;                                                               // Max Grid Lots
input ENUM_TIMEFRAMES InpNewBarTimeframe = PERIOD_M5;                                           // New Bar Timeframe
input ENUM_RECOVERY_MODE InpRecoveryMode = RECOVERY_MARTINGALE;                                 // Recovery Mode
input ENUM_GRID_SIZE_MODE InpGridSizeMode = GRID_SIZE_FIXED;                                    // Grid Size Mode
input int InpLossGridFixedSize = 500;                                                           // Fixed Grid Size (Points)
input ENUM_GRID_FIXED_CUSTOM_MODE InpGridCustomSizeMode;                                        // Grid Custom Size Mode
input string InpGridCustomSeries;                                                               // Grid Custom Series
input int InpGridATRPeriod = 5;                                                                 // Grid ATR Period
input ENUM_TIMEFRAMES InpGridATRTimeframe = PERIOD_H1;                                          // Grid ATR Timeframe
input ENUM_VALUE_ACTION InpGridATRValueAction = ATR_ACTION_MULTIPLY;                            // Grid ATR Value Action
input double InpGridATRActionValue = 2;                                                         // Grid ATR Action Value
input int InpGridATRMin = 500;                                                                  // Grid ATR Minimum
input int InpGridATRMax = 0;                                                                    // Grid ATR Maximum
input static string _g_ui = "==== UI Settings ====";                                            //
input bool InpShowUI = false;                                                                   // Show UI

RecoveryOptions SetupRecoveryOptions()
{
    RecoveryOptions options;

    options.gridFixedSize = InpLossGridFixedSize;
    options.gridATRMin = InpLossGridFixedSize;
    options.recoverySLPoints = InpMaxLossPoints;
    options.gridFixedSize = InpLossGridFixedSize;

    // Assuming you have ENUM_GRID_FIXED_CUSTOM_MODE and ENUM_GRID_SIZE_MODE defined in your inputs
    options.gridCustomSizeMode = InpGridCustomSizeMode;
    options.gridCustomSeries = InpGridCustomSeries;
    options.gridATRPeriod = InpGridATRPeriod;
    options.gridATRTimeframe = InpGridATRTimeframe;
    options.gridATRValueAction = InpGridATRValueAction;
    options.gridATRActionValue = InpGridATRActionValue;
    options.gridATRMin = InpGridATRMin;
    options.gridATRMax = InpGridATRMax;

    options.basketMaxOrderBehaviour = InpBasketMaxOrderBehaviour;

    options.maxGridLots = InpMaxGridLots;
    options.newBarTimeframe = InpNewBarTimeframe;
    options.recoveryMode = InpRecoveryMode;
    options.showTpLine = InpShowTpLine;
    options.showSLLine = InpShowSLLine;
    options.useVirtualSLTP = InpUseVirtualSLTP;
    options.recoveryTpPoints = InpRecoveryTpPoints;

    return options;
}

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

    // Entry filters
    pEntryFiltersForBuys = new CFilterManager();
    pEntryFiltersForBuys.RegisterSignal(new CPnLFilter(symbol, _constants, _buyBasket, InpMaxLossType, InpMaxLossValue, InpMaxProfitType, InpMaxProfitValue));
    pEntryFiltersForSells = new CFilterManager();
    pEntryFiltersForSells.RegisterSignal(new CPnLFilter(symbol, _constants, _sellBasket, InpMaxLossType, InpMaxLossValue, InpMaxProfitType, InpMaxProfitValue));

    // Exit filters
    pExitFiltersForBuys = new CFilterManager();
    pExitFiltersForSells = new CFilterManager();

    _normalLotCalc = new CNormalLotSizeCalculator(RISK_TYPE_PER_XBALANCE, 0, RISK_PERCENTAGE_FROM_BALANCE, 0, InpXBalance, InpLotForXBalance);
    //_normalLotCalc = new CNormalLotSizeCalculator(RISK_TYPE_FIXED_LOT, 0.02, RISK_PERCENTAGE_FROM_BALANCE, _riskPercent, 0, 0);
    _lotCalc = new CRecoveryLotSizeCalculator(_normalLotCalc, RECOVERY_LOT_MULTIPLIER, 0, "", InpLotMultiplier, RECOVERY_LOT_CUSTOM_SERIES);
    RecoveryOptions options = SetupRecoveryOptions();

    buyRecovery = new CRecoveryManager(_buyBasket, _reporter, _buySignalManager, _normalLotCalc, _lotCalc, options, pEntryFiltersForBuys, pExitFiltersForBuys);
    sellRecovery = new CRecoveryManager(_sellBasket, _reporter, _sellSignalManager, _normalLotCalc, _lotCalc, options, pEntryFiltersForSells, pExitFiltersForSells);

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

    if ((!buySignal && !sellSignal) || !_filterManager.AllAgree())
    {
        return;
    }

    int slPoints = InpDefaultSLPoints;
    int tpPoints = InpDefaultTPPoints;

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