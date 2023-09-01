#property strict

struct Trade
{
private:
    ulong _ticket;
    long _magicNumber;
    string _symbol;
    ENUM_ORDER_TYPE _orderType;
    double _openPrice;
    double _volume;
    double _fees;
    double _sLPrice;
    double _tPPrice;
    double _virtualSLPrice;
    double _virtualTPPrice;
    string _comment;

public:
    void Init(ulong ticket, long magicNumber, string symbol,
              ENUM_ORDER_TYPE orderType, double openPrice,
              double volume, double fees, double sLPrice,
              double tPPrice, string comment)
    {
        _ticket = ticket;
        _magicNumber = magicNumber;
        _symbol = symbol;
        _orderType = orderType;
        _openPrice = openPrice;
        _volume = volume;
        _fees = fees;
        _sLPrice = sLPrice;
        _tPPrice = tPPrice;
        _virtualSLPrice = sLPrice;
        _virtualTPPrice = tPPrice;
        _comment = comment;
    }

public:
    ulong Ticket() const { return _ticket; }
    long MagicNumber() const { return _magicNumber; }
    string Symbol() const { return _symbol; }
    ENUM_ORDER_TYPE OrderType() const { return _orderType; }
    double OpenPrice() const { return _openPrice; }
    double Volume() const { return _volume; }
    double Fees() const { return _fees; }
    double StopLoss() const { return _sLPrice; }
    double TakeProfit() const { return _tPPrice; }
    double VirtualStopLoss() const { return _virtualSLPrice; }
    double VirtualTakeProfit() const { return _virtualTPPrice; }
    string Comment() const { return _comment; }

    void SwitchToVirtualSLTP()
    {
        _virtualSLPrice = _sLPrice;
        _virtualTPPrice = _tPPrice;        
        _sLPrice = _tPPrice = 0;
    }
    
};