#include <Object.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\SpinEdit.mqh>

#property strict

#define INDENT_LEFT (11)   // indent from left (with allowance for border width)
#define INDENT_TOP (11)    // indent from top (with allowance for border width)
#define INDENT_RIGHT (11)  // indent from right (with allowance for border width)
#define INDENT_BOTTOM (11) // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X (5) // gap by X coordinate
#define CONTROLS_GAP_Y (5) // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH (100) // size by X coordinate
#define BUTTON_HEIGHT (20) // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT (20) // size by Y coordinate
//--- for group controls
#define GROUP_WIDTH (150) // size by X coordinate
#define LIST_HEIGHT (179) // size by Y coordinate
#define RADIO_HEIGHT (56) // size by Y coordinate
#define CHECK_HEIGHT (93) // size by Y coordinate

class CEADialog : public CAppDialog
{

private:
    CEdit m_edit;          // the display field object
    CButton m_button1;     // the button object
    CButton m_button2;     // the button object
    CButton m_button3;     // the fixed button object
    CSpinEdit m_spin_edit; // the up-down object
    CComboBox m_combo_box; // the dropdown list object

public:
    CEADialog(void);
    ~CEADialog(void);

    //--- create
    virtual bool Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2);
    //--- chart event handler
    virtual bool OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

protected:
    //--- create dependent controls
    bool CreateEdit(void);
    bool CreateButton1(void);
    bool CreateButton2(void);
    bool CreateButton3(void);
    bool CreateSpinEdit(void);
    bool CreateComboBox(void);

    //--- handlers of the dependent controls events
    void OnClickButton1(void);
    void OnClickButton2(void);
    void OnClickButton3(void);
    void OnChangeSpinEdit(void);
    void OnChangeComboBox(void);
};
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CEADialog)
ON_EVENT(ON_CLICK, m_button1, OnClickButton1)
ON_EVENT(ON_CLICK, m_button2, OnClickButton2)
ON_EVENT(ON_CLICK, m_button3, OnClickButton3)
ON_EVENT(ON_CHANGE, m_spin_edit, OnChangeSpinEdit)
ON_EVENT(ON_CHANGE, m_combo_box, OnChangeComboBox)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEADialog::CEADialog(void)
{
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CEADialog::~CEADialog(void)
{
}
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CEADialog::Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2)
{
    if (!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))
        return (false);
    //--- create dependent controls
    if (!CreateEdit())
        return (false);
    if (!CreateButton1())
        return (false);
    if (!CreateButton2())
        return (false);
    if (!CreateButton3())
        return (false);
    if (!CreateSpinEdit())
        return (false);    
    if (!CreateComboBox())
        return (false);
    //--- succeed
    return (true);
}
//+------------------------------------------------------------------+
//| Create the display field                                         |
//+------------------------------------------------------------------+
bool CEADialog::CreateEdit(void)
{
    //--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP;
    int x2 = ClientAreaWidth() - INDENT_RIGHT;
    int y2 = y1 + EDIT_HEIGHT;
    //--- create
    if (!m_edit.Create(m_chart_id, m_name + "Edit", m_subwin, x1, y1, x2, y2))
        return (false);
    if (!m_edit.ReadOnly(true))
        return (false);
    if (!Add(m_edit))
        return (false);
    //--- succeed
    return (true);
}
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CEADialog::CreateButton1(void)
{
    //--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP + (EDIT_HEIGHT + CONTROLS_GAP_Y);
    int x2 = x1 + BUTTON_WIDTH;
    int y2 = y1 + BUTTON_HEIGHT;
    //--- create
    if (!m_button1.Create(m_chart_id, m_name + "Button1", m_subwin, x1, y1, x2, y2))
        return (false);
    if (!m_button1.Text("Button1"))
        return (false);
    if (!Add(m_button1))
        return (false);
    //--- succeed
    return (true);
}
//+------------------------------------------------------------------+
//| Create the "Button2" button                                      |
//+------------------------------------------------------------------+
bool CEADialog::CreateButton2(void)
{
    //--- coordinates
    int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
    int y1 = INDENT_TOP + (EDIT_HEIGHT + CONTROLS_GAP_Y);
    int x2 = x1 + BUTTON_WIDTH;
    int y2 = y1 + BUTTON_HEIGHT;
    //--- create
    if (!m_button2.Create(m_chart_id, m_name + "Button2", m_subwin, x1, y1, x2, y2))
        return (false);
    if (!m_button2.Text("Button2"))
        return (false);
    if (!Add(m_button2))
        return (false);
    //--- succeed
    return (true);
}
//+------------------------------------------------------------------+
//| Create the "Button3" fixed button                                |
//+------------------------------------------------------------------+
bool CEADialog::CreateButton3(void)
{
    //--- coordinates
    int x1 = INDENT_LEFT + 2 * (BUTTON_WIDTH + CONTROLS_GAP_X);
    int y1 = INDENT_TOP + (EDIT_HEIGHT + CONTROLS_GAP_Y);
    int x2 = x1 + BUTTON_WIDTH;
    int y2 = y1 + BUTTON_HEIGHT;
    //--- create
    if (!m_button3.Create(m_chart_id, m_name + "Button3", m_subwin, x1, y1, x2, y2))
        return (false);
    if (!m_button3.Text("Locked"))
        return (false);
    if (!Add(m_button3))
        return (false);
    m_button3.Locking(true);
    //--- succeed
    return (true);
}
//+------------------------------------------------------------------+
//| Create the "SpinEdit" element                                    |
//+------------------------------------------------------------------+
bool CEADialog::CreateSpinEdit(void)
{
    //--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP + (EDIT_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y);
    int x2 = x1 + GROUP_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;
    //--- create
    if (!m_spin_edit.Create(m_chart_id, m_name + "SpinEdit", m_subwin, x1, y1, x2, y2))
        return (false);
    if (!Add(m_spin_edit))
        return (false);
    m_spin_edit.MinValue(10);
    m_spin_edit.MaxValue(1000);
    m_spin_edit.Value(100);
    //--- succeed
    return (true);
}
//+------------------------------------------------------------------+
//| Create the "ComboBox" element                                    |
//+------------------------------------------------------------------+
bool CEADialog::CreateComboBox(void)
{
    //--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP + (EDIT_HEIGHT + CONTROLS_GAP_Y) +
             (BUTTON_HEIGHT + CONTROLS_GAP_Y) +
             (EDIT_HEIGHT + CONTROLS_GAP_Y);
    int x2 = x1 + GROUP_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;
    //--- create
    if (!m_combo_box.Create(m_chart_id, m_name + "ComboBox", m_subwin, x1, y1, x2, y2))
        return (false);
    if (!Add(m_combo_box))
        return (false);
    //--- fill out with strings
    for (int i = 0; i < 16; i++)
        if (!m_combo_box.ItemAdd("Item " + IntegerToString(i)))
            return (false);
    //--- succeed
    return (true);
}
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CEADialog::OnClickButton1(void)
{
    m_edit.Text(__FUNCTION__);
}
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CEADialog::OnClickButton2(void)
{
    m_edit.Text(__FUNCTION__);
}
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CEADialog::OnClickButton3(void)
{
    if (m_button3.Pressed())
        m_edit.Text(__FUNCTION__ + "On");
    else
        m_edit.Text(__FUNCTION__ + "Off");
}
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CEADialog::OnChangeSpinEdit()
{
    m_edit.Text(__FUNCTION__ + " : Value=" + IntegerToString(m_spin_edit.Value()));
}
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CEADialog::OnChangeComboBox(void)
{
    m_edit.Text(__FUNCTION__ + " \"" + m_combo_box.Select() + "\"");
}
