#include "LotSizeCalculatorBase.mqh";
#include "..\Enums.mqh";

#property strict

class CNormalLotSizeCalculator : public CLotSizeCalculator
{

private:
   ENUM_RISK_TYPE _riskType;
   double _fixedLot;
   ENUM_RISK_SOURCE _riskPercentageSource;
   double _riskPercentage;
   double _xBalance;
   double _lotPerXBalance;

public:
   CNormalLotSizeCalculator(
       ENUM_RISK_TYPE riskType,
       double fixedLot,
       ENUM_RISK_SOURCE riskPercentageSource,
       double riskPercentage,
       double xBalance,
       double lotPerXBalance)
       : CLotSizeCalculator()
   {
      _riskType = riskType;
      _fixedLot = fixedLot;
      _riskPercentageSource = riskPercentageSource;
      _riskPercentage = riskPercentage;
      _xBalance = xBalance;
      _lotPerXBalance = lotPerXBalance;
   };
   ~CNormalLotSizeCalculator(){};

public:
   double CalculateLotSize(string symbol, const int riskPoints, const ENUM_ORDER_TYPE orderType = -1);
   double CalculateLotSize(string symbol, const double openPrice, const double slPrice, ENUM_ORDER_TYPE orderType = -1);
   double CalculateLotSize(string symbol, const int riskPoints, double lastLot, int orderCount, const ENUM_ORDER_TYPE orderType);
};

double CNormalLotSizeCalculator::CalculateLotSize(string symbol, const int riskPoints, const ENUM_ORDER_TYPE orderType = -1)
{
   double lotSize = 0;
   double riskAmount = 0;
   double riskPercentage = (_riskPercentage / 100.0);
   switch (_riskType)
   {
   case RISK_TYPE_FIXED_LOT:
   {
      lotSize = _fixedLot;
      break;
   }
   case RISK_TYPE_PER_XBALANCE:
   {
      lotSize = constants.AccountBalance() / _xBalance * _lotPerXBalance;
      break;
   }
   case RISK_TYPE_PERCENTAGE:
   {
      if (_riskPercentageSource == RISK_PERCENTAGE_FROM_BALANCE)
      {
         riskAmount = riskPercentage * constants.AccountBalance();
      }
      else if (_riskPercentageSource == RISK_PERCENTAGE_FROM_EQUITY)
      {
         riskAmount = riskPercentage * constants.AccountEquity();
      }
      else if (_riskPercentageSource == RISK_PERCENTAGE_FROM_AVILABLE_MARGIN)
      {
         riskAmount = riskPercentage * constants.AccountFreeMargin();
      }

      lotSize = GetRiskLots(symbol, riskPoints, riskAmount);
      break;
   }
   }

   double normalizedLotSize = NormalizeLot(symbol, lotSize);
   return normalizedLotSize;
}

double CNormalLotSizeCalculator::CalculateLotSize(string symbol, const double openPrice, const double slPrice, const ENUM_ORDER_TYPE orderType = -1)
{
   int points = (int)MathFloor(NormalizeDouble(MathAbs(openPrice - slPrice), _Digits) / _Point);
   return CalculateLotSize(symbol, points, orderType);
}

double CNormalLotSizeCalculator::CalculateLotSize(string symbol, const int riskPoints, double lastLot, int orderCount, const ENUM_ORDER_TYPE orderType)
{
   return CalculateLotSize(symbol, riskPoints, 0, 0, orderType);
}
