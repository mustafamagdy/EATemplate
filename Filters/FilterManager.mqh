#include "..\Enums.mqh"
#include "FilterBase.mqh"

#property strict

class CFilterManager
{
    CFilterBase *_filters[];

public:
    CFilterManager()
    {
        ArrayFree(_filters);
        ArrayResize(_filters, 0);
    }

    ~CFilterManager()
    {
        ArrayFree(_filters);
    }

    void RegisterSignal(CFilterBase *signal)
    {
        ArrayResize(_filters, ArraySize(_filters) + 1);
        _filters[ArraySize(_filters) - 1] = signal;
    }

    bool AllAgree()
    {
        for (int i = 0; i < ArraySize(_filters); i++)
        {
            if (!_filters[i].GetValue())
            {
                return false;
            }
        }

        return true;
    }

    bool AnyAgree()
    {
        for (int i = 0; i < ArraySize(_filters); i++)
        {
            if (_filters[i].GetValue())
            {
                return true;
            }
        }

        return false;
    }
};