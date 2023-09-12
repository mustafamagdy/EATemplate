#include <Object.mqh>

#property strict

class CIndicatorBase : public CObject
{

private:
protected:
  string mSymbol;
  int mTimeframe;

  int mHandle;
  double mBuffer[];

public:
  CIndicatorBase(string symbol, int timeframe);
  ~CIndicatorBase();

  bool IsValid() { return (mHandle != INVALID_HANDLE); }
  int GetArray(int bufferNumber, int start, int count, double &arr[]);
  virtual double GetValue(int index) { return GetValue(0, index); }
  virtual double GetValue(int bufferNumber, int index);

#ifdef __MQL5__
  void HideIndicators();
#endif
};

CIndicatorBase::CIndicatorBase(string symbol, int timeframe)
{
  mSymbol = symbol;
  mTimeframe = timeframe;
  mHandle = 0;
  ArraySetAsSeries(mBuffer, true);
}

CIndicatorBase::~CIndicatorBase()
{
#ifdef __MQL5__
  IndicatorRelease(mHandle);
#endif
}

#ifdef __MQL4__
int CIndicatorBase::GetArray(int bufferNumber, int start, int count, double &arr[])
{
  ArraySetAsSeries(arr, true);
  ArrayResize(arr, count);
  for (int i = 0; i < count; i++)
  {
    arr[i] = GetValue(bufferNumber, i + start);
  }
  return (count);
}

double CIndicatorBase::GetValue(int bufferNumber, int index)
{
  return (0);
}
#endif

#ifdef __MQL5__
int CIndicatorBase::GetArray(int bufferNumber, int start, int count, double &arr[])
{
  ArraySetAsSeries(arr, true);
  int result = CopyBuffer(mHandle, bufferNumber, start, count, mBuffer);
  return (result);
}

double CIndicatorBase::GetValue(int bufferNumber, int index)
{
  int result = CopyBuffer(mHandle, bufferNumber, index, 1, mBuffer);
  return (result > 0) ? mBuffer[0] : 0;
}
void CIndicatorBase::HideIndicators()
{
  TesterHideIndicators(true);
}
#endif