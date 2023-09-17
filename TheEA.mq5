#include "Enums.mqh"
#include "Common.mqh"
#include "SymbolExpert.mqh"
#include "UI\EADialog.mqh"
#include "UI\Reporter.mqh"

CEADialog ExtDialog;
CReporter _reporter;

datetime targetTime;

input string _g_main = "==== Main Settings ====";                                              //
input double InpXBalance = 25000;                                                              // xBalance
input double InpLotForXBalance = 0.01;                                                         // Lot per xBalance
input double InpLotMultiplier = 1.68;                                                          // Grid Multiplier
input static string _g_pnl = "==== PnL Settings ====";                                         //
input int InpDefaultSLPoints = 200;                                                            // Default SL (Main order) (Points)
input int InpDefaultTPPoints = 500;                                                            /// Default TP (Main order) (Points)
input ENUM_BASKET_PNL_TYPE InpMaxProfitType;                                                   // Max Profit Type (Currency/Percentage)
input double InpMaxProfitValue = 0;                                                            // Max Profit Value (Currency/Percentage, 0=Disabled)
input ENUM_BASKET_PNL_TYPE InpMaxLossType;                                                     // Max Loss Type (Currency/Percentage)
input double InpMaxLossValue = 0;                                                              // Max Loss Value (Currency/Percentage, 0=Disabled)
input ENUM_BASKET_PNL_RESET_MODE InpPnlReset = RESET_24_HOURS;                                 // PnL Reset After
input static string _g_filters = "==== Filter Settings ====";                                  //
input int InpMaxSpread = 100;                                                                  // Max Spread (Points, 0=Disabled)
input static string _g_loss_grid = "==== Loss Grid Settings ====";                             //
input bool InpGridTradeOnlyBySignal = false;                                                   // Grid Trade Only By Signal
input bool InpGridTradeOnlyNewBar = false;                                                     // Grid Trade Only New Bar
input bool InpShowTpLine = true;                                                               // Show TP Line
input bool InpShowSLLine = true;                                                               // Show SL Line
input bool InpUseVirtualSLTP = true;                                                           // Use Virtual SLTP
input double InpRecoveryTpPoints = 100;                                                        // Recovery TP Points
input int InpMaxGridOrderCount = 20;                                                           // Max Grid Order Count
input ENUM_BASKET_MAX_ORDER_BEHAVIOUR InpBasketMaxOrderBehaviour = MAX_ORDER_STOP_ADDING_GRID; // Basket Max Order Behaviour
input ENUM_BASKET_MAX_SLTP_MODE InpBasketSLMode = MAX_SL_MODE_AVERAGE;                         // Basket SL Mode
input int InpMaxBasketSLPoints = 0;                                                            // Max Basket SL Points
input double InpMaxGridLots = 50;                                                              // Max Grid Lots
input ENUM_TIMEFRAMES InpNewBarTimeframe = PERIOD_M5;                                          // New Bar Timeframe
input ENUM_RECOVERY_MODE InpRecoveryMode = RECOVERY_MARTINGALE;                                // Recovery Mode
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
CSymbolExpert *symbolEA;

RiskOptions SetupRiskOptions()
{
    RiskOptions options;

    options.riskType = RISK_TYPE_PER_XBALANCE;
    options.xBalance = InpXBalance;
    options.lotPerXBalance = InpLotForXBalance;
    options.fixedLot = 0;
    options.riskPercentage = 0;
    options.riskSource = RISK_PERCENTAGE_FROM_BALANCE;

    return options;
}

RecoveryOptions SetupRecoveryOptions()
{
    RecoveryOptions options;

    options.gridTradeOnlyNewBar = InpGridTradeOnlyNewBar;
    options.gridTradeOnlyBySignal = InpGridTradeOnlyBySignal;

    options.gridSizeMode = InpGridSizeMode;
    options.gridFixedSize = InpLossGridFixedSize;
    options.gridCustomSizeMode = InpGridCustomSizeMode;
    options.gridCustomSeries = InpGridCustomSeries;
    options.gridATRPeriod = InpGridATRPeriod;
    options.gridATRTimeframe = InpGridATRTimeframe;
    options.gridATRValueAction = InpGridATRValueAction;
    options.gridATRActionValue = InpGridATRActionValue;
    options.gridATRMin = InpGridATRMin;
    options.gridATRMax = InpGridATRMax;

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

int OnInit()
{
    string symbol = _Symbol;

    int spread = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    int maxSpread = (10 * spread); // assuming that 10 times the normal spread is abnormal
    maxSpread = InpMaxSpread > 0 ? MathMin(InpMaxSpread, maxSpread) : maxSpread;

    symbolEA = new CSymbolExpert(symbol, maxSpread, InpDefaultSLPoints, InpDefaultTPPoints, SetupRecoveryOptions(), SetupRiskOptions());
    symbolEA.OnInit();

    if (!symbolEA.ValidateInputs())
    {
        return (INIT_PARAMETERS_INCORRECT);
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
    symbolEA.OnTick();
}

void OnDeinit(const int reason)
{
    delete symbolEA;
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