#include <Object.mqh>;

#define MAX_RETRIES 3
#define ERR_INVALID_PARAMETER 4003

void SafeDeletePointer(CObject *obj)
{
    if (obj != NULL && CheckPointer(obj) == POINTER_DYNAMIC)
    {
        delete obj;
    }
}

#ifdef __MQL4__
template <typename T>
void ArrayRemove(T &arr[], int index, int count = 1)
{
    if (index < 0 || index + count > ArraySize(arr))
    {
        Print("Invalid index or count for ArrayRemove function");
        return;
    }

    for (int i = index; i < ArraySize(arr) - count; i++)
    {
        arr[i] = arr[i + count];
    }

    ArrayResize(arr, ArraySize(arr) - count);
}
#endif

#ifdef __MQL5__
int DayOfWeek()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    return dt.day_of_week;
}
#endif