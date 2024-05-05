#include "..\Options.mqh"

input static string _g_loss_grid = "==== Loss Grid Settings ====";                                    //
input bool InpGridTradeOnlyBySignal = false;                                                          // Grid Trade Only By Signal
input bool InpGridTradeOnlyNewBar = true;                                                             // Grid Trade Only New Bar
input ENUM_TIMEFRAMES InpNewBarTimeframe = PERIOD_M15;                                                // New Bar Timeframe
input bool InpShowTpLine = true;                                                                      // Show TP Line
input bool InpShowSLLine = true;                                                                      // Show SL Line
input bool InpUseVirtualSLTP = true;                                                                  // Use Virtual SLTP
input double InpRecoveryTpPoints = 100;                                                               // Recovery TP Points
input int InpMaxGridOrderCount = 0;                                                                   // Max Grid Order Count (0=Disabled)
input double InpMaxGridLots = 50;                                                                     // Max Grid Lots (0=Disabled)
input ENUM_BASKET_MAX_ORDER_BEHAVIOUR InpBasketMaxOrderBehaviour = MAX_ORDER_STOP_ADDING_GRID;        // Basket Max Order Behaviour
input ENUM_RECOVERY_LOT_SIZE_MODE InpLotSizeMode = RECOVERY_LOT_MULTIPLIER;                           // Grid Lot Size Mode
input double InpLotMultiplier = 1.68;                                                                 // Grid Multiplier
input double InpGridFixedLot = 0;                                                                     // Grid Fixed Lot
input ENUM_RECOVERY_FIXED_CUSTOM_MODE InpLotCusomMode = RECOVERY_LOT_CUSTOM_MULTIPLIER_FROM_ORIGINAL; // Grid Lot Custom Mode
input string InpGridLotCustomSeries = "1,1,1,3,6,9,12,15,21,27,33,39,45,55,65,75,85,95,120,140";      // Grid Custom Series
input ENUM_BASKET_MAX_SLTP_MODE InpBasketSLMode = MAX_SL_MODE_AVERAGE;                                // Basket SL Mode
input int InpMaxBasketSLPoints = 0;                                                                   // Max Basket SL Points
input ENUM_GRID_SIZE_MODE InpGridSizeMode = GRID_SIZE_FIXED;                                          // Grid Size Mode
input int InpLossGridFixedSize = 500;                                                                 // Fixed Grid Size (Points)
input ENUM_GRID_FIXED_CUSTOM_MODE InpGridCustomSizeMode;                                              // Grid Custom Size Mode
input string InpGridCustomSeries;                                                                     // Grid Custom Series
input int InpGridATRPeriod = 5;                                                                       // Grid ATR Period
input ENUM_TIMEFRAMES InpGridATRTimeframe = PERIOD_H1;                                                // Grid ATR Timeframe
input ENUM_VALUE_ACTION InpGridATRValueAction = ATR_ACTION_MULTIPLY;                                  // Grid ATR Value Action
input double InpGridATRActionValue = 2;                                                               // Grid ATR Action Value
input int InpGridATRMin = 500;                                                                        // Grid ATR Minimum
input int InpGridATRMax = 0;                                                                          // Grid ATR Maximum




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
    options.showTpLine = InpShowTpLine;
    options.showSLLine = InpShowSLLine;
    options.useVirtualSLTP = InpUseVirtualSLTP;
    options.recoveryTpPoints = InpRecoveryTpPoints;

    return options;
}