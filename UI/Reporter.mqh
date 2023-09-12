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
    PrintFormat("=> %s order opened with lot %2.f", EnumToString(order), lot);
}

void CReporter::ReportWarning(string message)
{
    PrintFormat("WARNING: %S", message);
}

void CReporter::ReportError(string message)
{
    PrintFormat("ERROR: %S", message);
}