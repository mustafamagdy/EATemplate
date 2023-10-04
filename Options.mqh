#include "Enums.mqh";

struct MartingaleOptions
{
    bool showTpLine;
    bool showSLLine;
    bool useVirtualSLTP;
    bool gridTradeOnlyBySignal;
    bool gridTradeOnlyNewBar;
    ENUM_TIMEFRAMES newBarTimeframe;
    double recoveryTpPoints;
    int maxGridOrderCount;
    ENUM_BASKET_MAX_ORDER_BEHAVIOUR basketMaxOrderBehaviour;
    double maxGridLots;
    ENUM_RECOVERY_LOT_SIZE_MODE lotMode;
    double lotMultiplier;
    double fixedLot;
    string gridLotSeries;
    ENUM_RECOVERY_FIXED_CUSTOM_MODE lotCustomMode;
    ENUM_GRID_SIZE_MODE gridSizeMode;
    int gridFixedSize;
    ENUM_GRID_FIXED_CUSTOM_MODE gridCustomSizeMode;
    string gridGapCustomSeries;
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

struct PnLOptions
{
    double maxProfitForAllPairs;
    double maxLossForAllPairs;
    ENUM_PNL_RESET_MODE resetMode;
    int resetAfterNMinutes;
};

struct RecoveryOptions {
    bool useLocking;
    double DDValue;
    ENUM_VALUE_TYPE DDValueType;

};