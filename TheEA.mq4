#include "Enums.mqh"
#include "Common.mqh"
#include "Options.mqh"
#include "SymbolExpert.mqh"
#include "UI\EADialog.mqh"
#include "UI\Reporter.mqh"

CEADialog ExtDialog;

datetime targetTime;

input string _g_main = "==== Main Settings ====";                                              //
input ENUM_RISK_TYPE InpRiskType = RISK_TYPE_PER_XBALANCE;                                     // Risk Type
input ENUM_RISK_SOURCE InpRiskSource = RISK_PERCENTAGE_FROM_BALANCE;                           // Risk Source
input double InpXBalance = 25000;                                                              // xBalance
input double InpLotForXBalance = 0.01;                                                         // Lot per xBalance
input double InpRiskPercentage = 2;                                                            // Risk Percentage
input double InpRiskFixedLot = 0.01;                                                           // Risk Fixed Lot
input string _g_multi_symbols = "==== Multi Symbol Settings ====";                             //
input string InpSymbols = "AUDUSD,EURUSD,USDJPY,GBPUSD";                                       // Symbols (comma separated), Leave blank to use current
input static string _g_pnl = "==== PnL Settings ====";                                         //
input int InpDefaultSLPoints = 200;                                                            // Default SL (Main order) (Points)
input int InpDefaultTPPoints = 500;                                                            /// Default TP (Main order) (Points)
input ENUM_BASKET_PNL_TYPE InpMaxProfitType;                                                   // Max Profit Type (Currency/Percentage)
input double InpMaxProfitValue = 0;                                                            // Max Profit Value (Currency/Percentage, 0=Disabled)
input ENUM_BASKET_PNL_TYPE InpMaxLossType;                                                     // Max Loss Type (Currency/Percentage)
input double InpMaxLossValue = 0;                                                              // Max Loss Value (Currency/Percentage, 0=Disabled)
input ENUM_PNL_RESET_MODE InpPnlReset = RESET_AFTER_N_MINUTES;                                 // PnL Reset After
input int InpResetAfterNMinutes = 24 * 60;                                                     // Reset After N Minutes
input static string _g_filters = "==== Filter Settings ====";                                  //
input int InpMaxSpread = 100;                                                                  // Max Spread (Points, 0=Disabled)
input static string _g_loss_grid = "==== Loss Grid Settings ====";                             //
input ENUM_RECOVERY_MODE InpRecoveryMode = RECOVERY_MARTINGALE;                                // Recovery Mode
input bool InpGridTradeOnlyBySignal = false;                                                   // Grid Trade Only By Signal
input bool InpGridTradeOnlyNewBar = false;                                                     // Grid Trade Only New Bar
input ENUM_TIMEFRAMES InpNewBarTimeframe = PERIOD_M5;                                          // New Bar Timeframe
input bool InpShowTpLine = true;                                                               // Show TP Line
input bool InpShowSLLine = true;                                                               // Show SL Line
input bool InpUseVirtualSLTP = true;                                                           // Use Virtual SLTP
input double InpRecoveryTpPoints = 100;                                                        // Recovery TP Points
input int InpMaxGridOrderCount = 20;                                                           // Max Grid Order Count
input double InpMaxGridLots = 50;                                                              // Max Grid Lots
input ENUM_BASKET_MAX_ORDER_BEHAVIOUR InpBasketMaxOrderBehaviour = MAX_ORDER_STOP_ADDING_GRID; // Basket Max Order Behaviour
input ENUM_RECOVERY_LOT_SIZE_MODE InpLotSizeMode = RECOVERY_LOT_MULTIPLIER;                    // Grid Lot Size Mode
input double InpLotMultiplier = 1.68;                                                          // Grid Multiplier
input double InpGridFixedLot = 0;                                                              // Grid Fixed Lot
input ENUM_RECOVERY_FIXED_CUSTOM_MODE InpLotCusomMode;                                         // Grid Lot Custom Mode
input string InpGridLotCustomSeries;                                                           // Grid Custom Series
input ENUM_BASKET_MAX_SLTP_MODE InpBasketSLMode = MAX_SL_MODE_AVERAGE;                         // Basket SL Mode
input int InpMaxBasketSLPoints = 0;                                                            // Max Basket SL Points
input ENUM_GRID_SIZE_MODE InpGridSizeMode = GRID_SIZE_FIXED;                                   // Grid Size Mode
input int InpLossGridFixedSize = 500;                                                          // Fixed Grid Size (Points)
input ENUM_GRID_FIXED_CUSTOM_MODE InpGridCustomSizeMode;                                       // Grid Custom Size Mode
input string InpGridCustomSeries;                                                              // Grid Custom Series
input int InpGridATRPeriod = 5;                                                                // Grid ATR Period
input ENUM_TIMEFRAMES InpGridATRTimeframe = PERIOD_H1;                                         // Grid ATR Timeframe
input ENUM_VALUE_ACTION InpGridATRValueAction = ATR_ACTION_MULTIPLY;                           // Grid ATR Value Action
input double InpGridATRActionValue = 2;                                                        // Grid ATR Action Value
input int InpGridATRMin = 500;                                                                 // Grid ATR Minimum
input int InpGridATRMax = 0;                                                                   // Grid ATR Maximum
input static string _g_ui = "==== UI Settings ====";                                           //
input bool InpShowUI = false;                                                                  // Show UI

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
CReporter *_reporter;
FirstEA *gEAs[];
CPnLManager *gPnlManager;
CTradingStatusManager *gTradingStatusManager;

RiskOptions SetupRiskOptions()
{
    RiskOptions options;

    options.riskType = InpRiskType;
    options.xBalance = InpXBalance;
    options.lotPerXBalance = InpLotForXBalance;
    options.fixedLot = InpRiskFixedLot;
    options.riskPercentage = InpRiskPercentage;
    options.riskSource = InpRiskSource;

    return options;
}

PnLOptions SetupPnlOptions()
{
    PnLOptions options;
    options.maxLossForAllPairs = InpMaxLossValue;
    options.resetMode = InpPnlReset;
    options.resetAfterNMinutes = InpResetAfterNMinutes;
    return options;
}

MartingaleOptions SetupMartingaleOptions()
{
    MartingaleOptions options;

    options.gridTradeOnlyNewBar = InpGridTradeOnlyNewBar;
    options.gridTradeOnlyBySignal = InpGridTradeOnlyBySignal;

    options.gridSizeMode = InpGridSizeMode;
    options.gridFixedSize = InpLossGridFixedSize;
    options.gridCustomSizeMode = InpGridCustomSizeMode;
    options.gridGapCustomSeries = InpGridCustomSeries;
    options.gridATRPeriod = InpGridATRPeriod;
    options.gridATRTimeframe = InpGridATRTimeframe;
    options.gridATRValueAction = InpGridATRValueAction;
    options.gridATRActionValue = InpGridATRActionValue;
    options.gridATRMin = InpGridATRMin;
    options.gridATRMax = InpGridATRMax;

    options.lotMode = InpLotSizeMode;
    options.fixedLot = InpGridFixedLot;
    options.gridLotSeries = InpGridLotCustomSeries;
    options.lotCustomMode = InpLotCusomMode;
    options.lotMultiplier = InpLotMultiplier;

    options.recoverySLPoints = InpMaxBasketSLPoints;
    options.basketSLMode = InpBasketSLMode;
    options.basketMaxOrderBehaviour = InpBasketMaxOrderBehaviour;
    options.maxGridOrderCount = InpMaxGridOrderCount;

    options.maxGridLots = InpMaxGridLots;
    options.newBarTimeframe = InpNewBarTimeframe;
    options.recoveryMode = InpRecoveryMode;
    options.showTpLine = InpShowTpLine;
    options.showSLLine = InpShowSLLine;
    options.useVirtualSLTP = InpUseVirtualSLTP;
    options.recoveryTpPoints = InpRecoveryTpPoints;

    return options;
}

void SetupSymbolEA(string symbol)
{
    int spread = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    int maxSpread = (10 * spread); // assuming that 10 times the normal spread is abnormal
    maxSpread = InpMaxSpread > 0 ? MathMin(InpMaxSpread, maxSpread) : maxSpread;

    ArrayResize(gEAs, ArraySize(gEAs) + 1);
    int idx = ArraySize(gEAs) - 1;
    gEAs[idx] = new FirstEA(symbol, maxSpread, InpDefaultSLPoints, InpDefaultTPPoints, SetupMartingaleOptions(), SetupRiskOptions(), gPnlManager, gTradingStatusManager);
    gEAs[idx].OnInit();
}

int OnInit()
{
    _reporter = new CReporter();
    string symbols[];
    StringSplit(InpSymbols, ',', symbols);
    // AUDUSD,EURUSD,USDJPY,GBPUSD,USDCHF,USDCAD,AUDCAD,AUDJPY,EURJPY,EURGBP,EURCHF,EURCAD,GBPJPY

    gTradingStatusManager = new CTradingStatusManager(_reporter);
    gPnlManager = new CPnLManager(SetupPnlOptions(), _reporter, gTradingStatusManager);

    if (!gPnlManager.ValidateInput())
    {
        return (INIT_PARAMETERS_INCORRECT);
    }
    
    if (ArraySize(symbols) == 0)
    {
        ArrayResize(symbols, 1);
        symbols[0] = _Symbol;
    }

    for (int i = 0; i < ArraySize(symbols); i++)
    {
        SetupSymbolEA(symbols[i]);
        if (!gEAs[i].ValidateInputs())
        {
            return (INIT_PARAMETERS_INCORRECT);
        }
    }

    if (InpShowUI)
    {
        if (!ExtDialog.Create(0, "Controls", 0, 20, 20, 320, 310))
            return (INIT_FAILED);
    }

    targetTime = TimeCurrent();
    int hours = 13; // 24-hour format
    int minutes = 25;

    // Convert hours and minutes to seconds and add them to targetTime.
    targetTime += hours * 3600 + minutes * 60;

    return INIT_SUCCEEDED;
}

void OnTick()
{
    for (int i = 0; i < ArraySize(gEAs); i++)
    {
        gEAs[i].OnTick();
    }

    gPnlManager.OnTick();
}

void OnDeinit(const int reason)
{
    ArrayFree(gEAs);
    delete gPnlManager;
    delete _reporter;
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