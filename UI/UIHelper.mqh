#include <Object.mqh>


class CUIHelper : public CObject
{
public:
    void DrawPriceLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width=1);
    void RemoveLine(string name);
};



void CUIHelper::RemoveLine(string name)
{
    if (ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);
}

void CUIHelper::DrawPriceLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width=1)
{
    RemoveLine(name);
    
    if (!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
    {
        return;
    }

    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    
    if(width > 1) 
    {
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    } 
}
