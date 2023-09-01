#include <Object.mqh>
#property static

class CReporter : public CObject
{
public:
    void ReportTradeOpen(ENUM_ORDER_TYPE order);
};


void CReporter::ReportTradeOpen(ENUM_ORDER_TYPE order) {
   
}