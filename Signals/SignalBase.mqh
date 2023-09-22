#include <Object.mqh>
#include "..\Enums.mqh"
class CSignalBase : public CObject
{

protected:
public:
   CSignalBase::CSignalBase(void)
   {
   }

   CSignalBase::~CSignalBase()
   {
   }

public:
   virtual bool ValidateInputs() = 0;
   virtual ENUM_SIGNAL GetSignal() = 0;
};