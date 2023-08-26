#include "LotSizeCalculatorBase.mqh";
#include "NormalLotSizeCalculator.mqh";
#include "..\Trade\PositionInfoCustom.mqh";
#include  "..\Common.mqh";
#include "..\Common\RecoveryParameters.mqh"

#property strict

/*
   To calculate the recovery for a grid, we need to know the following:
      - The last order of type, lot size
      - The max lot size opened for an order type    
*/
class CRecoveryLotSizeCalculator : public CLotSizeCalculatorBase {

private:
   CPositionInfoCustom        *mPositionInfo;
   CNormalLotSizeCalculator   *mNormalLotSizeCalc;

private:
   double CalculateNextLot(string series, int lastOrderNumber, bool rolling);
   double CalculateNextLotMultiplier(double lastLot, string series, int lastOrderNumber);
   
protected:

public:
   CRecoveryLotSizeCalculator(CPositionInfoCustom *positionInfo);
   ~CRecoveryLotSizeCalculator();
      
public:
   double CalculateLotSize(const int riskPoints, const ENUM_ORDER_TYPE orderType);
   double CalculateLotSize(const double openPrice, const double slPrice, ENUM_ORDER_TYPE orderType);
   double CalculateLotSize(const int riskPoints, double lastLot, int orderCount, const ENUM_ORDER_TYPE orderType);
};


double CRecoveryLotSizeCalculator::CalculateLotSize(const int riskPoints, double lastLot, int orderCount, const ENUM_ORDER_TYPE orderType) {
   //For the first order, use the normal method
   if(orderCount == 0) {      
      double normalLot = mNormalLotSizeCalc.CalculateLotSize(riskPoints, orderType);     
      return normalLot;
   }
   
   int count = 0;
   if(orderCount > 1) {
      count = orderCount - 1;//Ignore the first order (orignal order)
   }
   
   //utils.LogVerbose(__FUNCTION__, StringFormat("Using %s current lot %f , order count %i", EnumToString(RecoveryLotSizeMode), lastLot, count));
   
   switch(RecoveryLotSizeMode) {
      case LOT_FIXED: return NormalizeLot(RecoveryFixedLotSize);
      case LOT_ADD: return NormalizeLot(lastLot + RecoveryFixedLotSize);
      case LOT_FIXED_CUSTOM: {
         switch(MartingalCustomLotMode) {
            case LOT_CUSTOM_SERIES: {
                 double nextLotInSeries = CalculateNextLot(RecoveryLotSeries, count, false);
                 return NormalizeLot(nextLotInSeries);
            }
            case LOT_CUSTOM_ROLLING: {
                 double nextLotInSeries = CalculateNextLot(RecoveryLotSeries, count, true);
                 return NormalizeLot(nextLotInSeries);
            }
            case LOT_CUSTOM_MULTIPLIER: {
                 double nextLotInSeries = CalculateNextLotMultiplier(lastLot, RecoveryLotSeries, count);
                 return NormalizeLot(nextLotInSeries);
            }
         }
      }
   }
     
   return utils._MinLot();   
}

double CRecoveryLotSizeCalculator::CalculateLotSize(const double openPrice, const double slPrice, const ENUM_ORDER_TYPE orderType) {
   int points = (int)MathFloor(NormalizeDouble(MathAbs(openPrice-slPrice), utils._TheDigits()) / utils._ThePoint());
   return CalculateLotSize(points, 0, 0, orderType);   
}

double CRecoveryLotSizeCalculator::CalculateNextLot(string series, int lastOrderNumber, bool rolling) {
   string arSeries[];
   double values[];
   ushort sep = StringGetCharacter(SEPARATOR, 0);
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
   
   return utils._MinLot();
}

double CRecoveryLotSizeCalculator::CalculateNextLotMultiplier(double lastLot, string series, int lastOrderNumber) {
   string arSeries[];
   double values[];
   ushort sep = StringGetCharacter(SEPARATOR, 0);
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
   //utils.LogVerbose(__FUNCTION__, StringFormat("current lot %f, series %s, order number %i multiplier %f new lot %f", lastLot, series, lastOrderNumber, multiplier, result));
   return result;
}

double CRecoveryLotSizeCalculator::CalculateLotSize(const int riskPoints, const ENUM_ORDER_TYPE orderType) {
   return CalculateLotSize(riskPoints, 0, 0, orderType);
}

CRecoveryLotSizeCalculator::CRecoveryLotSizeCalculator(CPositionInfoCustom *positionInfo)
          : CLotSizeCalculatorBase() {
   mPositionInfo        = positionInfo;
   mNormalLotSizeCalc   = new CNormalLotSizeCalculator();
}

CRecoveryLotSizeCalculator::~CRecoveryLotSizeCalculator() {
   SafeDeletePointer(mPositionInfo);
   SafeDeletePointer(mNormalLotSizeCalc);
}