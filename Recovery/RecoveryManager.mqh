#include "..\Constants.mqh";
#include "..\Enums.mqh";
#include "..\Trade\TradingManager.mqh";
#include "..\Trade\TradingBasket.mqh";


/*
    - main basket contains all the original orders, and manual orders opened after that
    - if locking is enabled, we will have a locking basket, contains positions 
        opened to lock all opened positions in the main basket
    - recovery basket, contains all the current recovery orders (average orders)
 */
class CRecoveryManager : CTradingManager {


};