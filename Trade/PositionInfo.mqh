#include <Object.mqh>

#property strict

#ifdef __MQL4__

enum ENUM_POSITION_TYPE
{
   POSITION_TYPE_BUY = 0,  // Buy
   POSITION_TYPE_SELL = 1, // Sell
};

class CPositionInfo : public CObject
{

public:
   bool SelectByIndex(const int index);
   bool SelectByMagic(const int magic);
   bool SelectByTicket(const ulong ticket);
   ulong PositionGetTicket(int index);

public:
   string Symbol(void) { return OrderSymbol(); }
   string Comment(void) { return OrderComment(); }
   int Magic() { return (OrderMagicNumber()); }
   virtual ENUM_POSITION_TYPE PositionType() { return ((ENUM_POSITION_TYPE)OrderType()); }
   double PriceOpen() { return (OrderOpenPrice()); }
   double StopLoss() { return (OrderStopLoss()); }
   double TakeProfit() { return (OrderTakeProfit()); }
   int Ticket() { return (OrderTicket()); }
   double Volume() { return OrderLots(); }
   datetime Time(void) { return OrderOpenTime(); }
   double Commission() { return OrderCommission(); }
   double Swap() { return OrderSwap(); }
   double Profit() { return OrderProfit(); }
   double PriceCurrent() { return OrderType() == ORDER_TYPE_BUY ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK); }
};

bool CPositionInfo::SelectByIndex(const int index)
{

   if (!OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
      return (false);
   if (OrderType() != ORDER_TYPE_BUY && OrderType() != ORDER_TYPE_SELL)
      return (false);
   if (OrderCloseTime() > 0)
      return (false);
   return (OrderTicket() > 0);
}

bool CPositionInfo::SelectByMagic(const int magic)
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         return (false);
      if (OrderType() != ORDER_TYPE_BUY && OrderType() != ORDER_TYPE_SELL)
         return (false);
      if (OrderCloseTime() > 0)
         return (false);
      if (OrderMagicNumber() != magic)
         return (false);
      return (OrderTicket() > 0);
   }

   return false;
}

bool CPositionInfo::SelectByTicket(const ulong ticket)
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         return (false);
      if (OrderType() != ORDER_TYPE_BUY && OrderType() != ORDER_TYPE_SELL)
         return (false);
      if (OrderCloseTime() > 0)
         return (false);
      if (OrderTicket() > 0 && OrderTicket() != ticket)
         return (false);
      return (OrderTicket() > 0);
   }
   return false;
}

ulong CPositionInfo::PositionGetTicket(int index)
{

   if (!OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
      return (false);
   if (OrderType() != ORDER_TYPE_BUY && OrderType() != ORDER_TYPE_SELL)
      return (false);
   if (OrderCloseTime() > 0)
      return (false);
   return (OrderTicket());
}

enum ENUM_POSITION_PROPERTY_DOUBLE
{
   POSITION_SWAP,  // Cumulative swap
   POSITION_PROFIT // Current profit
};
double PositionGetDouble(ENUM_POSITION_PROPERTY_DOUBLE property)
{
   switch (property)
   {
   case POSITION_PROFIT:
      return OrderProfit();
   case POSITION_SWAP:
      return OrderSwap();
   default:
      return 0;
   }
}

bool PositionSelectByTicket(ulong ticket)
{
   return OrderSelect((int)ticket, SELECT_BY_TICKET, MODE_TRADES);
}

enum ENUM_POSITION_PROPERTY_STRING
{
   POSITION_SYMBOL,  // Symbol of the position
   POSITION_COMMENT, // Position comment
};
string PositionGetString(ENUM_POSITION_PROPERTY_STRING property)
{
   switch (property)
   {
   case POSITION_SYMBOL:
      return OrderSymbol();
   case POSITION_COMMENT:
      return OrderComment();
   default:
      return "";
   }
}

enum ENUM_POSITION_PROPERTY_INTEGER
{
   POSITION_TICKET, // Position ticket. Unique number assigned to each newly opened position. It usually matches the ticket of an order used to open the position except when the ticket is changed as a result of service operations on the server, for example, when charging swaps with position re-opening. To find an order used to open a position, apply the POSITION_IDENTIFIER property.
   POSITION_MAGIC,  // Position magic number (see ORDER_MAGIC)
   POSITION_TYPE,   // Position type
};

int PositionGetInteger(ENUM_POSITION_PROPERTY_INTEGER property)
{
   switch (property)
   {
   case POSITION_TICKET:
      return OrderTicket();
   case POSITION_MAGIC:
      return OrderMagicNumber();
   case POSITION_TYPE:
      return (ENUM_POSITION_TYPE)OrderType();
   default:
      return -1;
   }
}
#endif

#ifdef __MQL5__
#include <Trade/Trade.mqh>
#endif