#include <Object.mqh>
#property static

class CReporter : public CObject
{
public:
    void ReportTradeOpen(ENUM_ORDER_TYPE order);
    void ReportTradeOpen(ENUM_ORDER_TYPE order, double lot);
    void ReportWarning(string message);
    void ReportError(string message);
};

void CReporter::ReportTradeOpen(ENUM_ORDER_TYPE order)
{
}

void CReporter::ReportTradeOpen(ENUM_ORDER_TYPE order, double lot)
{
    PrintFormat("%s opened with lot %0.2f", EnumToString(order), lot);
}

void CReporter::ReportWarning(string message)
{
    PrintFormat("WARNING: %s", message);
}

void CReporter::ReportError(string message)
{
    PrintFormat("ERROR: %s", message);
}