
enum ENUM_VALUE_ACTION {
   ACTION_NONE                               = -1, //As Is
   ACTION_DEVIDE                             = 0,  //Devide
   ACTION_MULTIPLY                           = 1,  //Multiply
};

enum ENUM_RISK_TYPE {
    RISK_TYPE_FIXED_LOT                      = 0,        //Fixed Lot
    RISK_TYPE_PERCENTAGE                     = 1,        //Risk Percentage
    RISK_TYPE_PER_XBALANCE                   = 2,        //Lots per xBalance
};

enum ENUM_RISK_PERCENTAGE {
   RISK_PERCENTAGE_FROM_BALANCE              = 0,        //% of Balance
   RISK_PERCENTAGE_FROM_EQUITY               = 1,        //% of Equity
   RISK_PERCENTAGE_FROM_AVILABLE_MARGIN      = 2,        //% of Available Margin
};

enum ENUM_RECOVERY_MODE {
   RECOVERY_NONE                             = 0, //No Recovery
   RECOVERY_MARTINGALE                       = 1, //Martingale
   RECOVERY_HEDGING                          = 2, //Hedging
};

enum ENUM_RECOVERY_LOT_SIZE_MODE {
   RECOVERY_LOT_FIXED                        = 0,  //Fixed Lot
   RECOVERY_LOT_ADD                          = 1,  //Add Lot
   RECOVERY_LOT_FIXED_CUSTOM                 = 2,  //Custom Series
};

enum ENUM_RECOVERY_FIXED_CUSTOM_MODE {
   RECOVERY_LOT_CUSTOM_SERIES                = 0,  //Custom Series
   RECOVERY_LOT_CUSTOM_ROLLING               = 1,  //Custom Series (Restart when finished)
   RECOVERY_LOT_CUSTOM_MULTIPLIER            = 2,  //Custom Multiplier series
};
