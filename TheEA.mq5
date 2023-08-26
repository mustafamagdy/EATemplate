#include "Trade\TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";
#include "RiskManagement\NormalLotSizeCalculator.mqh";

TradingBasket _basket;
CCandleTypes _candleType;
CNormalLotSizeCalculator *_lotCalc;

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
    _lotCalc = new CNormalLotSizeCalculator(RISK_TYPE_PERCENTAGE, 0, RISK_PERCENTAGE_FROM_BALANCE, 1, 0, 0);
    _basket.SetMagicNumber(14324, _Symbol);
    return INIT_SUCCEEDED;
}

void OnTick()
{
    _basket.OnTick();

    if (IsNewBar())
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
        double lots = _lotCalc.CalculateLotSize(_Symbol, ask, slPoints, ORDER_TYPE_BUY);
        string message;
        if(!_basket.AddTradeWithPoints(_Symbol, lots, ask, ORDER_TYPE_BUY, slPoints, tpPoints, "test buy", message)) {
         PrintFormat("Failed to open trade: %s", message);
        }
        
        // if (rand() > 20000)
        // {
        //     double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        //     double lots = _lotCalc.CalculateLotSize(_Symbol, ask, slPoints, ORDER_TYPE_BUY);
        //     _basket.AddTrade(lots, ask, ORDER_TYPE_BUY, slPoints, tpPoints, "test buy");
        // }
        // else if (rand() < 10000)
        // {
        //     double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        //     double lots = _lotCalc.CalculateLotSize(_Symbol, bid, slPoints, ORDER_TYPE_SELL);
        //     _basket.AddTrade(lots, bid, ORDER_TYPE_SELL, slPoints, tpPoints, "test sell");
        // }
    }

    string comment = "";
    comment = StringFormat("%d orders, total volume= %.2f, avg price= %f", _basket.Count(), _basket.Volume(), _basket.AverageOpenPrice());
    Comment(comment);
}

void OnDeinit(const int reason)
{
    _basket.OnDeinit();
}
