#include <Object.mqh>;

void SafeDeletePointer(CObject *obj)
{
    if (obj != NULL && CheckPointer(obj) == POINTER_DYNAMIC)
    {
        delete obj;
    }
}
