/*
 * $Id$
 */

#include "vxh.ch"
#include "debug.ch"
#include "cstruct.ch"
#include "colors.ch"
#include "debug.ch"
#include "commdlg.ch"
#include "fileio.ch"

#define HKEY_LOCAL_MACHINE     (0x80000002)
#define HKEY_CURRENT_USER       0x80000001

#define KEY_ALL_ACCESS              (0xF003F)
#define DG_ADDCONTROL      1
#define XFM_EOL Chr(13) + Chr(10)

#ifdef VXH_ENTERPRISE
   #define VXH_PROFESSIONAL
#endif

//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------

CLASS ToolBox INHERIT TreeView
   DATA nScroll      PROTECTED INIT 0
   DATA LevelFont    PROTECTED
   DATA hPen         PROTECTED
   DATA nImage       PROTECTED

   DATA ActiveItem   EXPORTED
   DATA HoverItem    EXPORTED
   DATA aButtons     EXPORTED
   DATA ComObjects   EXPORTED INIT {}
   DATA hPenShadow   EXPORTED

   METHOD Init() CONSTRUCTOR
   METHOD Create()
   //METHOD ShowStandard()       INLINE ::Expand( ::GetFirstVisibleItem() )

   METHOD OnHScroll( n )       INLINE ::nScroll := n
   METHOD OnDestroy()          INLINE ::Super:OnDestroy(), ::LevelFont:Delete(), DeleteObject( ::hPen ), DeleteObject( ::hPenShadow )
   METHOD OnEraseBkGnd()
   METHOD OnParentNotify()
   METHOD DrawItem()
   METHOD OnGetDlgCode()       INLINE DLGC_WANTALLKEYS
   METHOD OnSelChanged()
   METHOD OnMouseLeave()
   METHOD OnMouseMove()
   METHOD SetControl()
   METHOD OnSysCommand(n)      INLINE IIF( n==SC_CLOSE, (::Hide(),0),)
   //METHOD Disable()            INLINE ::xEnabled := .F., ::InvalidateRect(,.F.)
   //METHOD Enable()             INLINE ::xEnabled := .T., ::InvalidateRect(,.F.)
   METHOD UpdateComObjects()
   METHOD UpdateCustomControls()
   METHOD AddCustomControls()
   METHOD DeleteCustomControls()
   METHOD FindItem()
ENDCLASS

//------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS ToolBox
   LOCAL lPro
   DEFAULT ::__xCtrlName  TO "ToolBox"
   ::Super:Init( oParent )
   ::ShowSelAlways := .T.
   ::TrackSelect   := .T.

   lPro := .F.
   #ifdef VXH_PROFESSIONAL
      lPro := .T.

      WITH OBJECT ::ContextMenu := ContextMenu( Self )
         :Create()
         WITH OBJECT MenuItem( :this )
            :Text := "Add Custom Control"
            :Action  := {|| ::AddCustomControls(lPro) }
            :Create()
         END
         WITH OBJECT MenuItem( :this )
            :Separator := .T.
            :Create()
         END
         WITH OBJECT MenuItem( :this )
            :Text := "Delete Custom Control"
            :Action  := {|| ::DeleteCustomControls(lPro) }
            :Create()
         END
      END

   #endif

RETURN Self
//------------------------------------------------------------------------------------------

METHOD Create() CLASS ToolBox
   LOCAL nIndex, nIcon, o, oPtr, oItem, n, x, lPro

   #ifdef VXH_PROFESSIONAL
    LOCAL oReg, oTypeLib, cId, cProgID, cClsID, aKeys
   #endif

   ::VertScroll := .F.
   ::Super:Create()
   //FlatSB_EnableScrollBar( ::hWnd, SB_BOTH, ESB_ENABLE_BOTH )
   ::SetScrollTime(0)
   ::LevelFont := Font( NIL )
   ::LevelFont:Weight     := 700
   ::LevelFont:Create()
   ::hPen := CreatePen( PS_SOLID, 0, GetSysColor( COLOR_BTNFACE ) )
   ::hPenShadow := CreatePen( PS_SOLID, 0, GetSysColor( COLOR_BTNSHADOW ) )
   ::SetIndent( 15 )
   ::SetItemHeight( ABS( ::Font:Height ) + 9 )

   ::aButtons := { { "All Windows Controls", {} },;
                   { "Standard",             {} },;
                   { "Advanced",             {} },;
                   { "Components",           {} },;
                   { "Data",                 {} },;
                   { "Dialogs",              {} },;
                   { "COM Objects",          {} },;
                   { "Custom Controls",      {} } }

   lPro := .F.
   #ifdef VXH_PROFESSIONAL
      lPro := .T.
   #endif
   //Standard
   AADD( ::aButtons[2][2], { "Button", .T. } )
   AADD( ::aButtons[2][2], { "EditBox", .T. } )
   AADD( ::aButtons[2][2], { "Label", .T. } )
   AADD( ::aButtons[2][2], { "Line", .T. } )
   AADD( ::aButtons[2][2], { "LinkLabel", .T. } )
   AADD( ::aButtons[2][2], { "ListBox", .T. } )
   AADD( ::aButtons[2][2], { "ComboBox", .T. } )
   AADD( ::aButtons[2][2], { "GroupBox", .T. } )
   AADD( ::aButtons[2][2], { "RadioButton", .T. } )
   AADD( ::aButtons[2][2], { "CheckBox", .T. } )
   AADD( ::aButtons[2][2], { "HeaderStrip", .T. } )
   AADD( ::aButtons[2][2], { "UpDown", .T. } )
   AADD( ::aButtons[2][2], { "TrackBar", .T. } )

   //Advanced
   AADD( ::aButtons[3][2], { "ComboBoxEx", .T. } )
   AADD( ::aButtons[3][2], { "CommandLink", .T. } )
   AADD( ::aButtons[3][2], { "CoolMenu", .T. } )
   AADD( ::aButtons[3][2], { "ListView", .T. } )
   AADD( ::aButtons[3][2], { "DataGrid", .T. } )
   AADD( ::aButtons[3][2], { "TreeView", .T. } )
   AADD( ::aButtons[3][2], { "StatusBar", .T. } )
   AADD( ::aButtons[3][2], { "ColorPicker", .T. } )
   AADD( ::aButtons[3][2], { "ProgressBar", .T. } )
   AADD( ::aButtons[3][2], { "TabControl", .T. } )
   AADD( ::aButtons[3][2], { "CoolBar", .T. } )
   AADD( ::aButtons[3][2], { "ToolBar", .T. } )

   AADD( ::aButtons[3][2], { "ExplorerBar", lPro } )
   AADD( ::aButtons[3][2], { "MonthCalendar", lPro } )
   AADD( ::aButtons[3][2], { "OptionBar", lPro } )
   AADD( ::aButtons[3][2], { "RichTextBox", lPro } )
   AADD( ::aButtons[3][2], { "WebBrowser", lPro } )
   //AADD( ::aButtons[3][2], { "WebControl", lPro } )
   AADD( ::aButtons[3][2], { "FreeImage", lPro } )

   AADD( ::aButtons[3][2], { "PageScroller", .T. } )
   AADD( ::aButtons[3][2], { "FolderTree", .T. } )
   AADD( ::aButtons[3][2], { "FolderList", .T. } )
   AADD( ::aButtons[3][2], { "MaskEdit", .T. } )
   AADD( ::aButtons[3][2], { "PictureBox", .T. } )
   AADD( ::aButtons[3][2], { "Panel", .T. } )
   AADD( ::aButtons[3][2], { "Splitter", .T. } )
   AADD( ::aButtons[3][2], { "Animation", .T. } )
   AADD( ::aButtons[3][2], { "DateTimePicker", .T. } )
   AADD( ::aButtons[3][2], { "DriveComboBox", .T. } )
   //AADD( ::aButtons[3][2], { "FontComboBox", .T. } )
   AADD( ::aButtons[3][2], { "ToolStrip", .T. } )
   AADD( ::aButtons[3][2], { "ToolStripContainer", .T. } )
   AADD( ::aButtons[3][2], { "TabStrip", lPro } )

   //Components
   AADD( ::aButtons[4][2], { "Timer", .T. } )
   AADD( ::aButtons[4][2], { "ImageList", .T. } )
   AADD( ::aButtons[4][2], { "ContextMenu", .T. } )
   AADD( ::aButtons[4][2], { "NotifyIcon", .T. } )
   AADD( ::aButtons[4][2], { "ContextStrip", lPro } )
   AADD( ::aButtons[4][2], { "SerialPort", lPro } )
   AADD( ::aButtons[4][2], { "MenuBar", .T. } )
   AADD( ::aButtons[4][2], { "MemoryTable", lPro } )
   AADD( ::aButtons[4][2], { "FtpClient", lPro } )
   AADD( ::aButtons[4][2], { "ServiceController", lPro } )
   AADD( ::aButtons[4][2], { "WinSock", lPro } )
   AADD( ::aButtons[4][2], { "SMTPCDO", lPro } )

   //Data
   //AADD( ::aButtons[5][2], { "BindingSource", .T. } )
   AADD( ::aButtons[5][2], { "SqlConnector", .T. } )
   //AADD( ::aButtons[5][2], { "Database", .T. } )
   AADD( ::aButtons[5][2], { "DataTable", .T. } )
   //AADD( ::aButtons[5][2], { "SqlTable", .T. } )
   AADD( ::aButtons[5][2], { "AdsServer", .T. } )
   AADD( ::aButtons[5][2], { "AdsDataTable", .T. } )
   AADD( ::aButtons[5][2], { "MemoryDataTable", lPro } )

   //Dialogs
   AADD( ::aButtons[6][2], { "ColorDialog", .T. } )
   AADD( ::aButtons[6][2], { "FolderBrowserDialog", .T. } )
   AADD( ::aButtons[6][2], { "OpenFileDialog", .T. } )
   AADD( ::aButtons[6][2], { "SaveFileDialog", .T. } )
   AADD( ::aButtons[6][2], { "PrintDialog", .T. } )
   AADD( ::aButtons[6][2], { "FontDialog", .T. } )
   AADD( ::aButtons[6][2], { "PageSetup", .T. } )
   AADD( ::aButtons[6][2], { "TaskDialog", .T. } )

   //COM
   FOR n := 1 TO LEN( ::ComObjects )
       AADD( ::aButtons[7], { ::ComObjects[n][2], lPro } )
   NEXT

   FOR n := 2 TO LEN( ::aButtons )
       aSort(::aButtons[n][2],,,{|x, y| x[1] < y[1]})

       // Add to "All Windows Controls"
       AEVAL( ::aButtons[n][2], {|a| AADD( ::aButtons[1][2], { a[1], a[2] } ) } )
   NEXT
   aSort(::aButtons[1][2],,,{|x, y| x[1] < y[1]})

   ::ImageList := ImageList( Self, 16, 16 ):Create()
   ::ImageList:AddIcon( "ICO_Pointer" )

   nIndex := 2
   FOR n := 1 TO LEN( ::aButtons )

       oItem := ::AddItem( ::aButtons[n][1] )
       oItem:Cargo := .T.

       oPtr := oItem:AddItem( "Pointer", 1 )
       oPtr:Action := {|o|IIF( o:Parent:Enabled, SetControlCursor(o),) }
       oPtr:Cargo := .T.

       FOR x := 1 TO LEN( ::aButtons[n][2] )

           nIcon := ::ImageList:AddImage( "ICO_" + UPPER( ::aButtons[n][2][x][1] ) )

           o := oItem:AddItem( ::aButtons[n][2][x][1], IIF( nIcon != NIL, nIndex, -1 ) )
           o:Cargo := ::aButtons[n][2][x][2]

           o:PointerItem := oPtr
           IF nIcon != NIL
              nIndex ++
           ENDIF
       NEXT
   NEXT
   ::nImage := ::ImageList:Count
   ::ImageList:AddImage( "ICO_COMOBJECT" )

   #ifdef VXH_PROFESSIONAL
    ::ComObjects    := {}
    oReg := Registry( HKEY_CURRENT_USER, "Software\Visual xHarbour\ComObjects" )
    IF oReg:Open()
       n := 0
       aKeys := oReg:GetKeys()

       FOR n := 1 TO LEN( aKeys )
          IF oReg:Open( aKeys[n][1] )
             cProgID := oReg:ProgID
             cClsID  := oReg:ClsID
             IF cProgID == NIL
                cProgID := oReg:GetValue()
             ENDIF

             DEFAULT cClsID TO cProgID
             TRY
                oTypeLib := LoadTypeLib( cClsID, .F. )
                cId := oTypeLib:Objects[1]:Name
              CATCH
                cId := STRTRAN( cProgID, "." )
             END
             AADD( ::ComObjects, { cId, aKeys[n][1], cProgID, cClsID } )
             oReg:Close()
          ENDIF
       NEXT
       oReg:Close()
       ::UpdateComObjects()
    ENDIF
    ::UpdateCustomControls(lPro,.T.)
   #endif

   ::SetImageList()
   ::ExpandAll()
   ::Items[1]:Toggle()
   ::Items[1]:EnsureVisible()
   ::Enabled := .F.

RETURN Self

METHOD FindItem( cText ) CLASS ToolBox
   LOCAL n, i
   FOR n := 2 TO LEN( ::Items )
       FOR i := 1 TO LEN( ::Items[n]:Items )
           IF ::Items[n]:Items[i]:Text == cText
              RETURN ::Items[n]:Items[i]
           ENDIF
       NEXT
   NEXT
RETURN NIL

METHOD AddCustomControls(lPro) CLASS ToolBox
   WITH OBJECT OpenFileDialog( Self )
      :CheckFileExists := .T.
      :Multiselect     := .F.
      :DefaultExt      := "xfm"
      :Title           := "Add Custom Control File"
      :Filter := "Visual xHarbour Form (*.xfm)|*.xfm"
      IF :Show()
         AADD( ::Application:CControls, :FileName )
         ::UpdateCustomControls(lPro,.T., :FileName)
      ENDIF
   END
RETURN Self

METHOD DeleteCustomControls() CLASS ToolBox
   LOCAL n, oPtr
   IF ( n := ASCAN( ::Application:CControls, {|c| UPPER( STRTRAN( SplitFile(c)[2], ".xfm" ) ) == UPPER( ::SelectedItem:Text ) } ) ) > 0
      ADEL( ::Application:CControls, n, .T. )
      oPtr := ::SelectedItem:PointerItem
      ::SelectedItem:Delete()
      oPtr:Select()
   ENDIF
RETURN Self

METHOD UpdateCustomControls(lPro, lTree, cFileName) CLASS ToolBox
   LOCAL oPtr, n, o, oItem := ::Items[-1]

   lPro := .F.
   #ifdef VXH_PROFESSIONAL
      lPro := .T.
   #endif

   IF lTree .AND. oItem != NIL
      FOR n := 1 TO LEN( oItem:Items )
          oItem:Items[n]:Delete()
          n--
      NEXT
   ENDIF

   oItem:Items := {}

   oPtr := oItem:AddItem( "Pointer", 1 )
   oPtr:Cargo := .T.
   oPtr:Action := {|o|IIF( o:Parent:Enabled, SetControlCursor(o),) }

   aSort( ::Application:CControls,,,{|x, y| x < y})

   FOR n := 1 TO LEN( ::Application:CControls )
       o := oItem:AddItem( STRTRAN( SplitFile( ::Application:CControls[n] )[2], ".xfm" ), ::nImage+1 )
       o:Cargo := lPro
       o:PointerItem := oPtr
       IF cFileName == ::Application:CControls[n]
          o:Select()
       ENDIF
   NEXT
   oPtr:Select()
RETURN Self

METHOD UpdateComObjects() CLASS ToolBox
   LOCAL oPtr, hIcon, n,o, oItem := ::Items[-2], lPro
   lPro := .F.
   #ifdef VXH_PROFESSIONAL
      lPro := .T.
   #endif

   IF oItem != NIL
      FOR n := 1 TO LEN( oItem:Items )
          oItem:Items[n]:Delete()
          ::ImageList:RemoveImage( ::ImageList:Count )
          n--
      NEXT
      oItem:Items := {}

      oPtr := oItem:AddItem( "Pointer", 1 )
      oPtr:Cargo := .T.
      oPtr:Action := {|o|IIF( o:Parent:Enabled, SetControlCursor(o),) }

      aSort( ::ComObjects,,,{|x, y| UPPER(x[2]) < UPPER(y[2])})
      FOR n := 1 TO LEN( ::ComObjects )
          hIcon := GetRegOleBmp( ::ComObjects[n][4] )
          IF !EMPTY( hIcon )
             ::ImageList:AddIcon( hIcon )
             DestroyIcon( hIcon )
           ELSE
             ::ImageList:AddImage( "ICO_COMOBJECT" )
          ENDIF
          o := oItem:AddItem( ::ComObjects[n][2], ::ImageList:Count )
          o:Cargo := lPro
          o:PointerItem := oPtr
      NEXT

   ENDIF
RETURN Self


METHOD OnMouseLeave() CLASS ToolBox
   ::HoverItem := NIL
RETURN NIL

METHOD OnMouseMove() CLASS ToolBox
   LOCAL oItem, pt := (struct POINT)
   GetCursorPos( @pt )
   ScreenToClient( ::hWnd, @pt )
   IF ( oItem := ::HitTest( pt:x, pt:y ) ) != NIL .AND. !(oItem == ::HoverItem)
      ::HoverItem := oItem
      //oItem:Select()
   ENDIF
RETURN Self
//---------------------------------------------------------------------------------------------------

METHOD OnEraseBkGnd( hDC ) CLASS ToolBox
   LOCAL nTop, rc, hItem := ::GetLastVisibleItem()
//   nTop := ::GetExpandedCount() * ::GetItemHeight()
   nTop := 0
   IF !EMPTY( hItem )
      rc := ::GetItemRect( hItem )
      nTop := rc:bottom
      IF nTop >= ::Height
         RETURN 1
      ENDIF
   ENDIF
   _FillRect( hDC, {0,nTop,::Width, ::Height}, ::System:CurrentScheme:Brush:ToolStripPanelGradientEnd )
RETURN 1

METHOD OnParentNotify( nwParam, nlParam, hdr ) CLASS ToolBox
   LOCAL tvcd
   Super:OnParentNotify( nwParam, nlParam, hdr )
   DO CASE
      CASE hdr:code == NM_CUSTOMDRAW
           tvcd := (struct NMTVCUSTOMDRAW)
           tvcd:Pointer( nlParam )
           DO CASE
              CASE tvcd:nmcd:dwDrawStage == CDDS_PREPAINT
                   RETURN CDRF_NOTIFYITEMDRAW

              CASE tvcd:nmcd:dwDrawStage == CDDS_ITEMPREPAINT
                   ::DrawItem( tvcd )
                   RETURN CDRF_SKIPDEFAULT
           ENDCASE
   ENDCASE
RETURN NIL

METHOD DrawItem( tvcd ) CLASS ToolBox
   LOCAL oItem, nState, nBack, nFore, lExpanded, rc, nLeft, nRight, nBottom, aAlign, x, y
   LOCAL hBrush, aRest, cText, hPen, nFlags, hBackBrush, nBackColor, hItemBrush
   LOCAL hBorderPen, hSelBrush, hDC, hOldFont

   rc         := tvcd:nmcd:rc
   oItem      := FindTreeItem( ::Items, tvcd:nmcd:dwItemSpec )

   IF oItem == NIL .OR. rc:Right == 0 .OR. !IsWindowVisible( ::hWnd )
      RETURN NIL
   ENDIF

   hDC        := tvcd:nmcd:hdc
   nBackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd
   hSelBrush  := ::System:CurrentScheme:Brush:ButtonCheckedGradientBegin
   hItemBrush := ::System:CurrentScheme:Brush:MenuItemSelected
   hBackBrush := ::System:CurrentScheme:Brush:ToolStripPanelGradientEnd
   hBorderPen := ::System:CurrentScheme:Pen:MenuItemBorder

   nBack      := nBackColor
   nFore      := GetSysColor( COLOR_BTNTEXT )
   nState     := ::GetItemState( tvcd:nmcd:dwItemSpec, TVIF_STATE )
   lExpanded  := nState & TVIS_EXPANDED != 0

   hOldFont := SelectObject( hDC, ::Font:Handle )
   IF oItem:Level == 0
      nBack := GetSysColor( COLOR_BTNSHADOW )
      hOldFont := SelectObject( hDC, ::LevelFont:Handle )
    ELSEIF nState & TVIS_SELECTED != 0 .AND. ::IsWindowEnabled() .AND. oItem:Cargo
      nBack := ::System:CurrentScheme:MenuItemSelected
   ENDIF

   cText := oItem:Text
   SetBkColor( hDC, nBack )
   SetTextColor( hDC, nFore )

   nLeft   := -::nScroll+14
   nRight  := rc:right
   nBottom := rc:bottom

   aAlign  := _GetTextExtentPoint32( hDC, cText )

   x := nLeft + 10
   y := rc:top + ( ( rc:bottom - rc:top )/2 ) - ( aAlign[2]/2 )

   IF oItem:Level > 0
      x += 5
   ENDIF

   _FillRect( hDC, { rc:left, rc:top, rc:right, rc:bottom }, hBackBrush )

   IF oItem:Level == 0
      rc:top ++
      //FillGradient( hDC, rc, GetSysColor( COLOR_BTNSHADOW ), GetSysColor( COLOR_BTNFACE ) )
      FillGradient( hDC, rc, ::System:CurrentScheme:ToolStripGradientEnd, ::System:CurrentScheme:ToolStripGradientBegin )
      rc:top --
      hBrush := SelectObject( hDC, GetStockObject( NULL_BRUSH ) )
      hPen := SelectObject( hDC, ::hPenShadow )
      Rectangle( hDC, rc:left, rc:bottom-1, rc:right, rc:bottom )
      SelectObject( hDC, hPen )
      SelectObject( hDC, hBrush )
   ENDIF

   IF !::IsWindowEnabled() .OR. !oItem:Cargo
      IF oItem:Level > 0
         SetTextColor( hDC, ::System:Colors:GrayText )
      ENDIF
   ENDIF
   IF oItem:Level > 0
      IF oItem:Cargo .AND. ( ( ::HoverItem != NIL .AND. oItem == ::HoverItem ) .OR. ( ::ActiveItem != NIL .AND. oItem == ::ActiveItem ) )//:Level > 0 .AND. nState & TVIS_SELECTED != 0
         hBrush := SelectObject( hDC, hItemBrush )
         hPen := SelectObject( hDC, hBorderPen )
         Rectangle( hDC, rc:left, rc:top, rc:right, rc:bottom )
         SelectObject( hDC, hPen )
         SelectObject( hDC, hBrush )
         SetBkColor( hDC, ::System:CurrentScheme:MenuItemSelected )
      ENDIF
   ENDIF

   nFlags := ETO_CLIPPED | ETO_OPAQUE
   IF oItem:Level == 0
      SetBkMode( hDC, TRANSPARENT )
      nFlags := 0
   ENDIF

   IF !( oItem == ::HoverItem ) .AND. nState & TVIS_SELECTED != 0 .AND. ::IsWindowEnabled() .AND. oItem:Cargo
      hBrush := SelectObject( hDC, hSelBrush )
      hPen := SelectObject( hDC, hBorderPen )
      Rectangle( hDC, rc:left, rc:top, rc:right, rc:bottom )
      SelectObject( hDC, hPen )
      SelectObject( hDC, hBrush )
      SetBkColor( hDC, ::System:CurrentScheme:ButtonCheckedGradientEnd )
   ENDIF

   _ExtTextOut( hDC, x, y, nFlags, { rc:left+1, rc:top+1, rc:right-1, rc:bottom-1 }, cText  )

   SetBkMode( hDC, OPAQUE )

   IF oItem:Level > 0
      IF ::IsWindowEnabled() .AND. oItem:Cargo
         ::ImageList:DrawImage( hDC, oItem:ImageIndex, 5, rc:top+2 )
       ELSE
         ::ImageList:DrawDisabled( hDC, oItem:ImageIndex, 5, rc:top+2 )
      ENDIF
   ENDIF

   aRest := { rc:Left, rc:bottom, rc:right, ::ClientHeight }

   IF oItem:Level == 0
      y := rc:top + ( ( rc:bottom - rc:top ) / 2 ) - ( 9/2 )
      DrawMinusPlus( hDC, 5, y, lExpanded, .T., C_BLACK, 9, 9/2 )
   ENDIF
   SelectObject( hDC, hOldFont )
RETURN 0

METHOD OnSelChanged( oItem ) CLASS ToolBox
   IF ::Enabled .AND. LEN( oItem:Items ) == 0
      IF !oItem:Cargo
         ::Form:MessageBox( oItem:Text + " is reserved for versions Professional and Enterprise", "Version", MB_ICONINFORMATION )
         IF ::PreviousItem != NIL
            ::PreviousItem:Select()
          ELSE
            oItem:PointerItem:Select()
         ENDIF
       ELSE
         SetControlCursor( oItem )
      ENDIF
   ENDIF
RETURN 0

METHOD SetControl( cName, nwParam, x, y, oParent, nWidth, nHeight, lSelect, oCmpBtn, aProps, oCtrl ) CLASS ToolBox
   EXTERN Button, UpDown, TrackBar
   EXTERN EditBox
   EXTERN Label
   EXTERN Line
   EXTERN LinkLabel
   EXTERN ListBox
   EXTERN ComboBox//, FontComboBox
   EXTERN GroupBox
   EXTERN RadioButton
   EXTERN CheckBox
   EXTERN HeaderStrip

   //Advanced
   EXTERN ComboBoxEx
   EXTERN CoolMenu
   EXTERN CommandLink
   EXTERN ListView
   EXTERN DataGrid
   EXTERN TreeView
   EXTERN StatusBar
   EXTERN ColorPicker
   EXTERN ProgressBar
   EXTERN TabControl
   EXTERN CoolBar
   EXTERN ToolBar
   #ifdef VXH_PROFESSIONAL
      EXTERN ExplorerBar
      EXTERN MonthCalendar
      EXTERN OptionBar
      EXTERN RichTextBox
      EXTERN WebBrowser
      //EXTERN WebControl
      EXTERN FreeImage
      EXTERN SMTPCDO
   #endif

   EXTERN PageScroller
   EXTERN FolderTree
   EXTERN FolderList
   EXTERN MaskEdit
   EXTERN PictureBox
   EXTERN Panel
   EXTERN Splitter
   EXTERN Animation
   EXTERN DateTimePicker
   EXTERN DriveComboBox
   EXTERN ToolStrip
   EXTERN ToolStripContainer

   //Components
   EXTERN Timer
   EXTERN ImageList
   EXTERN ContextMenu
   EXTERN NotifyIcon
   #ifdef VXH_PROFESSIONAL
      EXTERN ContextStrip
      EXTERN SerialPort
      EXTERN MemoryTable
      EXTERN FtpClient
      EXTERN ServiceController
      EXTERN WinSock
      EXTERN CustomControl
      EXTERN MemoryDataTable
      EXTERN TaskDialog
   #endif

   //Data
   EXTERN Database
   EXTERN BindingSource
   EXTERN SqlConnector
   EXTERN DataTable
   EXTERN AdsDataTable
   EXTERN SqlTable

   //Dialogs
   EXTERN ColorDialog
   EXTERN FolderBrowserDialog
   EXTERN OpenFileDialog
   EXTERN SaveFileDialog
   EXTERN PrintDialog
   EXTERN FontDialog
   EXTERN PageSetup

   LOCAL hPointer, oControl, oBand, n, aCtrl, cCC
   IF EMPTY( cName )
      RETURN .F.
   ENDIF
   IF VALTYPE( cName ) == "A"
      aCtrl := ACLONE( cName )
      cName := "ActiveX"
      DEFAULT aProps TO {}
      AADD( aProps, {"__xCtrlName", aCtrl[1] } )
      AADD( aProps, {"ProgID", aCtrl[3] } )
      AADD( aProps, {"ClsID", aCtrl[4] } )
   ENDIF

   IF UPPER( cName ) == "FORM"
      RETURN ::Application:Project:AddWindow()
   ENDIF

   DEFAULT lSelect TO .T.

   IF cName == "Band"
      cName := "CoolBarBand"
   ENDIF

   IF AT( "\", cName ) > 0
      cCC := cName
      cName := "CustomControl"
   ENDIF

   hPointer := HB_FuncPtr( cName )

   IF hPointer != NIL .AND. oParent != NIL
      ::Application:Project:Modified := .T.

      IF cName == "Splitter"
         IF ::Application:DesignPage:CtrlMask:nSplitterPos == NIL .OR. ::Application:DesignPage:CtrlMask:nSplitterPos == 0
            IF ::Application:Props[ "PointerBttn" ]:Checked
               TRY
                  ::ActiveItem:PointerItem:Select()
               CATCH
               END
               ::Application:Project:CurrentForm:CtrlMask:SetMouseShape( 0 )
            ENDIF
            RETURN NIL
         ENDIF
         oControl := HB_Exec( hPointer, ,oParent:Parent )
         oControl:Position := ::Application:DesignPage:CtrlMask:nSplitterPos
         oControl:Owner := oParent
       ELSEIF cName == "CMenuItem" .AND. !EMPTY( aProps ) .AND. ( n := ASCAN( aProps, {|a| a[1]=="POSITION"} ) ) > 0
         oControl := HB_Exec( hPointer, , oParent,, aProps[n][2] )
       ELSE
         //oControl := HB_Exec( hPointer, , IIF( cName == "BindingSource", ::Application:Project:AppObject, oParent ) )

         IF cCC != NIL

            oControl := CustomControl()
            oControl:Reference   := cCC
            oControl:__xCtrlName := STRTRAN( SplitFile( cCC )[2], ".xfm" )
            oControl:Init( oParent )

          ELSE
            oControl := HB_Exec( hPointer, , oParent )

         ENDIF


         IF nWidth != NIL
            IF oControl:__xCtrlName == "GridColumn"
               oControl:xWidth  := nWidth
               oControl:xHeight := nHeight
             ELSE
               oControl:Width  := nWidth
               oControl:Height := nHeight
            ENDIF
         ENDIF
      ENDIF

      IF ! __clsParent( oControl:ClassH, "COMPONENT" )
         IF __objHasMsg( oControl, "Left" )
            oControl:Left    := x
            oControl:Top     := y
         ENDIF
         IF aProps == NIL
            oControl:Text := oControl:Name
         ENDIF
         TRY
            oControl:ToolTip := NIL
          CATCH
         END
         DO CASE
            CASE cName == "CoolBar"
                 oControl:Left    := 0
                 oControl:Top     := 0
                 IF !EMPTY( aProps )
                    SetCtrlProps( oControl, aProps )
                 ENDIF
                 oControl:Create()

                 oBand := CoolBarBand( oControl )
                 oBand:MinWidth  := 60
                 oBand:MinHeight := 20
                 oBand:Break     := .T.
                 IF ABS( oBand:Font:Height ) + 9 > 20
                    oBand:MinHeight := ABS( oBand:Font:Height ) + 11
                 ENDIF
                 oBand:Create()

            CASE cName == "ListView"
                 oControl:Text := NIL
                 IF !EMPTY( aProps )
                    SetCtrlProps( oControl, aProps )
                 ENDIF
                 oControl:Create(.T.)

            CASE cName == "TreeView"
                 IF !EMPTY( aProps )
                    SetCtrlProps( oControl, aProps )
                 ENDIF
                 oControl:Create(.T.)

            CASE cName == "ListBox"
                 IF !EMPTY( aProps )
                    SetCtrlProps( oControl, aProps )
                 ENDIF
                 oControl:Create()

            OTHERWISE

                 IF !EMPTY( aProps )
                    SetCtrlProps( oControl, aProps )
                 ENDIF
                 IF !lSelect .AND. oControl:__xCtrlName == "DataGrid"
                    RETURN oControl
                 ENDIF
                 oControl:Create()

         ENDCASE
         IF __objHasMsg( oControl, "InvalidateRect" )
            oControl:InvalidateRect()
         ENDIF
       ELSE
         IF cName == "ImageList" .AND. oControl:Handle == NIL
            IF !EMPTY( aProps )
               SetCtrlProps( oControl, aProps )
            ENDIF
            oControl:Create()
          ELSEIF cName IN { "MenuBar", "ContextStrip" }
            oControl:Create()
         ENDIF
      ENDIF

      // Restore Mouse Pointer
      IF nwParam != MK_CONTROL .AND. ::Application:Props[ "PointerBttn" ]:Checked
         TRY
            ::ActiveItem:PointerItem:Select()
         CATCH
         END
         ::Application:Project:CurrentForm:CtrlMask:SetMouseShape( 0 )
      ENDIF

      IF lSelect
         ::Application:Project:CurrentForm:SelectControl( oControl )
      ENDIF

      ::Application:Project:CurrentForm:RedrawWindow( , , RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW | RDW_INTERNALPAINT )

      ::Application:Project:EditReset(1)
      IF oCmpBtn != NIL .AND. lSelect
         oCmpBtn:Select()
      ENDIF
      ::Application:Props:StatusBarPos:Text := ""
      IF ::Application:Props[ "PointerBttn" ]:Checked
         ::Application:Project:CurrentForm:CtrlMask:SetMouseShape( 0 )
      ENDIF
      ::Application:Project:CurrentForm:MouseDown := .F.
   ENDIF

   oCtrl := oControl
RETURN IIF( !lSelect, oControl, NIL )

