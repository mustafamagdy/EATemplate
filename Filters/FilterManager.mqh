#include <Object.mqh>
#include "..\Enums.mqh"
#include "FilterBase.mqh"

#property strict

class CFilterManager : public CObject
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

    bool ValidateFilters()
    {
        for (int i = 0; i < ArraySize(_filters); i++)
        {
            if (!_filters[i].ValidateInputs())
            {
                return (false);
            }
        }
        return (true);
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