#include "Enums.mqh"
#include "Common.mqh"
#include "Options.mqh"
#include "EAs/ExpertBase.mqh"
#include "EAs/BasicEANoMartingale.mqh"
#include "UI/EADialog.mqh"
#include "UI/Reporter.mqh"


CEADialog ExtDialog;

datetime targetTime;

input string _g_main = "==== Main Settings ====";                                                     //
input ENUM_RISK_TYPE InpRiskType = RISK_TYPE_PER_XBALANCE;                                            // Risk Type
input double InpXBalance = 25000;                                                                     // xBalance
input double InpLotForXBalance = 0.01;                                                                // Lot per xBalance
input double InpRiskPercentage = 2;                                                                   // Risk Percentage
input ENUM_RISK_SOURCE InpRiskSource = RISK_PERCENTAGE_FROM_BALANCE;                                  // Risk Source (% of)
input double InpRiskFixedLot = 0.01;                                                                  // Risk Fixed Lot
input string _g_multi_symbols = "==== Multi Symbol Settings ====";                                    //
input string InpSymbols = "";                                                                         // Symbols (comma separated), Leave blank to use current
input static string _g_pnl = "==== PnL Settings ====";                                                //
input int InpDefaultSLPoints = 200;                                                                   // Default SL (Main order) (Points)
input int InpDefaultTPPoints = 500;                                                                   /// Default TP (Main order) (Points)
input ENUM_BASKET_PNL_TYPE InpMaxProfitType;                                                          // Max Profit Type (Currency/Percentage)
input double InpMaxProfitValue = 0;                                                                   // Max Profit Value (Currency/Percentage, 0=Disabled)
input ENUM_BASKET_PNL_TYPE InpMaxLossType;                                                            // Max Loss Type (Currency/Percentage)
input double InpMaxLossValue = 0;                                                                     // Max Loss Value (Currency/Percentage, 0=Disabled)
input ENUM_PNL_RESET_MODE InpPnlReset = RESET_AFTER_N_MINUTES;                                        // PnL Reset After
input int InpResetAfterNMinutes = 24 * 60;                                                            // Reset After N Minutes
input static string _g_filters = "==== Filter Settings ====";                                         //
input int InpMaxSpread = 100;                                                                         // Max Spread (Points, 0=Disabled)

#ifdef __RECOVERY_EA__
#include "Recovery\RecoveryParameters.mqh"
#endif 

input static string _g_ui = "==== UI Settings ====";                                                  //
input bool InpShowUI = false;                                                                         // Show UI

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
CReporter *_reporter;
CExpertBase *gEAs[];
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



CExpertBase* SetupSymbolEA(string symbol)
{
    int spread = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    int maxSpread = (10 * spread); // assuming that 10 times the normal spread is abnormal
    maxSpread = InpMaxSpread > 0 ? MathMin(InpMaxSpread, maxSpread) : maxSpread;

    
    //return new CProfitCrumpEA(symbol, maxSpread, InpDefaultSLPoints, InpDefaultTPPoints, SetupMartingaleOptions(), SetupRiskOptions(), gPnlManager, gTradingStatusManager);
    //return new CFirstEA(symbol, maxSpread, InpDefaultSLPoints, InpDefaultTPPoints, SetupMartingaleOptions(), SetupRiskOptions(), gPnlManager, gTradingStatusManager);    
    return new BasicEANoMartingale(symbol, maxSpread, InpDefaultSLPoints, InpDefaultTPPoints, SetupRiskOptions(), gPnlManager, gTradingStatusManager);    
}

int OnInit()
{
    _reporter = new CReporter();
    string symbols[];
    StringSplit(InpSymbols, ',', symbols);
    // AUDUSD,EURUSD,USDJPY,GBPUSD,USDCHF,AUDCAD,,EURGBP,EURCHF,EURCAD,GBPJPY,USDCAD,AUDJPY

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
        CExpertBase *ea = SetupSymbolEA(symbols[i]);
        ea.OnInit();
        if (!ea.ValidateInputs())
        {
            return (INIT_PARAMETERS_INCORRECT);
        }
        
        ArrayResize(gEAs, ArraySize(gEAs) + 1);
        int idx = ArraySize(gEAs) - 1;
        gEAs[idx] = ea;                
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