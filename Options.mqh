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
    ENUM_BASKET_MAX_ORDER_BEHAVIOUR basketMaxOrderBehaviour;
    double maxGridLots;
    ENUM_RECOVERY_LOT_SIZE_MODE lotMode;
    double lotMultiplier;
    ENUM_GRID_SIZE_MODE gridSizeMode;
    double fixedLot;
    string lotSeries;
    int gridFixedSize;
    ENUM_GRID_FIXED_CUSTOM_MODE gridCustomSizeMode;
    ENUM_RECOVERY_FIXED_CUSTOM_MODE lotCustomMode;
    string gridCustomSeries;
    int gridATRPeriod;
    ENUM_TIMEFRAMES gridATRTimeframe;
    ENUM_VALUE_ACTION gridATRValueAction;
    double gridATRActionValue;
    int gridATRMin;
    int gridATRMax;
    int recoverySLPoints;
    ENUM_BASKET_MAX_SLTP_MODE basketSLMode;
};

struct RiskOptions
{
    ENUM_RISK_TYPE riskType;
    double xBalance;
    double lotPerXBalance;
    double fixedLot;
    ENUM_RISK_SOURCE riskSource;
    double riskPercentage;
};
