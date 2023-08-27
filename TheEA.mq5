#include "Trade\TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";
#include "RiskManagement\NormalLotSizeCalculator.mqh";

TradingBasket _basket1;
TradingBasket _basket2;
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
    _basket1.SetMagicNumber(14324, _Symbol);
    _basket2.SetMagicNumber(3456, _Symbol);
    return INIT_SUCCEEDED;
}

void OnTick()
{
    _basket1.OnTick();
    _basket2.OnTick();

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
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double lots = _lotCalc.CalculateLotSize(_Symbol, ask, slPoints, ORDER_TYPE_BUY);
        string message;
        if(!_basket1.AddTradeWithPoints(_Symbol, lots, ask, ORDER_TYPE_BUY, slPoints, tpPoints, "test buy", message)) {
         PrintFormat("Failed to open buy trade: %s", message);
        }

        if(!_basket2.AddTradeWithPoints(_Symbol, lots, bid, ORDER_TYPE_SELL, slPoints, tpPoints, "test sell", message)) {
         PrintFormat("Failed to open sell trade: %s", message);
        }
        
        if (rand() > 20000)
        {
            // double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            // double lots = _lotCalc.CalculateLotSize(_Symbol, ask, slPoints, ORDER_TYPE_BUY);
            // _basket.AddTrade(lots, ask, ORDER_TYPE_BUY, slPoints, tpPoints, "test buy");
            _basket1.CloseBasketOrders();
        }
        else if (rand() < 10000)
        {
            // double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            // double lots = _lotCalc.CalculateLotSize(_Symbol, bid, slPoints, ORDER_TYPE_SELL);
            // _basket.AddTrade(lots, bid, ORDER_TYPE_SELL, slPoints, tpPoints, "test sell");
            _basket2.CloseBasketOrders();
        }
    }

    string comment = "";
    comment += StringFormat("%d orders (buy basket), total volume= %.2f, avg price= %f", _basket1.Count(), _basket1.Volume(), _basket1.AverageOpenPrice());
    comment += "\n";
    comment += StringFormat("%d orders (sell basket), total volume= %.2f, avg price= %f", _basket2.Count(), _basket2.Volume(), _basket2.AverageOpenPrice());
    Comment(comment);
}

void OnDeinit(const int reason)
{
    _basket1.OnDeinit();
    _basket2.OnDeinit();
}
