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
        return _basket.OpenTradeWithPoints(volume, price, orderType, slPoints, tpPoints, comment, message, newTrade);
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