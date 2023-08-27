#include "..\RiskManagement\LotSizeCalculatorBase.mqh";
#include "..\RiskManagement\NormalLotSizeCalculator.mqh";
#include "..\Constants.mqh";
#include "..\Enums.mqh";

#property strict

/*
   To calculate the recovery for a grid, we need to know the following:
      - The last order of type, lot size
      - The max lot size opened for an order type    
*/
class CRecoveryLotSizeCalculator : public CLotSizeCalculatorBase {

private:   
   CNormalLotSizeCalculator   *mNormalLotSizeCalc;
   ENUM_RECOVERY_LOT_SIZE_MODE _recoveryLotSizeMode;
   double _recoveryFixedLotSize;
   string _recoveryLotSeries;
   ENUM_RECOVERY_FIXED_CUSTOM_MODE _martingalCustomLotMode;

private:
   double CalculateNextLot(string symbol, string series, int lastOrderNumber, bool rolling);
   double CalculateNextLotMultiplier(string symbol, double lastLot, string series, int lastOrderNumber);
   
protected:

public:
   CRecoveryLotSizeCalculator(CNormalLotSizeCalculator *normalLotSizeCalc);
   ~CRecoveryLotSizeCalculator();
      
public:
   double CalculateLotSize(string symbol, const int riskPoints, const ENUM_ORDER_TYPE orderType);
   double CalculateLotSize(string symbol, const double openPrice, const double slPrice, ENUM_ORDER_TYPE orderType);
   double CalculateLotSize(string symbol, const int riskPoints, double lastLot, int orderCount, const ENUM_ORDER_TYPE orderType);
};


double CRecoveryLotSizeCalculator::CalculateLotSize(string symbol, const int riskPoints, double lastLot, int orderCount, const ENUM_ORDER_TYPE orderType) {
   //For the first order, use the normal method
   if(orderCount == 0) {      
      double normalLot = mNormalLotSizeCalc.CalculateLotSize(symbol, riskPoints, orderType);     
      return normalLot;
   }
   
   int count = 0;
   if(orderCount > 1) {
      count = orderCount - 1;//Ignore the first order (orignal order)
   }
      
   switch(_recoveryLotSizeMode) {
      case RECOVERY_LOT_FIXED: return NormalizeLot(symbol, _recoveryFixedLotSize);
      case RECOVERY_LOT_ADD: return NormalizeLot(symbol, lastLot + _recoveryFixedLotSize);
      case RECOVERY_LOT_FIXED_CUSTOM: {
         switch(_martingalCustomLotMode) {
            case RECOVERY_LOT_CUSTOM_SERIES: {
                 double nextLotInSeries = CalculateNextLot(symbol, _recoveryLotSeries, count, false);
                 return NormalizeLot(symbol, nextLotInSeries);
            }
            case RECOVERY_LOT_CUSTOM_ROLLING: {
                 double nextLotInSeries = CalculateNextLot(symbol, _recoveryLotSeries, count, true);
                 return NormalizeLot(symbol, nextLotInSeries);
            }
            case RECOVERY_LOT_CUSTOM_MULTIPLIER: {
                 double nextLotInSeries = CalculateNextLotMultiplier(symbol, lastLot, _recoveryLotSeries, count);
                 return NormalizeLot(symbol, nextLotInSeries);
            }
         }
      }
   }
     
   return constants.MinLot(symbol);
}

double CRecoveryLotSizeCalculator::CalculateLotSize(string symbol, const double openPrice, const double slPrice, const ENUM_ORDER_TYPE orderType) {
   int points = (int)MathFloor(NormalizeDouble(MathAbs(openPrice-slPrice), _Digits) / _Point);
   return CalculateLotSize(symbol, points, 0, 0, orderType);   
}

double CRecoveryLotSizeCalculator::CalculateNextLot(string symbol, string series, int lastOrderNumber, bool rolling) {
   string arSeries[];
   double values[];
   ushort sep = StringGetCharacter(constants.Separator(), 0);
   int count = StringSplit(series, sep, arSeries);
   if(count > 0) {
      int size = ArraySize(arSeries);
      ArrayResize(values, size);

      for(int i=0;i<size;i++) {
         values[i] = StringToDouble(arSeries[i]);   
      }
      
      if(lastOrderNumber >= size && !rolling) {
         return values[size-1];
      } else if (lastOrderNumber >= size && rolling) {
         return values[(lastOrderNumber%size)];
      } else {
         return values[lastOrderNumber];
      }
   }
   
   return constants.MinLot(symbol);
}

double CRecoveryLotSizeCalculator::CalculateNextLotMultiplier(string symbol, double lastLot, string series, int lastOrderNumber) {
   string arSeries[];
   double values[];
   ushort sep = StringGetCharacter(constants.Separator(), 0);
   int count = StringSplit(series, sep, arSeries);
   double multiplier = 1;
   if(count > 0) {
      int size = ArraySize(arSeries);
      ArrayResize(values, size);

      for(int i=0;i<size;i++) {
         values[i] = StringToDouble(arSeries[i]);   
      }
      
      if(lastOrderNumber >= size) {
         multiplier = values[size-1];
      } else {
         multiplier = values[lastOrderNumber%size];
      }
   }
   
   double result = lastLot * multiplier;
   return result;
}

double CRecoveryLotSizeCalculator::CalculateLotSize(string symbol, const int riskPoints, const ENUM_ORDER_TYPE orderType) {
   return CalculateLotSize(symbol, riskPoints, 0, 0, orderType);
}

CRecoveryLotSizeCalculator::CRecoveryLotSizeCalculator(CNormalLotSizeCalculator *normalLotSizeCalc)
          : CLotSizeCalculatorBase() { 
   mNormalLotSizeCalc   = normalLotSizeCalc;
}

CRecoveryLotSizeCalculator::~CRecoveryLotSizeCalculator() {
   delete mNormalLotSizeCalc;
}