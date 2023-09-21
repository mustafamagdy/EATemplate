#property strict
#ifdef __MQL5__
#include <Trade\Trade.mqh>
#endif

#ifdef __MQL4__
#include "Trade_mql4.mqh"
#endif

#include "..\UI\Reporter.mqh"
#include "..\Common.mqh"
#include "..\Constants.mqh"

class CTradeCustom : public CTrade
{
private:
   CReporter *_reporter;
   CConstants *_constants;
   string pSymbol;

public:
   CTradeCustom(string symbol, CReporter *reporter, CConstants *constants)
   {
      _reporter = reporter;
      _constants = constants;
      pSymbol = symbol;
   }

   ~CTradeCustom()
   {
   }

public:
   ulong OpenPosition(const string symbol, const ENUM_ORDER_TYPE order_type, const double volume,
                      const double price, const int slippage, const double sl, const double tp,
                      const string comment = "", datetime expiration = 0);
};

ulong CTradeCustom::OpenPosition(const string symbol, const ENUM_ORDER_TYPE order_type, const double volume,
                                 const double price, const int slippage, const double sl, const double tp,
                                 const string comment = "", datetime expiration = 0)
{
   ulong ticket = -1;
   for (int i = 0; i < MAX_RETRIES; i++)
   {

      bool openResult = false;
#ifdef __MQL5__
      ENUM_ORDER_TYPE_TIME expirationTime = 0;
      if (expiration != 0)
      {
         expirationTime = ORDER_TIME_SPECIFIED;
      }
#else
      int expirationTime = 0;
#endif

      switch (order_type)
      {
      case ORDER_TYPE_BUY_STOP:
         openResult = BuyStop(volume, price, pSymbol, sl, tp, expirationTime, expiration, comment);
         break;
      case ORDER_TYPE_SELL_STOP:
         openResult = SellStop(volume, price, pSymbol, sl, tp, expirationTime, expiration, comment);
         break;
      case ORDER_TYPE_BUY_LIMIT:
         openResult = BuyLimit(volume, price, pSymbol, sl, tp, expirationTime, expiration, comment);
         break;
      case ORDER_TYPE_SELL_LIMIT:
         openResult = SellLimit(volume, price, pSymbol, sl, tp, expirationTime, expiration, comment);
         break;
      default:
#ifdef __MQL4__
         openResult = PositionOpen(pSymbol, (ENUM_ORDER_TYPE)order_type, volume, price, 0, sl, tp, comment);
#else
         openResult = PositionOpen(pSymbol, (ENUM_ORDER_TYPE)order_type, volume, price, sl, tp, comment);
#endif
         break;
      }

      if (!openResult)
      {
         _reporter.ReportError(StringFormat(" Failed to open order %d Lot %g at price %g [account balance %g - margin %g - leverage %d]",
                                            EnumToString(order_type), volume, price, _constants.AccountBalance(), _constants.AccountFreeMargin(), _constants.AccountLeverage()));
      }
      else
      {
         MqlTradeResult tradeResult;

         Result(tradeResult);

         if (tradeResult.retcode == TRADE_RETCODE_DONE)
         {
            ticket = tradeResult.order;
         }
         break;
      }
   }

   return (ticket);
}