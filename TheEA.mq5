#include "TradingBasket.mqh";
#include "Candles\CandleTypes.mqh";

TradingBasket _basket;
CCandleTypes _candleType;

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
   _basket.SetMagicNumber(14324, _Symbol);
   return INIT_SUCCEEDED;
}

void OnTick()
{
   _basket.OnTick();
   
    if (IsNewBar())
    {         
        if(_basket.Count() >= 3) {
         _basket.SetBasketAvgTpPoints(300);
         _basket.SetBasketAvgSlPoints(500);
         //_basket.CloseBasketOrders();
        }
        
        CANDLE_STRUCTURE res;
        _candleType.RecognizeCandle(PERIOD_CURRENT, 0, 2, res);

        double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);       
       
        
        if(iClose(_Symbol,PERIOD_CURRENT, 1) > iOpen(_Symbol, PERIOD_CURRENT, 1))        
            _basket.AddTrade(0.1, price, ORDER_TYPE_BUY, 1000, 500, "test buy");
        //else
        //    _basket.AddTrade(0.1, price, ORDER_TYPE_SELL, 1000, 500, "test sell");
    }
    
   string comment = "";
   comment = StringFormat("%d orders, total volume= %.2f, avg price= %f", _basket.Count(), _basket.Volume(), _basket.AverageOpenPrice());
   Comment(comment);
   
   
}  

void OnDeinit(const int reason)
{
   _basket.OnDeinit(); 
}
