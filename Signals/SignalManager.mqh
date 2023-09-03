#include "..\Enums.mqh"
#include "SignalBase.mqh"

#property strict

class CSignalManager
{
    CSignalBase *_signals[];

public:
    CSignalManager()
    {
        ArrayFree(_signals);
        ArrayResize(_signals, 0);
    }

    ~CSignalManager()
    {
        ArrayFree(_signals);
    }

    void RegisterSignal(CSignalBase *signal)
    {
        ArrayResize(_signals, ArraySize(_signals) + 1);
        _signals[ArraySize(_signals) - 1] = signal;
    }

    bool GetSignalWithAnd(ENUM_SIGNAL signal)
    {
        for (int i = 0; i < ArraySize(_signals); i++)
        {
            if (_signals[i].GetSignal() != signal)
            {
                return false;
            }
        }

        return true;
    }

    ENUM_SIGNAL GetSignalWithOr(ENUM_SIGNAL signal)
    {
        for (int i = 0; i < ArraySize(_signals); i++)
        {
            if (_signals[i].GetSignal() == signal)
            {
                return true;
            }
        }

        return false;
    }
};