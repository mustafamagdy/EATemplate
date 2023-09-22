#include <Object.mqh>

#property strict

class CIndicatorBase : public CObject
{
protected:
  string mSymbol;
  int mTimeframe;
  int mHandle;
  double mBuffer[];

  // Internal methods for MQL4 and MQL5 specific implementations
#ifdef __MQL4__
  int _GetArray(int bufferNumber, int start, int count, double &arr[]);
  double _GetValue(int bufferNumber, int index);
#endif

#ifdef __MQL5__
  int _GetArray(int bufferNumber, int start, int count, double &arr[]);
  double _GetValue(int bufferNumber, int index);
  void _HideIndicators();
#endif

public:
  // Constructor & Destructor
  CIndicatorBase(string symbol, int timeframe);
  ~CIndicatorBase();

  // Public methods
  bool IsValid() const { return (mHandle != INVALID_HANDLE); }
  int GetArray(int bufferNumber, int start, int count, double &arr[]);
  virtual double GetValue(int index) { return GetValue(0, index); }
  virtual double GetValue(int bufferNumber, int index);

#ifdef __MQL5__
  void HideIndicators();
#endif
};

CIndicatorBase::CIndicatorBase(string symbol, int timeframe) :
  mSymbol(symbol),
  mTimeframe(timeframe),
  mHandle(0)
{
  ArraySetAsSeries(mBuffer, true);
}

CIndicatorBase::~CIndicatorBase()
{
#ifdef __MQL5__
  IndicatorRelease(mHandle);
#endif
}

// Implementation for MQL4
#ifdef __MQL4__
int CIndicatorBase::_GetArray(int bufferNumber, int start, int count, double &arr[])
{
  ArraySetAsSeries(arr, true);
  ArrayResize(arr, count);
  for (int i = 0; i < count; i++)
  {
    arr[i] = GetValue(bufferNumber, i + start);
  }
  return count;
}

double CIndicatorBase::_GetValue(int bufferNumber, int index)
{
  return 0;
}
#endif

// Implementation for MQL5
#ifdef __MQL5__
int CIndicatorBase::_GetArray(int bufferNumber, int start, int count, double &arr[])
{
  ArraySetAsSeries(arr, true);
  int result = CopyBuffer(mHandle, bufferNumber, start, count, mBuffer);
  return result;
}

double CIndicatorBase::_GetValue(int bufferNumber, int index)
{
  int result = CopyBuffer(mHandle, bufferNumber, index, 1, mBuffer);
  return (result > 0) ? mBuffer[0] : 0;
}

void CIndicatorBase::_HideIndicators()
{
  TesterHideIndicators(true);
}
#endif

// Public Methods
int CIndicatorBase::GetArray(int bufferNumber, int start, int count, double &arr[])
{
#ifdef __MQL4__
  return _GetArray(bufferNumber, start, count, arr);
#else
  return _GetArray(bufferNumber, start, count, arr);
#endif
}

double CIndicatorBase::GetValue(int bufferNumber, int index)
{
#ifdef __MQL4__
  return _GetValue(bufferNumber, index);
#else
  return _GetValue(bufferNumber, index);
#endif
}

#ifdef __MQL5__
void CIndicatorBase::HideIndicators()
{
  _HideIndicators();
}
#endif
