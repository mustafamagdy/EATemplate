#include "Enums.mqh";

struct RecoveryOptions
{
    bool showTpLine;
    bool useVirtualSLTP;
    bool gridTradeOnlyBySignal;
    bool gridTradeOnlyNewBar;
    ENUM_TIMEFRAMES newBarTimeframe;
    ENUM_RECOVERY_MODE recoveryMode;
    double recoveryTpPoints;
    int maxGridOrderCount;
    ENUM_GRID_SIZE_MODE gridSizeMode;
    int gridFixedSize;
    ENUM_GRID_FIXED_CUSTOM_MODE gridCustomSizeMode;
    string gridCustomSeries;
    int gridATRPeriod;
    ENUM_TIMEFRAMES gridATRTimeframe;
    ENUM_VALUE_ACTION gridATRValueAction;
    double gridATRActionValue;
    int gridATRMin;
    int gridATRMax;
};