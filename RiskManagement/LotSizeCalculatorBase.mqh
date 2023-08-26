#include <Object.mqh>;
#include "..\Constants.mqh";

#property strict

class CLotSizeCalculatorBase : public CObject
{

private:
   double MaxLotForMarginAvailable(string symbol);

protected:
   CConstants constants;

protected:
   double GetRiskAmount(string symbol, double riskPoints, double riskLotSize);
   double GetRiskLots(string symbol, double riskPoints, double riskAmount);

public:
   CLotSizeCalculatorBase(){};

   ~CLotSizeCalculatorBase(){};

public:
   virtual double CalculateLotSize(string symbol, const int riskPoints, const ENUM_ORDER_TYPE orderType = -1) = NULL;
   virtual double CalculateLotSize(string symbol, const double openPrice, const double slPrice, ENUM_ORDER_TYPE orderType = -1) = NULL;
   virtual double CalculateLotSize(string symbol, const int riskPoints, double lastLot, int orderCount, const ENUM_ORDER_TYPE orderType = -1) = NULL;

   double NormalizeLot(string symbol, double lots);
};

double CLotSizeCalculatorBase::GetRiskAmount(string symbol, double riskPoints, double riskLotSize)
{
   return riskPoints * riskLotSize * _Point;
}

double CLotSizeCalculatorBase::GetRiskLots(string symbol, double riskPoints, double riskAmount)
{
   if (riskPoints == 0)
      return constants.MinLot(symbol);
   double commission = 7;
   double pointValue = _Point;
   double x = riskPoints * pointValue;
   double y = x + commission;
   double z = riskAmount / y;
   return z;
   // return riskAmount/((riskPoints * ) + commission);
}

double CLotSizeCalculatorBase::NormalizeLot(string symbol, double lots)
{
   double NormalizedLot; // The final LotSize, bounded by broker's specs
   double InverseLotStep;
   double LotStep = constants.LotStep(symbol);
   double MinLot = constants.MinLot(symbol);
   double MaxLot = constants.MaxLot(symbol);
   if (MinLot == 0.0)
      MinLot = 0.1; // In case MarketInfo returns no info
   if (MaxLot == 0.0)
      MaxLot = 5; // In case MarketInfo returns no info
   if (LotStep == 0.0)
      InverseLotStep = 1 / MinLot; // In case MarketInfo returns no info
   else
      InverseLotStep = 1 / LotStep;

   NormalizedLot = MathFloor(lots * InverseLotStep) / InverseLotStep;

   double maximumLotForMarginAvilable = MaxLotForMarginAvailable(symbol);
   if (NormalizedLot > maximumLotForMarginAvilable)
   {
      // constants.LogError(__FUNCTION__, StringFormat("Not enough margin to open lot %f, use max lot allowed %f", NormalizedLot, maximumLotForMarginAvilable));
      NormalizedLot = maximumLotForMarginAvilable;
   }
   if (NormalizedLot < MinLot)
      NormalizedLot = MinLot; // Broker's absolute minimum Lot
   if (NormalizedLot > MaxLot)
      NormalizedLot = MaxLot; // Broker's absolute maximum Lot

   // constants.LogVerbose(__FUNCTION__, StringFormat( "normalized lot %f", NormalizedLot));
   return NormalizeDouble(NormalizedLot, 2);
}

double CLotSizeCalculatorBase::MaxLotForMarginAvailable(string symbol)
{

   double freeMargin = constants.AccountFreeMargin();
   double equity = constants.AccountEquity();
   // constants.LogVerbose(StringFormat("Free margin= %g",freeMargin));
   // constants.LogVerbose(StringFormat("equity= %g",equity));

   ENUM_ACCOUNT_STOPOUT_MODE soMode = (ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);

   double marginCall = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
   double marginStopOut = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
   double callValue = (soMode == ACCOUNT_STOPOUT_MODE_PERCENT) ? equity * marginCall / 100 : marginCall;

   double stopoutValue = (soMode == ACCOUNT_STOPOUT_MODE_MONEY) ? equity * marginStopOut / 100 : marginStopOut;

   double availableMargin = freeMargin - callValue;

   // constants.LogVerbose(StringFormat("availableMargin= %g",availableMargin));

   double marginPerLot = constants.MarginRequired(symbol);
   if (marginPerLot == 0)
   {
      return constants.MaxLot(symbol);
   }

   // constants.LogVerbose(StringFormat("marginPerLot= %g",marginPerLot));

   double lots = availableMargin / marginPerLot;

   return (lots);
}