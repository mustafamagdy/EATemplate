#include "Enums.mqh";

struct RecoveryOptions
{
    bool showTpLine;
    bool showSLLine;
    bool useVirtualSLTP;
    bool gridTradeOnlyBySignal;
    bool gridTradeOnlyNewBar;
    ENUM_TIMEFRAMES newBarTimeframe;
    ENUM_RECOVERY_MODE recoveryMode;
    double recoveryTpPoints;
    int maxGridOrderCount;
    double maxGridLots;
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
    int recoverySLPoints;
    ENUM_BASKET_SLTP_MODE basketSLMode;
};