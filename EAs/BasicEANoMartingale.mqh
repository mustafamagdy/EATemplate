#include "ExpertBase.mqh"
#include "..\Signals\AlligatorSignal.mqh"

class BasicEANoMartingale : public CExpertBase
{

public:
    BasicEANoMartingale(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
                        RiskOptions &riskOptions, CPnLManager *pnlManager, CTradingStatusManager *tradingStatusManager)
        : CExpertBase(symbol, maxSpread, defaultSLPoints, defaultTPPoints, riskOptions, pnlManager, tradingStatusManager) {}

protected:
    void RegisterFilters(CFilterManager *filterManager)
    {
    }

    void RegisterBuySignals(CSignalManager *signalManager)
    {
         signalManager.RegisterSignal(new CAlligatorSignal(pSymbol, PERIOD_M15, 50, 0, 21, 0, 14, 0, MODE_SMMA, PRICE_MEDIAN));
    }

    void RegisterSellSignals(CSignalManager *signalManager)
    {
         signalManager.RegisterSignal(new CAlligatorSignal(pSymbol, PERIOD_M15, 50, 0, 21, 0, 14, 0, MODE_SMMA, PRICE_MEDIAN));
    }

    void OnBuySignal()
    {
      MqlDateTime time;
      TimeCurrent(time);
      
      if(time.hour < 5 || time.hour > 18) return;
      
      int slPoints = _defaultSLPoints;
      int tpPoints = _defaultTPPoints;
      double ask = _constants.Ask(pSymbol);
      
      if (_buyBasket.IsEmpty())
      {
         ENUM_ORDER_TYPE direction = ORDER_TYPE_BUY;
         double price = ask;
      
         double slPrice = price + (slPoints * _constants.Point(pSymbol));
         double lots = _normalLotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
         string message;
         Trade trade;
         if (!buyManager.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test buy"))
         {
             _reporter.ReportError(StringFormat("Failed to open buy trade: %s", message));
         }
      }
    }

    void OnSellSignal()
    {
      MqlDateTime time;
      TimeCurrent(time);
      
      if(time.hour < 5 || time.hour > 18) return;
      
      int slPoints = _defaultSLPoints;
      int tpPoints = _defaultTPPoints;
      double bid = _constants.Bid(pSymbol);
      
      if (_sellBasket.IsEmpty())
      {
         ENUM_ORDER_TYPE direction = ORDER_TYPE_SELL;
         double price = bid;
      
         double slPrice = price + (slPoints * _constants.Point(pSymbol));
         double lots = _normalLotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
         string message;
         Trade trade;
         if (!sellManager.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, "test sell"))
         {
             _reporter.ReportError(StringFormat("Failed to open sell trade: %s", message));
         }
      }
    }
};