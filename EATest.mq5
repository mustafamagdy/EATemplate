int InpLookback = 500;    // How many peaks/valleys to consider
double InpGapPoints = 50; // Gap in points between S/R levels
int InpSensitivity = 2;   // Sensitivity of S/R levels

// Define global arrays to store levels
double SRLevels[];
int srCounter;
double _min_gap = 100; // 10 pips

int OnInit(void)
{
    ArrayResize(SRLevels, 0);
    ArrayInitialize(SRLevels, 0.0);

    return (INIT_SUCCEEDED);
}

void OnTick()
{
    // Get current price
    double currentPrice = iClose(Symbol(), 0, 0);

    // Identify S/R levels
    IdentifySRLevels();

    DrawSRLevels();

    CheckForSignal();
}

void IdentifySRLevels()
{
    int rates_total = 2000;

    double zzPeaks[];
    int zzCount = 0;

    ArrayResize(zzPeaks, InpLookback);
    ArrayInitialize(zzPeaks, 0.0);

    int Handle = iCustom(_Symbol, _Period, "Examples\\ZigZag.ex5", 12, 5, 3, 0); // Adjust ZigZag parameters as needed
    double Buffer[];
    ArrayResize(Buffer, rates_total);
    int count = CopyBuffer(Handle, 0, 0, rates_total, Buffer);
    if (count < 0)
    {
        int err = GetLastError();
        Print("Error in CopyBuffer: ");
        return;
    }

    for (int i = rates_total - 1; i >= 0 && zzCount < InpLookback; i--)
    {
        double zz = Buffer[i];
        if (zz != 0 && zz != EMPTY_VALUE)
        {
            zzPeaks[zzCount] = zz;
            zzCount++;
        }
    }

    ArraySort(zzPeaks);

    double price = 0;
    int priceCount = 0;
    for (int i = InpLookback - 1; i >= 0; i--)
    {
        price += zzPeaks[i];
        priceCount++;
        if (i == 0 || MathAbs((zzPeaks[i] - zzPeaks[i - 1])) > InpGapPoints * _Point)
        {
            if (priceCount >= InpSensitivity)
            {
                price = price / priceCount;
                if (ArraySearch(SRLevels, price) == -1)
                {
                    ArrayResize(SRLevels, srCounter + 1);
                    SRLevels[srCounter++] = price;
                }
            }
            price = 0;
            priceCount = 0;
        }
    }
}

int ArraySearch(double &arr[], double value)
{
    int searchValue = (int)(value * (1.0 / _Point));

    for (int i = 0; i < ArraySize(arr); i++)
    {
        int arrayValue = (int)(arr[i] * (1.0 / _Point));

        if (MathAbs(arrayValue - searchValue) <= _min_gap)
            return i;
    }
    return -1; // If value not found in the array
}

void DrawSRLevels()
{
    for (int i = 0; i < ArraySize(SRLevels); i++)
    {
        string lineName = "SRLine_" + IntegerToString(i);
        if (ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, SRLevels[i]))
        {
            ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrGray);
            ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
        }
    }
}

void CheckForSignal()
{
    double currentClose = iClose(Symbol(), 0, 0);

    for (int i = 0; i < ArraySize(SRLevels); i++)
    {
        double prevClose = iClose(Symbol(), 0, 1);
        datetime time = iTime(Symbol(), 0, 0);
        string arrowName;
        if (prevClose < SRLevels[i] && currentClose > SRLevels[i])
        {
            Print("Buy Signal at ", SRLevels[i]);
            arrowName = StringFormat("BuyArrow_%s", TimeToString(time, TIME_DATE | TIME_MINUTES));

            ObjectCreate(0, arrowName, OBJ_ARROW, 0, time, SRLevels[i]);
            ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, OBJ_ARROW_UP);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrBlue);
        }
        else if (prevClose > SRLevels[i] && currentClose < SRLevels[i])
        {
            Print("Sell Signal at ", SRLevels[i]);
            arrowName = StringFormat("SellArrow_%s", TimeToString(time, TIME_DATE | TIME_MINUTES));
            ObjectCreate(0, arrowName, OBJ_ARROW, 0, time, SRLevels[i]);
            ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, OBJ_ARROW_DOWN);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrRed);
        }
    }
}

void FindNearestLevels(double currentPrice, double minGap, double &sPrice, double &rPrice)
{
    if (ArraySize(SRLevels) < 2)
        return;
    double closestSupport = 0;
    double closestResistance = 0;
    // Find the nearest support level (highest value below current price)
    for (int i = ArraySize(SRLevels) - 1; i >= 0; i--)
    {
        if (SRLevels[i] < currentPrice)
        {
            closestSupport = SRLevels[i];
            break;
        }
    }

    double gap = 200 * _Point;
    // From the support level position, find the nearest resistance (next value above current price)
    for (int i = 0; i < ArraySize(SRLevels); i++)
    {
        if (SRLevels[i] > currentPrice && SRLevels[i] > (closestSupport + gap))
        {
            closestResistance = SRLevels[i];
            break;
        }
    }

    sPrice = closestSupport;
    rPrice = closestResistance;
}

void DrawSRLevels(double support, double resistance)
{
    string s_name = "Support_Line";
    string r_name = "Resistance_Line";

    // Delete previous lines if they exist
    ObjectDelete(0, s_name);
    ObjectDelete(0, r_name);

    if (support != 0)
    {
        ObjectCreate(0, s_name, OBJ_HLINE, 0, 0, support);
        ObjectSetInteger(0, s_name, OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(0, s_name, OBJPROP_WIDTH, 2);
    }

    if (resistance != 0)
    {
        ObjectCreate(0, r_name, OBJ_HLINE, 0, 0, resistance);
        ObjectSetInteger(0, r_name, OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, r_name, OBJPROP_WIDTH, 2);
    }
}
