#include <Object.mqh>
#include "..\Enums.mqh"
class CFilterBase : public CObject
{

protected:
public:
   CFilterBase::CFilterBase(void)
   {
   }

   CFilterBase::~CFilterBase()
   {
   }

public:
   virtual bool ValidateInputs() = NULL;
   virtual bool GetValue() = NULL;
};