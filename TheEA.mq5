#include "Trade\TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";
#include "RiskManagement\NormalLotSizeCalculator.mqh";
#include "Trade\RecoveryManager.mqh"
#include "Trade\NormalTradingManager.mqh";
#include "UI\Reporter.mqh";
#include "UI\EADialog.mqh"

CEADialog ExtDialog;

CTradingBasket *_basket1;
CReporter *_reporter;
CNormalLotSizeCalculator *_normalLotCalc;
CLotSizeCalculator *_lotCalc;
CTradingManager *manager;

int m_maxRecoveryOrderCount = 100;
int m_recoveryTpPoints = 100;
int m_gridFixedSize = 200;
double _riskPercent = 0.05;

datetime targetTime;

bool IsNewBar(ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = NULL)
{
    datetime currentTime = iTime(symbol == NULL ? _Symbol : symbol, timeframe, 0);
    static datetime previousTime = 0;
    if (currentTime == previousTime)
        return false;
    previousTime = currentTime;
    return true;
}

int OnInit()
{
    if (!ExtDialog.Create(0, "Controls", 0, 20, 20, 360, 324))
        return (INIT_FAILED);

    _basket1 = new CTradingBasket(_Symbol, 14324);
    _reporter = new CReporter();

    _normalLotCalc = new CNormalLotSizeCalculator(RISK_TYPE_PERCENTAGE, 0, RISK_PERCENTAGE_FROM_BALANCE, _riskPercent, 0, 0);
    _lotCalc = new CRecoveryLotSizeCalculator(_normalLotCalc, RECOVERY_LOT_MULTIPLIER, 0.1, "", 1.5, RECOVERY_LOT_CUSTOM_SERIES);
    manager = new CRecoveryManager(_basket1, _reporter, _normalLotCalc, _lotCalc, m_maxRecoveryOrderCount, RECOVERY_MARTINGALE, m_recoveryTpPoints,
                                   GRID_SIZE_FIXED, m_gridFixedSize, GRID_SIZE_CUSTOM_MULTIPLIER, "", 0,
                                   ACTION_NONE, 0, 0, 0, true, true);

    // manager = new CNormalTradingManager(_basket1, _reporter);

    targetTime = TimeCurrent();
    int hours = 13; // 24-hour format
    int minutes = 25;

    // Convert hours and minutes to seconds and add them to targetTime.
    targetTime += hours * 3600 + minutes * 60;
    return INIT_SUCCEEDED;
}

void OnTick()
{
    manager.OnTick();

    if (IsNewBar() && TimeCurrent() > targetTime && _basket1.IsEmpty())
    {
        // if (_basket.Count() >= 3)
        // {
        //     _basket.SetBasketAvgTpPoints(300);
        //     _basket.SetBasketAvgSlPoints(500);
        //     _basket.CloseBasketOrders();
        // }

        // CANDLE_STRUCTURE res;
        //_candleType.RecognizeCandle(PERIOD_CURRENT, 1, 2, res);

        // PrintFormat("Candle type is: %s", EnumToString(res.type));

        int slPoints = 200;
        int tpPoints = 200;
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        ENUM_ORDER_TYPE direction = ORDER_TYPE_SELL;
        double price = direction == ORDER_TYPE_BUY ? ask : bid;
        double slPrice = price + (((direction == ORDER_TYPE_BUY ? 1 : -1) * slPoints) * _Point);
        double lots = _lotCalc.CalculateLotSize(_Symbol, price, slPrice, direction);
        string message;
        Trade trade;
        if (!manager.OpenTradeWithPoints(lots, price, direction, slPoints, tpPoints, "test sell", message, trade))
        {
            PrintFormat("Failed to open sell trade: %s", message);
        }
    }

    string comment = "";
    comment += StringFormat("%d orders (buy basket), total volume= %.2f, avg price= %f", _basket1.Count(), _basket1.Volume(), _basket1.AverageOpenPrice());
    Comment(comment);
}

void OnDeinit(const int reason)
{
    //--- destroy dialog
    ExtDialog.Destroy(reason);
}

void OnChartEvent(const int id,         // event ID
                  const long &lparam,   // event parameter of the long type
                  const double &dparam, // event parameter of the double type
                  const string &sparam) // event parameter of the string type
{
    ExtDialog.ChartEvent(id, lparam, dparam, sparam);
}