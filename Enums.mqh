
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