#include <Object.mqh>
#property static

class CReporter : public CObject
{
public:
    void ReportTradeOpen(ENUM_ORDER_TYPE order);
    void ReportWarning(string message);
};

void CReporter::ReportTradeOpen(ENUM_ORDER_TYPE order)
{
}

void CReporter::ReportWarning(string message)
{
    Print(message);
}