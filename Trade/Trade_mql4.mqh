#property strict

#include <Object.mqh>;

enum ENUM_TRADE_RETCODES
{
  TRADE_RETCODE_INVALID = 10013, // Invalid request
  TRADE_RETCODE_DONE = 10009,    // Done
};

struct MqlTradeResult
{
  uint retcode;          // Operation return code
  ulong deal;            // Deal ticket, if it is performed
  ulong order;           // Order ticket, if it is placed
  double volume;         // Deal volume, confirmed by broker
  double price;          // Deal price, confirmed by broker
  double bid;            // Current Bid price
  double ask;            // Current Ask price
  string comment;        // Broker comment to operation (by default it is filled by description of trade server return code)
  uint request_id;       // Request ID set by the terminal during the dispatch
  uint retcode_external; // Return code of an external trading system
  string symbol;         // Symbol
  double sl;             // Stop loss
  double tp;             // Take profit 
};

class CTrade : public CObject
{

private:
protected:
  int m_magic;             // Expert Magic Number
  MqlTradeResult m_result; // Result data

public:
  void ClearStructures(void);
  void Result(MqlTradeResult &result);

public:
  CTrade();
  ~CTrade();

public:
  string RequestSymbol() { return m_result.symbol; }
  long RequestMagic() { return m_magic; }
  double RequestSL() { return m_result.sl;  }
  double RequestTP() { return m_result.tp; }
  
public:
  void SetExpertMagicNumber(const int magicNumber) { m_magic = magicNumber; }
  bool PositionOpen(const string symbol, const ENUM_ORDER_TYPE order_type, const double volume,
                    const double price, const double sl, const double tp, const string comment);
  bool BuyLimit(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
                const int type_time = 0, const datetime expiration = 0, const string comment = "");
  bool BuyStop(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
               const int type_time = 0, const datetime expiration = 0, const string comment = "");
  bool SellLimit(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
                 const int type_time = 0, const datetime expiration = 0, const string comment = "");
  bool SellStop(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
                const int type_time = 0, const datetime expiration = 0, const string comment = "");
  bool PositionClose(const ulong ticket, long diviation = ULONG_MAX);
  bool OrderDelete(const ulong ticket);
  bool PositionModify(const ulong ticket, const double sl, const double tp);
};

CTrade::CTrade()
{
}

CTrade::~CTrade()
{
}

bool CTrade::PositionOpen(const string symbol, const ENUM_ORDER_TYPE order_type, const double volume,
                          const double price, const double sl, const double tp, const string comment)
{

  ClearStructures();

  if (order_type != ORDER_TYPE_BUY && order_type != ORDER_TYPE_SELL)
  {
    m_result.retcode = TRADE_RETCODE_INVALID;
    m_result.comment = "Invalid order type";
    return (false);
  }

  ulong ticket = OrderSend(symbol, order_type, volume, price, 0, sl, tp, comment, m_magic);
  if (ticket > 0)
  {
    m_result.order = ticket;
    m_result.symbol = symbol;
    m_result.retcode = TRADE_RETCODE_DONE;
  }

  return (ticket > 0);
}

bool CTrade::BuyLimit(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
                      const int type_time = 0, const datetime expiration = 0, const string comment = "")
{
  return PositionOpen(symbol, ORDER_TYPE_BUY_LIMIT, volume, price, sl, tp, comment);
}
bool CTrade::BuyStop(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
                     const int type_time = 0, const datetime expiration = 0, const string comment = "")
{
  return PositionOpen(symbol, ORDER_TYPE_BUY_STOP, volume, price, sl, tp, comment);
}
bool CTrade::SellLimit(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
                       const int type_time = 0, const datetime expiration = 0, const string comment = "")
{
  return PositionOpen(symbol, ORDER_TYPE_SELL_LIMIT, volume, price, sl, tp, comment);
}
bool CTrade::SellStop(const double volume, const double price, const string symbol, const double sl = 0.0, const double tp = 0.0,
                      const int type_time = 0, const datetime expiration = 0, const string comment = "")
{
  return PositionOpen(symbol, ORDER_TYPE_BUY_STOP, volume, price, sl, tp, comment);
}

bool CTrade::PositionClose(const ulong ticket, long diviation = ULONG_MAX)
{
  return OrderClose((int)ticket, OrderLots(), OrderType() == ORDER_TYPE_BUY ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK), 0);
}

bool CTrade::OrderDelete(const ulong ticket)
{
  return OrderDelete(ticket);
}

bool CTrade::PositionModify(const ulong ticket, const double sl, const double tp)
{
  return OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0);
}
void CTrade::ClearStructures()
{
  ZeroMemory(m_result);
}

void CTrade::Result(MqlTradeResult &result)
{
  result.order = m_result.order;
  result.retcode = m_result.retcode;
}
