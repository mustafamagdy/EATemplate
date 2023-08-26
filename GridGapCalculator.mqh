#include <Object.mqh>
#include "Enums.mqh";
#include "Constants.mqh";

#property strict

enum ENUM_GRID_SIZE_MODE
{
    GRID_SIZE_FIXED = 0,        // Fixed Size
    GRID_SIZE_FIXED_CUSTOM = 1, // Custom Series
    GRID_SIZE_DYNAMIC = 2,      // ATR Based
};

enum ENUM_GRID_FIXED_CUSTOM_MODE
{
    GRID_SIZE_CUSTOM_SERIES = 0,     // Custom Fixed Series
    GRID_SIZE_CUSTOM_ROLLING = 1,    // Custom Series (Restart when finished)
    GRID_SIZE_CUSTOM_MULTIPLIER = 2, // Custom Multiplier Series
};

class CGridGapCalculator : public CObject
{

private:
    ENUM_GRID_SIZE_MODE _gridSizeMode;               // Grid Size Mode
    int _gridFixedSize;                              // Fixed Grid Size (Points)
    ENUM_GRID_FIXED_CUSTOM_MODE _gridCustomSizeMode; // Custom Size Mode
    string _gridCustomSeries;                        // Grid Size/Multiplier Series
    int _gridATRPeriod;                              // ATR Period (Grid Size)
    ENUM_VALUE_ACTION _gridATRValueAction;           // ATR Action (Grid Size)
    double _gridATRValue;                            // ATR Value (Grid Size)
    int _gridATRMin;                                 // ATR Minimum GAP (Points, 0=No Min)
    int _gridATRMax;                                 // ATR Maximum GAP (Points, 0=No Max)

protected:
    int NormalizeATRGridValue(double gridSize);
    
public:
    CGridGapCalculator(ENUM_GRID_SIZE_MODE gridSizeMode, int gridFixedSize,
                       ENUM_GRID_FIXED_CUSTOM_MODE gridCustomSizeMode, string gridCustomSeries,
                       int gridATRPeriod, ENUM_VALUE_ACTION gridATRValueAction, double gridATRValue, int gridATRMin, int _gridATRMax);
    ~CGridGapCalculator();

public:
    int CalculateNextOrderDistance(int orderCount, double lastOrderPrice, double previousOrderPrice);
};

int CGridGapCalculator::CalculateNextOrderDistance(int orderCount, double lastOrderPrice, double previousOrderPrice)
{
    switch (_gridSizeMode)
    {
        case GRID_SIZE_FIXED:
            return _gridFixedSize;
        case GRID_SIZE_FIXED_CUSTOM:
        {
            switch (_gridCustomSizeMode)
            {
            case GRID_SIZE_CUSTOM_SERIES:
            {
                int nextSizeInSeries = CalculateNextSize(_gridCustomSeries, orderCount, false);
                return NormalizeSize(nextSizeInSeries);
            }
            case GRID_SIZE_CUSTOM_ROLLING:
            {
                int nextSizeInSeries = CalculateNextSize(_gridCustomSeries, orderCount, true);
                return NormalizeSize(nextSizeInSeries);
            }
            case GRID_SIZE_CUSTOM_MULTIPLIER:
            {
                if (previousOrderPrice == 0)
                {
                    // No previous order, this is the first grid order
                    return _MinSize();
                }
                int distance = (int)MathFloor(MathAbs(NormalizeDouble(previousOrderPrice - lastOrderPrice, _Digits) / _Point));
                int nextSizeInSeries = CalculateNextSizeMultiplier(distance, _gridCustomSeries, orderCount);
                return NormalizeSize(nextSizeInSeries);
            }
            }
        }
        case GRID_SIZE_DYNAMIC:
        {
            //TODO: get actual ATR value
            double atrValue = 50;//mATR.GetValue(0, 1);
            switch (_gridATRValueAction)
            {
            case ACTION_NONE:
                return NormalizeATRGridValue((atrValue / _Point));
            case ACTION_MULTIPLY:
                return NormalizeATRGridValue(((atrValue / _Point) * _gridATRValue));
            case ACTION_DEVIDE:
                return NormalizeATRGridValue(((atrValue / _Point) / _gridATRValue));
            }
        }
    }

    return _MinSize();
}

int CalculateNextSize(string series, int lastOrderNumber, bool rolling)
{
    string arSeries[];
    int values[];
    ushort sep = StringGetCharacter(SEPARATOR, 0);
    int count = StringSplit(series, sep, arSeries);
    if (count > 0)
    {
        int size = ArraySize(arSeries);
        ArrayResize(values, size);

        for (int i = 0; i < size; i++)
        {
            values[i] = (int)StringToInteger(arSeries[i]);
        }

        if (lastOrderNumber >= size && !rolling)
        {
            return values[size - 1];
        }
        else if (lastOrderNumber >= size && rolling)
        {
            return values[(lastOrderNumber % size)];
        }
        else
        {
            return values[lastOrderNumber];
        }
    }

    return _MinSize();
}

int CalculateNextSizeMultiplier(int lastSize, string series, int lastOrderNumber)
{
    string arSeries[];
    double values[];
    ushort sep = StringGetCharacter(SEPARATOR, 0);
    int count = StringSplit(series, sep, arSeries);
    double multiplier = 1;
    if (count > 0)
    {
        int size = ArraySize(arSeries);
        ArrayResize(values, size);

        for (int i = 0; i < size; i++)
        {
            values[i] = StringToDouble(arSeries[i]);
        }

        if (lastOrderNumber >= size)
        {
            multiplier = values[size - 1];
        }
        else
        {
            multiplier = values[lastOrderNumber % size];
        }
    }

    return (int)MathFloor(lastSize * multiplier);
}

int CGridGapCalculator::NormalizeATRGridValue(double gridSize)
{
    int value = (int)MathFloor(gridSize);
    if (_gridATRMin != 0 && value < _gridATRMin)
        return _gridATRMin;
    if (_gridATRMax != 0 && value > _gridATRMax)
        return _gridATRMax;
    return value;
}

int NormalizeSize(int size)
{
    return size;
}

int _MinSize()
{
    return 50;
}

CGridGapCalculator::CGridGapCalculator(ENUM_GRID_SIZE_MODE gridSizeMode, int gridFixedSize,
                                       ENUM_GRID_FIXED_CUSTOM_MODE gridCustomSizeMode, string gridCustomSeries,
                                       int gridATRPeriod, ENUM_VALUE_ACTION gridATRValueAction, double gridATRValue,
                                       int gridATRMin, int gridATRMax)
{
    _gridSizeMode = gridSizeMode;
    _gridFixedSize = gridFixedSize;
    _gridCustomSizeMode = gridCustomSizeMode;
    _gridCustomSeries = gridCustomSeries;
    _gridATRPeriod = gridATRPeriod;
    _gridATRValueAction = gridATRValueAction;
    _gridATRValue = gridATRValue;
    _gridATRMin = gridATRMin;
    _gridATRMax = gridATRMax;
}