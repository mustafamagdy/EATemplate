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
   virtual bool ValidateInputs() = NULL;
   virtual ENUM_SIGNAL GetSignal() = NULL;
};