#property strict

#include <Object.mqh>;
#include "..\Common\Defines.mqh";
#include "..\Common\Utils.mqh";
#include "PositionInfoCustom.mqh";
#include "..\Recovery\RecoveryManager.mqh";
#include "TradeCustom.mqh";

#ifdef __MQL4__
  #include "Trade_mql4.mqh";
#endif

#ifdef __MQL5__
  #include <Trade/Trade.mqh>
#ifndef ERR_REQUOTE
   #define ERR_REQUOTE TRADE_RETCODE_REQUOTE
#endif 
#endif

class CTradeManager : public CObject {

private:
   CUtils                           *utils;
   CPositionInfoCustom              *mPositionInfo;
   CLotSizeCalculatorBase           *mLotSizeCalculator;
#ifdef RECOVERY_EA   
   CRecoveryManager                 *mRecoveryManager;
#endif    
   CTradeCustom                     trade;
   
   
private:   
   ulong OpenTrade(ENUM_ORDER_TYPE order, double price, int slPoints, int tpPoints, 
                     datetime expiration=0);
   ulong OpenTradeByPrice(ENUM_ORDER_TYPE order, double price, double lotSize, double sl, double tp);
                     
   
   void UpdateSLForOrder(double newSLPrice);
   
   void TrailStopOrders(ENUM_ORDER_TYPE type=-1);
   void BreakEvenOrders(ENUM_ORDER_TYPE type=-1);

protected:

public:
   CTradeManager(CLotSizeCalculatorBase *lotSizeCalc, CPositionInfoCustom *positionInfoCustom,
                 CRecoveryManager *recoveryManager);
   ~CTradeManager();

public:

#ifdef __MQL5__
   void RefreshRates();
#endif

 void  SetExpertMagicNumber(int magic);
 
 ulong OpenBuy(const double price, const int slPoints, const int tpPoints=0); 
 ulong OpenBuy(const double price, const double slPrice, const double tpPrice=0); 
 ulong OpenBuyStop(const int points, const int slPoints, const int tpPoints=0);
 ulong OpenBuyLimit(const int points, const int slPoints, const int tpPoints=0);
 ulong OpenBuyStop(const double price, const double slPrice, const double tpPrice);
 ulong OpenBuyLimit(const double price, const double slPrice, const double tpPrice);
 ulong OpenBuyStop(const double price, const double lots, const double slPrice, const double tpPrice);
 ulong OpenBuyLimit(const double price, const double lots, const double slPrice, const double tpPrice);


 
 ulong OpenSell(const double price, const int slPoints, const int tpPoints=0);
 ulong OpenSell(const double price, const double slPrice, const double tpPrice=0); 
 ulong OpenSellStop(const int points, const int slPoints, const int tpPoints=0);
 ulong OpenSellLimit(const int points, const int slPoints, const  int tpPoints=0);
 ulong OpenSellStop(const double price, const double slPrice, const double tpPrice);
 ulong OpenSellLimit(const double price, const double slPrice, const double tpPrice);
 ulong OpenSellStop(const double price, const double lots, const double slPrice, const double tpPrice);
 ulong OpenSellLimit(const double price, const double lots, const double slPrice, const double tpPrice);

 bool HasOpenOrder(ENUM_ORDER_TYPE type=-1);
 bool HasOpenPendingOrder(ENUM_ORDER_TYPE type=-1);
 bool CloseAllTradesOfType(ENUM_ORDER_TYPE type=-1);
 bool DeletePendingOrders(ENUM_ORDER_TYPE type=-1);
 bool OrderDelete(ulong ticket);
 bool CloseTrade(ulong ticket);
 
 void OnTick();
 
};

#ifdef  __MQL5__
   void CTradeManager::RefreshRates() {
      
   }
#endif 

void CTradeManager::SetExpertMagicNumber(int magic) {
   trade.SetExpertMagicNumber(magic);
}

ulong CTradeManager::OpenTradeByPrice(ENUM_ORDER_TYPE order, double price, double lotSize, double slPrice, double tpPrice) {
   ulong ticket = -1;
   
   double _slPrice = slPrice;

#ifdef RECOVERY_EA   
   mRecoveryManager.SetStopLossIfRecovery(_slPrice);
#endif 

   ticket = trade.OpenPosition(utils._TheSymbol(), (ENUM_ORDER_TYPE)order, lotSize, price, 0, _slPrice, tpPrice, EAComment);
   if(ticket == -1) {
      return ticket;
   }

#ifdef RECOVERY_EA
   mRecoveryManager.OpenPosition(ticket, price, slPrice, lotSize);
#endif   
   return ticket;
}

void CTradeManager::OnTick(void) {
   CTradeManager::BreakEvenOrders();
   CTradeManager::TrailStopOrders();
#ifdef RECOVERY_EA   
   mRecoveryManager.OnTick();   
#endif   
}

bool CTradeManager::DeletePendingOrders(ENUM_ORDER_TYPE type=-1) {
   bool result = true;
   utils.LogVerbose(__FUNCTION__, "Deleting all pending trades, recalculating profit/loss");
   int pendingOrderCount = mPositionInfo.TotalPending(utils._TheSymbol(), MagicNumber);
   for(int i=pendingOrderCount-1;i>=0;i--) {
       if(!mPositionInfo.SelectPendingByIndex(i)) continue;
       ulong ticket = mPositionInfo.GetPendingTicketByIndex(i, type);
       if(ticket <= 0) continue;         
       result &= OrderDelete(ticket);                
   }

   //Update closed trades profit
   mPositionInfo.ReCalculateHistoryProfit(utils._TheSymbol(), MagicNumber);   
   return result;
}

bool CTradeManager::CloseAllTradesOfType(ENUM_ORDER_TYPE type=-1){
   bool result = true;
   utils.LogVerbose(__FUNCTION__, "Closing all open trades, recalculating profit/loss");
   
   for(int i=mPositionInfo.Total(utils._TheSymbol(), MagicNumber)-1;i>=0;i--) {
       if(!mPositionInfo.SelectByIndex(i)) continue;
       if(mPositionInfo.PositionType() != (int)ORDER_TYPE_BUY && mPositionInfo.PositionType() != (int)ORDER_TYPE_SELL) continue;
       if(type != -1 && mPositionInfo.PositionType() != type) continue;         
       result &= CloseTrade(mPositionInfo.PositionTicket());                
   }

   //Update closed trades profit
   mPositionInfo.ReCalculateHistoryProfit(utils._TheSymbol(), MagicNumber);   
   return result;
}

//Close order by ticket
bool CTradeManager::CloseTrade(ulong ticket) {
   if(ticket > 0) {
      if(mPositionInfo.SelectByTicket(ticket)) {
         if(mPositionInfo.Magic() != MagicNumber || mPositionInfo.Symbol() != utils._TheSymbol()) return false; 
         
         RefreshRates();
         
         double price = mPositionInfo.PositionType() == (int)ORDER_TYPE_BUY ? utils.BuyPrice() : utils.SellPrice();
         
         if(!mPositionInfo.IsClosed(ticket)) {
            for(int i=0;i<MAX_RETRIES;i++) {
               if(trade.PositionClose((int)ticket)) {//, mPositionInfo.Volume(), price, MaxSlippage
                  return true;
               } else {
                  if(GetLastError() == ERR_REQUOTE) RefreshRates();              
                  utils.LogError(__FUNCTION__, StringFormat("Failed to close order #%i, retry %d of %d", ticket, i, MAX_RETRIES));
               }
            }
            
            return (false);
         }
         return (false);
      } else {
         return false;
      }
   }
   
   return false;
}

// Delete pending order
bool CTradeManager::OrderDelete(ulong ticket) {
   for(int i=0;i<MAX_RETRIES;i++) {
      if(trade.OrderDelete(ticket)) {
         return true;
      } else {                  
         utils.LogError(__FUNCTION__, StringFormat("Failed to delete order #%i, retry %d of %d", ticket, i, MAX_RETRIES));
      }
   }
   return false;
}

bool CTradeManager::HasOpenOrder(ENUM_ORDER_TYPE type=-1) {
   for(int i=mPositionInfo.Total(utils._TheSymbol(), MagicNumber)-1;i>=0; i--) {
      if(mPositionInfo.SelectByIndex(i)){
         if(mPositionInfo.Magic() != MagicNumber || mPositionInfo.Symbol() != utils._TheSymbol()) continue;   
         ulong ticket = mPositionInfo.PositionTicket();
         ENUM_ORDER_TYPE orderType = mPositionInfo.PositionType();
         bool isClosed = mPositionInfo.IsClosed(ticket);
         if(!isClosed && (type == -1 || orderType == type)) return (true);
      }
   }
   
   return false;
}

bool CTradeManager::HasOpenPendingOrder(ENUM_ORDER_TYPE type=-1) {
   for(int i=mPositionInfo.TotalPending(utils._TheSymbol(), MagicNumber);i>=0; i--) {
      if(mPositionInfo.SelectByIndex(i)){
         if(mPositionInfo.Magic() != MagicNumber || mPositionInfo.Symbol() != utils._TheSymbol()) continue;        
         if((type == -1 || mPositionInfo.OrderType() == type)) return (true);
      }
   }
   
   return false;
}

void CTradeManager::BreakEvenOrders(ENUM_ORDER_TYPE type=-1) {
   if(BEMode == TP_MODE_DISABLED) return;
   
   for(int o=mPositionInfo.Total(utils._TheSymbol(), MagicNumber);o>=0;o--) {
     if(!mPositionInfo.SelectByIndex(o)) continue;
     if(mPositionInfo.Magic() != MagicNumber || mPositionInfo.Symbol() != utils._TheSymbol()) continue; 
      if(type != -1 && mPositionInfo.PositionType() != type) continue;
      if(mPositionInfo.IsClosed(mPositionInfo.PositionTicket()) || (mPositionInfo.PositionType() != (int)ORDER_TYPE_BUY && mPositionInfo.PositionType() != (int)ORDER_TYPE_SELL)) continue;
     
      //If we already BE or TS, or order not in profit do nothing
      if(mPositionInfo.StopLoss() >= mPositionInfo.PriceOpen() || mPositionInfo.Profit() < 0) continue;
      
      double swap          = mPositionInfo.Swap();
      double commission    = mPositionInfo.Commission();
      
      double csValue       = (swap + commission) / utils._PointValue();
      int scPoints         = (int)MathCeil(csValue / utils._ThePoint());
      
      switch(BEMode) {
         case TP_MODE_POINTS: {
            int profitPoints = (int)MathFloor(mPositionInfo.Profit() / (utils._TickValue() * mPositionInfo.Volume()));
            int bePoints = (int)BEValue + scPoints;               
            if(profitPoints > bePoints) {
               if(mPositionInfo.PositionType() == ORDER_TYPE_BUY) {
                  UpdateSLForOrder(mPositionInfo.PriceOpen() + (scPoints*utils._ThePoint()));
               } else if (mPositionInfo.PositionType() == (int)ORDER_TYPE_SELL) {
                  UpdateSLForOrder(mPositionInfo.PriceOpen() - (scPoints*utils._ThePoint()));
               }
            } 
         }
         case TP_MODE_RR: {
            int profitPoints = (int)MathFloor(mPositionInfo.Profit() / (utils._TickValue() * mPositionInfo.Volume()));
            int slPoints = (int)MathCeil(mPositionInfo.StopLoss() / utils._ThePoint());
            int rrPoints = (int)MathCeil(slPoints * BEValue);               
            if(profitPoints > rrPoints) {
               if(mPositionInfo.PositionType() == (int)ORDER_TYPE_BUY) {
                  UpdateSLForOrder(mPositionInfo.PriceOpen() + (scPoints*utils._ThePoint()));
               } else if (mPositionInfo.PositionType() == ORDER_TYPE_SELL) {
                  UpdateSLForOrder(mPositionInfo.PriceOpen() - (scPoints*utils._ThePoint()));
               }
            }
         }   
      }       
   }   
}

void CTradeManager::TrailStopOrders(ENUM_ORDER_TYPE type=-1) {
   if(!EnableTS) return;
   
   for(int o=mPositionInfo.Total(utils._TheSymbol(), MagicNumber)-1;o>=0;o--) {
      if(!mPositionInfo.SelectByIndex(o)) continue;
      if(mPositionInfo.Magic() != MagicNumber || mPositionInfo.Symbol() != utils._TheSymbol()) continue; 
      if(type != -1 && mPositionInfo.PositionType() != type) continue;
      if(mPositionInfo.IsClosed(mPositionInfo.PositionTicket()) || (mPositionInfo.PositionType() != (int)ORDER_TYPE_BUY && mPositionInfo.PositionType() != (int)ORDER_TYPE_SELL)) continue;
      
      double tsValue = NormalizeDouble(TSPoints*utils._ThePoint(), utils._TheDigits());
      double tsStartValue = NormalizeDouble(TSAfterPoints*utils._ThePoint(), utils._TheDigits());
      double tsStep = NormalizeDouble(TSStep*utils._ThePoint(), utils._TheDigits());         
      
      RefreshRates();
      
      double price         = mPositionInfo.PriceCurrent();
      double openPrice     = mPositionInfo.PriceOpen();  
      double slPrice       = mPositionInfo.StopLoss();
      double tsWithStep    = (tsValue + tsStep);
           

      if(mPositionInfo.PositionType() == ORDER_TYPE_BUY) {
         if(price - openPrice > tsWithStep) {
            if(slPrice < (price - tsWithStep) || slPrice == 0) {
               double newSLPrice = price - tsValue;    
               newSLPrice = NormalizeDouble(newSLPrice, utils._TheDigits());
               UpdateSLForOrder(newSLPrice);
            }
         }              
      } else 
      if(mPositionInfo.PositionType() == ORDER_TYPE_SELL) {
         if(openPrice - price > tsWithStep) {
            if(slPrice > (price + tsWithStep) || slPrice == 0) {
               double newSLPrice = price + tsValue;    
               newSLPrice = NormalizeDouble(newSLPrice, utils._TheDigits());
               UpdateSLForOrder(newSLPrice);
            }
         }              
      } 
   }   
}


// ================================

// ===== Buy
ulong CTradeManager::OpenBuy(const double price, const int slPoints, const int tpPoints=0) {
   return OpenTrade(ORDER_TYPE_BUY, price, slPoints, tpPoints);
}

ulong CTradeManager::OpenBuy(const double price, const double slPrice, const double tpPrice=0) {
   double lotSize = mLotSizeCalculator.CalculateLotSize(price, slPrice);
   return OpenTradeByPrice(ORDER_TYPE_BUY, price, lotSize, slPrice, tpPrice);
}

ulong CTradeManager::OpenBuyStop(const int points, const int slPoints, const int tpPoints=0) {
   double openPrice = NormalizeDouble(utils.BuyPrice() + (points * utils._ThePoint()), utils._TheDigits());
   return OpenTrade(ORDER_TYPE_BUY_STOP, openPrice, slPoints, tpPoints);
}

ulong CTradeManager::OpenBuyLimit(const int points, const int slPoints, const int tpPoints=0) {
   double openPrice = NormalizeDouble(utils.BuyPrice() - (points * utils._ThePoint()), utils._TheDigits());
   return OpenTrade(ORDER_TYPE_BUY_LIMIT, openPrice, slPoints, tpPoints);
}

ulong CTradeManager::OpenBuyStop(const double price, const double slPrice, const double tpPrice) {
   double lotSize = mLotSizeCalculator.CalculateLotSize(price, slPrice);
   return OpenTradeByPrice(ORDER_TYPE_BUY_STOP, price, lotSize, slPrice, tpPrice);
}

ulong CTradeManager::OpenBuyLimit(const double price, const double slPrice, const double tpPrice) {
   double lotSize = mLotSizeCalculator.CalculateLotSize(price, slPrice);
   return OpenTradeByPrice(ORDER_TYPE_BUY_LIMIT, price, lotSize, slPrice, tpPrice);
}

ulong CTradeManager::OpenBuyStop(const double price, const double lots, const double slPrice, const double tpPrice) {
   return OpenTradeByPrice(ORDER_TYPE_BUY_STOP, price, lots, slPrice, tpPrice);
}

ulong CTradeManager::OpenBuyLimit(const double price, const double lots, const double slPrice, const double tpPrice) {
   return OpenTradeByPrice(ORDER_TYPE_BUY_LIMIT, price, lots, slPrice, tpPrice);
}
// ===== Sell

ulong CTradeManager::OpenSell(const double price,const int slPoints,const int tpPoints) {
   return OpenTrade(ORDER_TYPE_SELL, price, slPoints, tpPoints);
}

ulong CTradeManager::OpenSell(const double price, const double slPrice, const double tpPrice=0) {
   double lotSize = mLotSizeCalculator.CalculateLotSize(price, slPrice);
   return OpenTradeByPrice(ORDER_TYPE_SELL, price, lotSize, slPrice, tpPrice);
}

ulong CTradeManager::OpenSellStop(const int points, const int slPoints, const int tpPoints=0) {
   double openPrice = NormalizeDouble(utils.SellPrice() - (points * utils._ThePoint()), utils._TheDigits());
   return OpenTrade(ORDER_TYPE_SELL_STOP, openPrice, slPoints, tpPoints);
}

ulong CTradeManager::OpenSellLimit(const int points, const int slPoints, const int tpPoints=0) {
   double openPrice = NormalizeDouble(utils.SellPrice() + (points * utils._ThePoint()), utils._TheDigits());
   return OpenTrade(ORDER_TYPE_SELL_LIMIT, openPrice, slPoints, tpPoints);
}

ulong CTradeManager::OpenSellStop(const double price, const double slPrice, const double tpPrice) {
   double lotSize = mLotSizeCalculator.CalculateLotSize(price, slPrice);
   return OpenTradeByPrice(ORDER_TYPE_SELL_STOP, price, lotSize, slPrice, tpPrice);
}

ulong CTradeManager::OpenSellLimit(const double price, const double slPrice, const double tpPrice) {
   double lotSize = mLotSizeCalculator.CalculateLotSize(price, slPrice);
   return OpenTradeByPrice(ORDER_TYPE_SELL_LIMIT, price, lotSize, slPrice, tpPrice);
}

ulong CTradeManager::OpenSellStop(const double price, const double lots, const double slPrice, const double tpPrice) {   
   return OpenTradeByPrice(ORDER_TYPE_SELL_STOP, price, lots, slPrice, tpPrice);
}

ulong CTradeManager::OpenSellLimit(const double price, const double lots, const double slPrice, const double tpPrice) {
   return OpenTradeByPrice(ORDER_TYPE_SELL_LIMIT, price, lots, slPrice, tpPrice);
}
// =======

ulong CTradeManager::OpenTrade(ENUM_ORDER_TYPE order, double price, int slPoints, int tpPoints, 
                              datetime expiration=0) {
   double slPrice = 0;
   double tpPrice = 0;
   
   switch(order) {
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_BUY_STOP:
      case ORDER_TYPE_BUY_LIMIT:
         if(slPoints > 0) {
            slPrice = price - (slPoints * utils._ThePoint()); 
         }
         
         if(tpPoints > 0) {
            tpPrice = price + (tpPoints * utils._ThePoint());
         }       
        break;
      case ORDER_TYPE_SELL:
      case ORDER_TYPE_SELL_STOP:
      case ORDER_TYPE_SELL_LIMIT:
         if(slPoints > 0) {
            slPrice = price + (slPoints * utils._ThePoint());   
         }
         
         if(tpPoints > 0) {
            tpPrice = price - (tpPoints * utils._ThePoint());
         }     
        break;
   }
   
   double lotSize = mLotSizeCalculator.CalculateLotSize(slPoints, order);
   utils.Log(StringFormat("opening trade %i at %f lot= %f, sl =%f, tp=%f", order, price, lotSize, slPrice, tpPrice));
   return OpenTradeByPrice(order, price, lotSize, slPrice, tpPrice);
   
}

void CTradeManager::UpdateSLForOrder(double newSLPrice) {
   if(mPositionInfo.PositionTicket() <= 0 || mPositionInfo.IsClosed(mPositionInfo.PositionTicket())) return;
   for(int i=0;i<MAX_RETRIES;i++) {
      if(trade.PositionModify(mPositionInfo.PositionTicket(), newSLPrice, mPositionInfo.TakeProfit())) {
         break; 
      } else {
         if(GetLastError() == ERR_REQUOTE) RefreshRates();              
         utils.LogError(__FUNCTION__, StringFormat("Failed to modify order, retry %d of %d", i, MAX_RETRIES));
      }
   }
}


CTradeManager::CTradeManager(CLotSizeCalculatorBase *lotSizeCalc, CPositionInfoCustom *positionInfoCustom,
                             CRecoveryManager *recoveryManager) {

   utils                   = new CUtils();                           
   mLotSizeCalculator      = lotSizeCalc;
   mPositionInfo           = positionInfoCustom;   
#ifdef RECOVERY_EA   
   mRecoveryManager        = recoveryManager;
#endif    
}

CTradeManager::~CTradeManager() {
   SafeDeletePointer(mLotSizeCalculator);
   SafeDeletePointer(utils);
   SafeDeletePointer(mPositionInfo);
#ifdef RECOVERY_EA   
   SafeDeletePointer(mRecoveryManager); 
#endif    
}