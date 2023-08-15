#include "CandlePattern.mqh"


class CandlestickPattern {

private:
   CCandlePatterns *cPtr;

public:
   CandlestickPattern() {
      cPtr = new CCandlePatterns();      
   }

public:
   bool IsDoji(int shift) { return false; }
   bool IsBullishEngulfing(int shift) { return false; }
   bool IsBearishEngulfing(int shift) { return false; }
   bool IsHammer(int shift) { return cPtr.ReversalPatterns(true); }
   bool IsHangingMan(int shift) { return false; }
   bool IsShootingStar(int shift) { return false; }
   bool IsMorningStar(int shift) { return false; }
   bool IsEveningStar(int shift) { return false; }
   bool IsBullishHarami(int shift) { return false; }
   bool IsBearishHarami(int shift) { return false; }
   bool IsThreeBlackCrows(int shift) { return false; }
   bool IsThreeWhiteSoldiers(int shift) { return false; }
   
};

  