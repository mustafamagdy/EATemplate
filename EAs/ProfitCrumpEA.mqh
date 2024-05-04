#include "..\Common.mqh"
#include "ExpertBase.mqh"
#include "..\Indicators\IndicatorMACD.mqh"

class CProfitCrumpEA : public CExpertBase
{
private:
    bool hedgingAllowed;
    CIndicatorMACD *_indi;
    int _shift;

public:
    CProfitCrumpEA(string symbol, int maxSpread, int defaultSLPoints, int defaultTPPoints,
                   MartingaleOptions &recoveryOptions, RiskOptions &riskOptions, CPnLManager *pnlManager, CTradingStatusManager *tradingStatusManager)
        : CExpertBase(symbol, maxSpread, defaultSLPoints, defaultTPPoints, recoveryOptions, riskOptions, pnlManager, tradingStatusManager)
    {
        _indi = new CIndicatorMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE);
        _shift = 1;
        hedgingAllowed = true; // recoveryOptions.hedgingAllowed;
    }

protected:
    void RegisterFilters(CFilterManager *filterManager)
    {
    }

    void RegisterBuySignals(CSignalManager *signalManager)
    {
    }

    void RegisterSellSignals(CSignalManager *signalManager)
    {
    }

    void OnSignal(bool isSellSignal)
    {
        double price = isSellSignal ? _constants.Bid(pSymbol) : _constants.Ask(pSymbol);

        int factor = 10000;

        double high_1 = factor * iHigh(NULL, PERIOD_CURRENT, 1);
        double low_1 = factor * iLow(NULL, PERIOD_CURRENT, 1);
        double close_1 = factor * iClose(NULL, PERIOD_CURRENT, 1);
        double high_2 = factor * iHigh(NULL, PERIOD_CURRENT, 2);
        double low_2 = factor * iLow(NULL, PERIOD_CURRENT, 2);
        double close_2 = factor * iClose(NULL, PERIOD_CURRENT, 2);
        double avgPrice = (high_1 + low_1) / 2.0;
        int orderCount = isSellSignal ? _sellBasket.Count() : _buyBasket.Count();
        int otherBasketOrderCount = isSellSignal ? _buyBasket.Count() : _sellBasket.Count();

        int tf = PERIOD_M5;
        if (orderCount > 2 && orderCount < 5)
            tf = PERIOD_M5;
        if (orderCount > 4)
            tf = PERIOD_M1;

        _indi.SetTimeframe(tf);
        double macd_1 = factor * _indi.GetValue(MACD_SIGNAL_LINE, _shift);
        double macd_2 = factor * _indi.GetValue(MACD_SIGNAL_LINE, _shift + 1);
        double macd_3 = factor * _indi.GetValue(MACD_SIGNAL_LINE, _shift + 2);

        Trade lastTrade;
        double lastOpenPrice = 0;
        if (_sellBasket.LastTrade(lastTrade))
        {
            lastOpenPrice = lastTrade.OpenPrice();
        }

        bool has_signal = false;
        int dayOfWeek = DayOfWeek();
        int nextGridGap = GetProfitCrumpSymbolGridGap(pSymbol);
        int maxMacd = 20;
double point = _constants.Point(pSymbol);
        if (dayOfWeek < 6 && _constants.AccountFreeMargin() > 100.0)
        {
            if (orderCount == 0)
            {
                has_signal = CheckMACDEntrySignal(avgPrice, close_1, low_2, low_1, 20, 0, macd_3, macd_2, macd_1, false);
                if (has_signal && (isSellSignal ? (nextGridGap * point < price - lastOpenPrice) : (nextGridGap * point > price + lastOpenPrice)))
                    Print("first countertrade sell");
            }
            if (orderCount > 0)
                has_signal = CheckMACDEntrySignal(avgPrice, close_1, low_2, low_1, 20, 0, macd_3, macd_2, macd_1, false);

            if (has_signal == true && (isSellSignal ? (nextGridGap * point < price - lastOpenPrice) : (nextGridGap * point > price + lastOpenPrice)))
                Print("adding to countertrade sell");

            if (orderCount == 0 && has_signal == false)
            {
                has_signal = CheckMACDEntrySignal(avgPrice, close_1, low_2, low_1, 20, 0, macd_3, macd_2, macd_1, false);
                if (has_signal == true && (isSellSignal ? (nextGridGap * point < price - lastOpenPrice) : (nextGridGap * point > price + lastOpenPrice)))
                    Print("first trend sell");
            }

            if (orderCount > 0 && has_signal == false)
            {
                has_signal = CheckMACDEntrySignal(avgPrice, close_1, low_2, low_1, 20, 0, macd_3, macd_2, macd_1, false);
                if (has_signal == true && (isSellSignal ? (nextGridGap * point < price - lastOpenPrice) : (nextGridGap * point > price + lastOpenPrice)))
                    Print("adding to first trend sell");
            }
        }

        if (has_signal == true && (isSellSignal ? (nextGridGap * point < price - lastOpenPrice) : (nextGridGap * point > price + lastOpenPrice)))
            has_signal = true;
        else
            has_signal = false;

        if (!hedgingAllowed && otherBasketOrderCount != 0)
            has_signal = false;

        if (orderCount == 0 && dayOfWeek == 0 && has_signal == true)
        {
            has_signal = false;
            Print("Due to False Signals, No New Trades Started on Sunday");
        }

        int slPoints = _defaultSLPoints;
        int tpPoints = _defaultTPPoints;

        if (has_signal)
        {
            ENUM_ORDER_TYPE direction = isSellSignal ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            double slPrice = price + ((direction == ORDER_TYPE_BUY ? -1 : 1) * (slPoints * point));
            double lots = _lotCalc.CalculateLotSize(pSymbol, price, slPrice, direction);
            string message;
            string comment = direction == ORDER_TYPE_BUY ? "Open buy order" : "Open sell order";
            Trade trade;
            if (!sellRecovery.OpenTradeWithPoints(lots, price, direction, 0, 0, message, trade, slPoints, tpPoints, comment))
            {
                PrintFormat("Failed to open sell trade: %s", message);
            }
        }
    }

    void OnBuySignal()
    {
        OnSignal(false);
    }

    void OnSellSignal()
    {
        OnSignal(true);
    }

    bool CheckMACDEntrySignal(double avgPrice, double close1, double low2, double low1,
                              double a5, double a6, double macd1, double macd2, double macd3,
                              bool isBuySignal)
    {
        if (isBuySignal)
        {
            return (
                (close1 < avgPrice && close1 <= low2 && (close1 < low1 || close1 < -low1) && (a6 == 0 || a5 > a6) && macd1 > macd2 && (macd2 > macd3 || macd1 > macd3)) ||
                (close1 < avgPrice && close1 <= low2 && close1 < low1 && close1 > a5 && (a6 == 0 || a6 > macd1) && macd2 > macd3));
        }
        else
        {
            return (
                (close1 > avgPrice && close1 >= low2 && (close1 > low1 || close1 > -low1) && (a6 == 0 || a5 < a6) && macd1 < macd2 && (macd2 < macd3 || macd1 < macd3)) ||
                (close1 > avgPrice && close1 >= low2 && close1 > -low1 && close1 < -a5 && (a6 == 0 || a6 < macd1) && macd2 < macd3));
        }
    }

    // bool CheckMacdSellEntrySignal1(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8)
    // {
    //     return (close1 > avgPrice && close1 >= low2 && close1 > low1 && a5 < a6 && a7 < a8);
    // }
    // bool CheckMacdSellEntrySignal2(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8, double a9)
    // {
    //     return (close1 > avgPrice && close1 >= low2 && close1 > -low1 && close1 < -a5 && a6 < a7 && a8 < a9);
    // }
    // bool CheckMacdSellEntrySignal3(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8, double a9)
    // {
    //     return (close1 > avgPrice && close1 >= low2 && close1 > -low1 && close1 < -a5 && a6 < a7 && a8 < a9);
    // }
    // bool CheckMacdSellEntrySignal4(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8)
    // {
    //     return (close1 > avgPrice && close1 >= low2 && close1 > low1 && a5 < a6 && a7 < a8);
    // }
    // bool CheckMacdBuyEntrySignal1(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8)
    // {
    //     return (close1 < avgPrice && close1 <= low2 && close1 < -low1 && a5 > a6 && a7 > a8);
    // }
    // bool CheckMacdBuyEntrySignal2(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8, double a9)
    // {
    //     return (close1 < avgPrice && close1 <= low2 && close1 < low1 && close1 > a5 && a6 > a7 && a8 > a9);
    // }
    // bool CheckMacdBuyEntrySignal3(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8, double a9)
    // {
    //     return (close1 < avgPrice && close1 <= low2 && close1 < low1 && close1 > a5 && a6 > a7 && a8 > a9);
    // }
    // bool CheckMacdBuyEntrySignal4(double avgPrice, double close1, double low2, double low1, double a5, double a6, double a7, double a8)
    // {
    //     return (close1 < avgPrice && close1 <= low2 && close1 < -low1 && a5 > a6 && a7 > a8);
    // }

    int GetProfitCrumpSymbolGridGap(string symbol)
    {
        if (symbol == "BTCUSD")
            return 3000;
        if (symbol == "EURUSD")
            return 480;
        if (symbol == "USDCAD")
            return 300;
        if (symbol == "GBPUSD")
            return 380;
        if (symbol == "EURGBP")
            return 180;
        else
            return 480;
    }
};