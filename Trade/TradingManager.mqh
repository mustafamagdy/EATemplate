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
    virtual void OnTick()
    {
        _basket.OnTick();
    }
};