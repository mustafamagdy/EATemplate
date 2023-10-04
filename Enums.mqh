
enum ENUM_VALUE_ACTION
{
    ATR_ACTION_NONE = 0,     // As Is
    ATR_ACTION_DEVIDE = 1,   // Devide
    ATR_ACTION_MULTIPLY = 2, // Multiply
};

enum ENUM_RISK_TYPE
{
    RISK_TYPE_FIXED_LOT = 0,    // Fixed Lot
    RISK_TYPE_PERCENTAGE = 1,   // Risk Percentage
    RISK_TYPE_PER_XBALANCE = 2, // Lots per xBalance
};

enum ENUM_VALUE_TYPE {
    VALUE_CURRENCY = 0;         //Currency
    VALUE_PERCENTAGE = 1,       //Percentage
};

enum ENUM_RISK_SOURCE
{
    RISK_PERCENTAGE_FROM_BALANCE = 0,         //% of Balance
    RISK_PERCENTAGE_FROM_EQUITY = 1,          //% of Equity
    RISK_PERCENTAGE_FROM_AVILABLE_MARGIN = 2, //% of Available Margin
};

enum ENUM_RECOVERY_LOT_SIZE_MODE
{
    RECOVERY_LOT_FIXED = 0,        // Fixed Lot
    RECOVERY_LOT_ADD = 1,          // Add Lot
    RECOVERY_LOT_MULTIPLIER = 2,   // Multiplier Lot
    RECOVERY_LOT_FIXED_CUSTOM = 3, // Custom Series
};

enum ENUM_RECOVERY_FIXED_CUSTOM_MODE
{
    RECOVERY_LOT_CUSTOM_SERIES = 0,                   // Custom Series
    RECOVERY_LOT_CUSTOM_ROLLING = 1,                  // Custom Series (Restart when finished)
    RECOVERY_LOT_CUSTOM_MULTIPLIER = 2,               // Custom Multiplier series
    RECOVERY_LOT_CUSTOM_MULTIPLIER_FROM_ORIGINAL = 3, // Custom Multiplier series from original
};

enum ENUM_GRID_SIZE_MODE
{
    GRID_SIZE_FIXED = 0,        // Fixed Size
    GRID_SIZE_FIXED_CUSTOM = 1, // Custom Series
    GRID_SIZE_ATR = 2,          // ATR Based
};

enum ENUM_GRID_FIXED_CUSTOM_MODE
{
    GRID_SIZE_CUSTOM_SERIES = 0,     // Custom Fixed Series
    GRID_SIZE_CUSTOM_ROLLING = 1,    // Custom Series (Restart when finished)
    GRID_SIZE_CUSTOM_MULTIPLIER = 2, // Custom Multiplier Series
};

enum ENUM_SIGNAL
{
    SIGNAL_NEUTRAL = 0,
    SIGNAL_BUY = 1,
    SIGNAL_SELL = 2,
};

enum ENUM_BASKET_PNL_TYPE
{
    MAX_PNL_CURRENCY_PER_PAIR = 0,  // Currency value per pair
    MAX_PNL_CURRENCY_ALL_PAIRS = 1, // Currency value for all pairs
    MAX_PNL_PERCENT_EQUITY = 2,     // Percentage of equity
};

enum ENUM_PNL_RESET_MODE
{
    RESET_AFTER_N_MINUTES = 0, // Reset after number of minutes
    RESET_AFTER_RESTART = 1,   // Reset after restart
};

enum ENUM_BASKET_MAX_SLTP_MODE
{
    MAX_SL_MODE_AVERAGE = 0,        // Weighted Average
    MAX_SL_MODE_INDIVIDUAL = 1,     // Individual per position
    MAX_SL_MODE_GAP_FROM_FIRST = 2, // Gap from first position
};

enum ENUM_BASKET_MAX_ORDER_BEHAVIOUR
{
    MAX_ORDER_STOP_ADDING_GRID = 0,  // Stop adding new orders
    MAX_ORDER_CLOSE_FIRST_ORDER = 1, // Close first order and add new order
};
