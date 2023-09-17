#include <Object.mqh>;
#include "..\Enums.mqh"
#include "SignalBase.mqh"

#property strict

class CSignalManager : public CObject
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

    bool ValidateSignals()
    {
        for (int i = 0; i < ArraySize(_signals); i++)
        {
            if (!_signals[i].ValidateInputs())
            {
                return (false);
            }
        }
        return (true);
    }

    void RegisterSignal(CSignalBase *signal)
    {
        ArrayResize(_signals, ArraySize(_signals) + 1);
        _signals[ArraySize(_signals) - 1] = signal;
    }

    bool GetSignalWithAnd(ENUM_SIGNAL signal)
    {
        // if(signal == SIGNAL_SELL) DebugBreak();
        for (int i = 0; i < ArraySize(_signals); i++)
        {
            if (_signals[i].GetSignal() != signal)
            {
                return false;
            }
        }

        return true;
    }

    bool GetSignalWithOr(ENUM_SIGNAL signal)
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