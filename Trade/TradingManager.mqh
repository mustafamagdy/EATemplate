#include <Object.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include "TradingBasket.mqh";
#include "..\Constants.mqh"

#property strict

class CTradingManager : public CObject
{

protected:
    CConstants *constants;
    CTradingBasket *_basket;
    CTrade _trade;
    CPositionInfo _position;

public:
    CTradingManager(CTradingBasket *basket)
    {
        _basket = basket;
    }

public:
    virtual bool OpenTradeWithPoints(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints, int tpPoints, string comment, string &message, Trade &newTrade)
    {
        double slPrice = 0, tpPrice = 0;
        double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        double spread = ask - bid;
        int spread_points = (int)MathRound(spread / SymbolInfoDouble(Symbol(), SYMBOL_POINT));
        if (slPoints <= spread_points)
        {
            message = "SL points is less than the spread points";
            return (false);
        }

        if (orderType == ORDER_TYPE_BUY)
        {
            slPrice = slPoints > 0 ? price - (slPoints * _Point) : 0;
            tpPrice = tpPoints > 0 ? price + (tpPoints * _Point) : 0;
        }
        else
        {
            slPrice = slPoints > 0 ? price + (slPoints * _Point) : 0;
            tpPrice = tpPoints > 0 ? price - (tpPoints * _Point) : 0;
        }
        return OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, comment, message, newTrade);
    }

    virtual bool OpenTradeWithPrice(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, string comment, string &message, Trade &newTrade)
    {
        return _basket.OpenTradeWithPrice(volume, price, orderType, slPrice, tpPrice, comment, message, newTrade);
    }

    virtual void OnTick()
    {
        _basket.OnTick();
    }
};