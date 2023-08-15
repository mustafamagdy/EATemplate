#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

enum ENUM_BASKET_STATUS
{
    BASKET_OPEN = 0,
    BASKET_CLOSING = 1,
    BASKET_CLOSED = 2
};

class Trade
{
private:
    ulong _ticket;
    long _magicNumber;
    string _symbol;
    double _openPrice;
    double _volume;
    double _fees;
    double _sLPrice;
    double _tPPrice;
    string _comment;

public:
    Trade() {}
    Trade(ulong ticket, long magicNumber, string symbol,
          double openPrice, double volume, double fees,
          double sLPrice, double tPPrice, string comment)
    {
        _ticket = ticket;
        _magicNumber = magicNumber;
        _symbol = symbol;
        _openPrice = openPrice;
        _volume = volume;
        _fees = fees;
        _sLPrice = sLPrice;
        _tPPrice = tPPrice;
        _comment = comment;
    }

public:
    ulong Ticket() const { return _ticket; }
    long MagicNumber() const { return _magicNumber; }
    string Symbol() const { return _symbol; }
    double OpenPrice() const { return _openPrice; }
    double Volume() const { return _volume; }
    double Fees() const { return _fees; }
    double SLPrice() const { return _sLPrice; }
    double TPPrice() const { return _tPPrice; }
    string Comment() const { return _comment; }
};

class TradingBasket
{
private:
    CTrade _trade;
    CPositionInfo _position;
    Trade _trades[];
    ENUM_BASKET_STATUS _basketStatus;
    long _magicNumber;
    string _symbol;
    int _basketAvgTpPoints;
    int _basketAvgSlPoints;

public:
    TradingBasket()
    {
        _basketStatus = BASKET_OPEN;
    }

    void SetMagicNumber(long magicNumber, string symbol)
    {
        _magicNumber = magicNumber;
        _symbol = symbol;
    }

    void SetBasketAvgTpPoints(int basketAvgTpPoints)
    {
        _basketAvgTpPoints = basketAvgTpPoints;
        _UpdateAvgTpForBasketTrades();
    }

    void SetBasketAvgSlPoints(int basketAvgSlPoints)
    {
        _basketAvgSlPoints = basketAvgSlPoints;
        _UpdateAvgSlForBasketTrades();
    }

    void AddTrade(double volume, double price, ENUM_ORDER_TYPE orderType, int slPoints = 0, int tpPoints = 0, string comment = "")
    {
        double slPrice = 0, tpPrice = 0;
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

        AddTrade(volume, price, orderType, slPrice, tpPrice, comment);
    }

    void AddTrade(double volume, double price, ENUM_ORDER_TYPE orderType, double slPrice = 0, double tpPrice = 0, string comment = "")
    {
        if (_basketStatus != BASKET_OPEN)
        {
            // TODO: error reporting
            return;
        }

        MqlTradeResult result;
        _trade.PositionOpen(_symbol, orderType, volume, price, slPrice, tpPrice, comment);
        _trade.Result(result);

        if (result.retcode > 0)
        {
            Trade *trade = new Trade(result.order, _trade.RequestMagic(), _trade.RequestSymbol(),
                                     result.price, result.volume, 0,
                                     _trade.RequestSL(), _trade.RequestTP(), result.comment);
            ArrayResize(_trades, ArraySize(_trades) + 1);
            _trades[ArraySize(_trades) - 1] = trade;

            _UpdateAvgTpForBasketTrades();
            _UpdateAvgSlForBasketTrades();
        }
        else
        {
            // TODO
        }
    }

    double Volume()
    {
        double totalVolume = 0.0;
        for (int i = 0; i < ArraySize(_trades); i++)
        {
            totalVolume += _trades[i].Volume();
        }
        return totalVolume;
    }

    double AverageOpenPrice()
    {
        double totalPrice = 0.0;
        double totalVolume = 0.0;
        for (int i = 0; i < Count(); i++)
        {
            totalVolume += _trades[i].Volume();
            totalPrice += _trades[i].OpenPrice() * _trades[i].Volume();
        }

        if (Count() == 0 || totalVolume == 0)
            return 0;
        double avgPrice = totalPrice / totalVolume;
        return avgPrice;
    }

    double Profit()
    {
        double totalProfit = 0.0;
        for (int i = Count() - 1; i >= 0; i--)
        {
            ulong ticket = _trades[i].Ticket();
            if (PositionSelectByTicket(ticket))
            {
                totalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            }
        }
        return totalProfit;
    }

    int Count() { return ArraySize(_trades); }
    bool HasOpenedTrades() { return Count() > 0; }

    void CloseBasketOrders()
    {
        _basketStatus = BASKET_CLOSING;
        for (int i = Count() - 1; i >= 0; i--)
        {
            ulong ticket = _trades[i].Ticket();
            if (PositionSelectByTicket(ticket))
            {
                if (_trade.PositionClose(ticket, ULONG_MAX))
                {
                    ArrayRemove(_trades, i, 1);
                }
                else
                {
                    // TODO
                }
            }
        }

        if (Count() == 0)
        {
            _basketStatus = BASKET_CLOSED;
        }
    }

    void OnTick()
    {
        for (int i = Count() - 1; i >= 0; i--)
        {
            ulong ticket = _trades[i].Ticket();
            if (!PositionSelectByTicket(ticket))
            {
                ArrayRemove(_trades, i, 1);
            }
        }
    }

    void OnDeinit()
    {
        ArrayFree(_trades);
    }

private:
    void _UpdateAvgTpForBasketTrades()
    {
        if (Count() == 0 || _basketAvgTpPoints == 0)
            return;

        double avgPrice = AverageOpenPrice();
        for (int i = Count() - 1; i >= 0; i--)
        {
            ulong ticket = _trades[i].Ticket();
            if (_position.SelectByTicket(ticket))
            {
                double tpPrice = 0;

                if (_position.PositionType() == POSITION_TYPE_BUY)
                {
                    tpPrice = avgPrice + (_basketAvgTpPoints * _Point);
                }
                else
                {
                    tpPrice = avgPrice - (_basketAvgTpPoints * _Point);
                }

                _trade.PositionModify(ticket, _position.StopLoss(), tpPrice);
            }
        }
    }

    void _UpdateAvgSlForBasketTrades()
    {
        if (Count() == 0 || _basketAvgTpPoints == 0)
            return;

        double avgPrice = AverageOpenPrice();
        for (int i = Count() - 1; i >= 0; i--)
        {
            ulong ticket = _trades[i].Ticket();
            if (_position.SelectByTicket(ticket))
            {
                double slPrice = 0;

                if (_position.PositionType() == POSITION_TYPE_BUY)
                {
                    slPrice = avgPrice - (_basketAvgTpPoints * _Point);
                }
                else
                {
                    slPrice = avgPrice + (_basketAvgTpPoints * _Point);
                }

                _trade.PositionModify(ticket, slPrice, _position.TakeProfit());
            }
        }
    }
};