/*
 * $Id$
 */

// touched
#include "vxh.ch"
#include "cstruct.ch"
#include "colors.ch"
#include "debug.ch"

#define MCS_NONE     0
#define MCS_SIZENWSE 1
#define MCS_SIZEWE   2
#define MCS_SIZENESW 3
#define MCS_SIZENS   4
//#define MCS_SIZENWSE 5
//#define MCS_SIZEWE   6
//#define MCS_SIZENESW 7
//#define MCS_SIZENS   8
#define MCS_SIZEALL  9
#define MCS_ARROW    10
#define MCS_PASTE    11
#define MCS_DRAGGING 12
#define MCS_NO       13

#define DG_ADDCONTROL      1
#define DG_PROPERTYCHANGED 3
#define DG_FONTCHANGED     5
#define DG_DELCOMPONENT    6

//-----------------------------------------------------------------------------------------------

CLASS FormEditor INHERIT TabPage
   DATA RulerWeight   EXPORTED INIT 26
   DATA RulerBorder   EXPORTED INIT  5
   DATA RulerFont     PROTECTED
   DATA RulerVertFont PROTECTED
   DATA RulerBkBrush  EXPORTED INIT GetStockObject( WHITE_BRUSH )
   DATA RulerBrush    EXPORTED
   DATA CtrlMask      EXPORTED
   ACCESS CurForm           INLINE ::Application:Project:CurrentForm

   METHOD Init() CONSTRUCTOR
   METHOD OnDestroy()                INLINE   ::Super:OnDestroy(),;
                                              DeleteObject( ::RulerFont ),;
                                              DeleteObject( ::RulerVertFont ), NIL
   METHOD OnLButtonDown()            INLINE ::SetFocus(), 0
   METHOD Create()
   METHOD OnSetFocus()               INLINE ::CtrlMask:SetFocus()
   METHOD Refresh()                  INLINE ::SetWindowPos(,0,0,0,0,SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER)
   METHOD OnNCCalcSize()
   METHOD OnNCPaint()
   METHOD OnNCRButtonUp()
   //METHOD OnNCHitTest()
   METHOD OnVertScroll()
   METHOD OnHorzScroll(n)            INLINE IIF( n == SB_THUMBPOSITION, IIF( ::CurForm != NIL, ::CtrlMask:CurForm:UpdateSelection(),),),NIL
   METHOD UpdateScroll()
ENDCLASS

//---------------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS FormEditor
   ::__xCtrlName   := "FormEditor"
   ::Super:Init( oParent )
   ::ExStyle       := WS_EX_NOACTIVATE
   ::VertScroll    := .T.
   ::HorzScroll    := .T.
   ::RulerFont     := __FontCreate( "Tahoma", 8 )
   ::RulerVertFont := __FontCreate( "Tahoma", 8,,, .T. )
   ::RulerBrush    := ::System:CurrentScheme:Brush:ToolStripPanelGradientEnd
RETURN Self

//---------------------------------------------------------------------------------------------------

METHOD Create() CLASS FormEditor
   Super:Create()
   ::OriginalRect[3] := ::Width
   ::OriginalRect[4] := ::Height
   //::DockIt()
   ::CtrlMask := ControlMask( Self )
   ::CtrlMask:Create()
RETURN Self

METHOD UpdateScroll() CLASS FormEditor
   IF ::CurForm != NIL .AND. IsWindow( ::CurForm:hWnd )
      ::OriginalRect[3] := ::CurForm:Width  + 30
      ::OriginalRect[4] := ::CurForm:Height + 30
      IF ::CtrlMask != NIL
         ::CtrlMask:xWidth  := MAX( ::OriginalRect[3], ::ClientWidth )
         ::CtrlMask:xHeight := MAX( ::OriginalRect[4], ::ClientHeight )
         ::CtrlMask:MoveWindow()
      ENDIF
      ::__SetScrollBars()
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------
METHOD OnVertScroll(n) CLASS FormEditor
   IF n == SB_THUMBPOSITION
      ::CtrlMask:Top := 0
      ::Redraw()
      IF ::CurForm != NIL
         ::CurForm:UpdateSelection()
      ENDIF
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------

METHOD OnNCCalcSize( nwParam, nlParam ) CLASS FormEditor
   LOCAL nccs
   ( nwParam )
   IF ::Application:ShowRulers
      nccs := (struct NCCALCSIZE_PARAMS)
      nccs:Pointer( nlParam )

      nccs:rgrc[1]:Left   += ::RulerWeight
      nccs:rgrc[1]:Top    += ::RulerWeight
      nccs:CopyTo( nlParam )
   ENDIF
RETURN 0

//---------------------------------------------------------------------------------------------------

METHOD OnNCPaint( nwParam ) CLASS FormEditor
   LOCAL rc, aRect, n := ::CurForm:SelPointSize
   IF ::Application:ShowRulers
      rc := (struct RECT)
      IF !EMPTY( ::CurForm:Selected )
         aRect := ::CurForm:GetSelRect()
         IF EMPTY(aRect)
            aRect := {0,0,0,0}
         ENDIF
         rc:left   := aRect[1]+n
         rc:top    := aRect[2]+n
         rc:right  := aRect[3]-n
         rc:bottom := aRect[4]-n
      ENDIF
      PaintRulers( ::hWnd,;
                   nwParam,;
                   ::RulerWeight,;
                   ::Width,;
                   ::Height,;
                   rc:Value(),;
                   ::HorzScrollPos,;
                   ::VertScrollPos,;
                   ::RulerFont,;
                   ::RulerVertFont,;
                   ::RulerBorder,;
                   ::RulerBkBrush,;
                   ::__nCaptionHeight,;
                   IIF( ::Application:RulerType == 1, 1, 0.39 ),;
                   ::RulerBrush,;
                   IIF( IsThemeActive(), 0, 1 ) )
   ENDIF
RETURN 0

METHOD OnNCRButtonUp( nwParam, nlParam ) CLASS FormEditor
   LOCAL oMenu, oItem
   ( nwParam )
   IF ::Application:ShowRulers
      oMenu := ContextMenu( Self )
      oMenu:Create()

      oItem := MenuItem( oMenu )
      oItem:Text := "Inches"
      oItem:Checked := ::Application:RulerType == 1
      oItem:Action  := {||::Application:RulerType := 1,;
                          ::Application:AppIniFile:WriteInteger( "General", "RulerType", 1 ),;
                          ::Application:DesignPage:Refresh() }
      oItem:Create()

      oItem := MenuItem( oMenu )
      oItem:Separator := .T.
      oItem:Create()

      oItem := MenuItem( oMenu )
      oItem:Text := "Centimeters"
      oItem:Checked :=  ::Application:RulerType == 2
      oItem:Action  := {||::Application:RulerType := 2,;
                          ::Application:AppIniFile:WriteInteger( "General", "RulerType", 2 ),;
                          ::Application:DesignPage:Refresh() }
      oItem:Create()

      oMenu:Show( LOWORD( nlParam ), HIWORD( nlParam ) )
      oMenu:Destroy()
   ENDIF
RETURN 0

//METHOD OnNCHitTest( nwParam, nlParam ) CLASS FormEditor
//   LOCAL uHitTest := DefWindowProc( ::hWnd, WM_NCHITTEST, nwParam, nlParam )
//RETURN IIF( uHitTest==0, HTCAPTION, uHitTest )

//-----------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------

CLASS ControlMask INHERIT Window
   DATA Points              EXPORTED
   DATA __xCtrlName         EXPORTED INIT "ControlMask"
   DATA lTimer              EXPORTED INIT .F.
   DATA RubberBrush         PROTECTED
   DATA RubberBmp           PROTECTED
   DATA DrawBand            EXPORTED INIT .T.
   DATA xGrid               EXPORTED INIT 8
   DATA yGrid               EXPORTED INIT 8
   DATA hBmpGrid            EXPORTED
   DATA xBmpSize            EXPORTED
   DATA yBmpSize            EXPORTED
   DATA hOrderFont          EXPORTED
   DATA lOrderMode          EXPORTED INIT .F.
   DATA nSplitterPos        EXPORTED INIT 0
   DATA xMdiContainer       EXPORTED INIT .F.

   DATA hCursorDrag         EXPORTED
   DATA hCursorNo           EXPORTED
   DATA aPointsCursors      EXPORTED

   ACCESS CurForm           INLINE ::Application:Project:CurrentForm
   ACCESS MdiContainer      INLINE    ::xMdiContainer PERSISTENT
   DATA aPrevRect           PROTECTED
   DATA aCursors            PROTECTED

   METHOD Init() CONSTRUCTOR
   METHOD Create()
   METHOD OnEraseBkGnd()
   METHOD OnLButtonDblClk() INLINE ::CurForm:EditClickEvent()
   METHOD OnMouseMove()
   METHOD OnLButtonDown()
   METHOD OnLButtonUp(n,x,y)
   METHOD OnGetDlgCode()    INLINE DLGC_WANTMESSAGE | DLGC_WANTALLKEYS
   METHOD OnKeyDown(nKey)   INLINE IIF( ::lTimer, ( ::lTimer := .F., ::KillTimer(1) ), ), IIF( ::CurForm != NIL, ::CurForm:MaskKeyDown( Self, nKey ),)
   METHOD OnKeyUp()
   METHOD OnPaint()
   METHOD OnUserMsg()
   METHOD OnTimer()
   METHOD OnDestroy()       INLINE  ::Super:OnDestroy(),;
                                    DeleteObject( ::RubberBrush ),;
                                    DeleteObject( ::hBmpGrid ),;
                                    DeleteObject( ::hOrderFont ),;
                                    NIL
   METHOD Clean()
   METHOD OnContextMenu()
//   METHOD SetGridSize()
   METHOD OnShowWindow()    INLINE ::CtrlMask:SetFocus()
   METHOD DrawOrder()
   METHOD SetMouseShape()
   METHOD DrawSelRect()
ENDCLASS

METHOD Init( oParent ) CLASS ControlMask
   Super:Init( oParent )
   ::ClsName         := "CtrlMask"
   ::__xCtrlName       := "CtrlMask"
   ::ClassBrush  := GetStockObject( NULL_BRUSH )
//   ::ClassStyle      := CS_VREDRAW | CS_HREDRAW
   ::Left            := 0//::Parent:Left
   ::Top             := 0//::Parent:Top
   ::Width           := ::Parent:OriginalRect[3]
   ::Height          := ::Parent:OriginalRect[4]

   ::aCursors        := { LoadCursor(, IDC_SIZENWSE ),;
                          LoadCursor(, IDC_SIZEWE   ),;
                          LoadCursor(, IDC_SIZENESW ),;
                          LoadCursor(, IDC_SIZENS   ),;
                          LoadCursor(, IDC_SIZENWSE ),;
                          LoadCursor(, IDC_SIZEWE   ),;
                          LoadCursor(, IDC_SIZENESW ),;
                          LoadCursor(, IDC_SIZENS   ),;
                          LoadCursor(, IDC_SIZEALL  ),;
                          LoadCursor(, IDC_ARROW    ),;
                          LoadCursor( GetModuleHandle(), "CUR_PASTE" ),;
                          LoadCursor( GetModuleHandle(), "CUR_DRAGGING" ),;
                          LoadCursor(, IDC_NO       ) }

RETURN Self

METHOD SetMouseShape( nPos )
   ::__hCursor := IIF( nPos > 0, ::aCursors[ nPos ], NIL )
   SendMessage( ::hWnd, WM_SETCURSOR )
RETURN Self

METHOD Create() CLASS ControlMask

   ::xGrid := ::yGrid := ::Application:IniFile:ReadInteger( "Settings", "GridSize", ::xGrid )

   ::Style   := WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
   ::ExStyle := WS_EX_TOPMOST | WS_EX_TRANSPARENT
   Super:Create()
   ::RubberBmp   := LoadImage( ::Application:Instance , "RUBBER", IMAGE_BITMAP )
   ::RubberBrush := CreatePatternBrush( ::RubberBmp )
   DeleteObject( ::RubberBmp )
   ::hOrderFont   := __FontCreate( "Tahoma", 16 )
   SetTimer( ::hWnd, 2, 250 )
RETURN Self
//----------------------------------------------------------------------------


METHOD OnTimer( nId ) CLASS ControlMask
   LOCAL pt
   static lOn, aRect
   DEFAULT lOn TO .F.
   SWITCH nId
      CASE 1
         ::lTimer := .F.
         ::ToolTip:Title := NIL
         ::ToolTip:Text := NIL
         ::KillTimer( 1 )
         //SetActiveWindow( ::Application:MainForm:hWnd )
         EXIT

      CASE 2
         IF ::CurForm != NIL .AND. ::CurForm:CtrlParent != NIL .AND. !(::CurForm:CtrlParent==::CurForm) .AND. VALTYPE( ::Application:CurCursor ) == "C" .AND. ::Application:CurCursor == "Splitter"
            KillTimer( ::hWnd, 2 )
            IF !lOn
               lOn := .T.
               GetCursorPos( @pt )
               ScreenToClient( ::CurForm:CtrlParent:hWnd, @pt )

               aRect := _GetWindowRect( ::CurForm:CtrlParent:hWnd )
               aRect := RectScreenToClient( ::hWnd, aRect )

               aRect[1]-=6
               aRect[2]-=6
               aRect[3]+=6
               aRect[4]+=6
               DO CASE
                  CASE pt:x <= 10
                       aRect[3] := aRect[1]+6
                       aRect[2]+=6
                       aRect[4]-=6
                       ::nSplitterPos := 1
                  CASE pt:x >= ::CurForm:CtrlParent:ClientWidth - 10
                       aRect[1] := aRect[3]-5
                       aRect[2]+=6
                       aRect[4]-=6
                       ::nSplitterPos := 3
                  CASE pt:y <= 10
                       aRect[4] := aRect[2]+6
                       aRect[1]+=6
                       aRect[3]-=6
                       ::nSplitterPos := 2
                  CASE pt:y >= ::CurForm:CtrlParent:ClientHeight - 10
                       aRect[2] := aRect[4]-5
                       aRect[1]+=6
                       aRect[3]-=6
                       ::nSplitterPos := 4
                  OTHERWISE
                       SetTimer( ::hWnd, 2, 250 )
                       RETURN 0
               ENDCASE
               ::Drawing:Destroy()
               ::Drawing:Rectangle( aRect[1]+2, aRect[2]+2, aRect[3]-2, aRect[4]-2, C_RED, GetStockObject( NULL_BRUSH ), 2 )
               ::Drawing:Rectangle( aRect[1], aRect[2], aRect[3], aRect[4], C_RED, GetStockObject( NULL_BRUSH ), 2 )
             ELSE
               lOn := .F.
               ::CurForm:InvalidateRect()
            ENDIF
            SetTimer( ::hWnd, 2, 250 )
          ELSEIF VALTYPE( ::Application:CurCursor ) == "C" .AND. ::Application:CurCursor == "Splitter" .AND. aRect != NIL
            ::CurForm:InvalidateRect()
            aRect := NIL
         ENDIF
         EXIT
   END
RETURN 0

METHOD OnKeyUp( nKey ) CLASS ControlMask
   LOCAL aKeys := { VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN }
   IF !::lTimer .AND. ASCAN( aKeys, nKey ) > 0
      ::lTimer := .T.
      ::SetTimer( 1, 2000 )
    ELSEIF nKey == VK_TAB
      ::ToolTip:Title := NIL
      ::ToolTip:Text := NIL
   ENDIF
RETURN NIL

METHOD Clean( aRect, lPaint, lDes ) CLASS ControlMask
   LOCAL aPt
   IF aRect != NIL
      aPt := { aRect[1], aRect[2] }
      _ClientToScreen( ::CurForm:hWnd, aPt )
      _ScreenToClient( ::hWnd, aPt )
      aRect[1] := aPt[1]
      aRect[2] := aPt[2]

      aPt := { aRect[3], aRect[4] }
      _ClientToScreen( ::CurForm:hWnd, aPt )
      _ScreenToClient( ::hWnd, aPt )
      aRect[3] := aPt[1]
      aRect[4] := aPt[2]
   ENDIF
   _InvalidateRect( ::hWnd, aRect, lPaint )
   IF lDes
      ::Parent:InvalidateRect()
   ENDIF
RETURN Self

METHOD OnLButtonUp( n, x, y ) CLASS ControlMask
   LOCAL nX, nY, aCtrl, aActions, nLeft, nTop, aPt

   IF ! ::lOrderMode
      ::ToolTip:Title := NIL
      ::ToolTip:Text := NIL

      IF ::CurForm != NIL .AND. ::Application:CurCursor == NIL
         ::CurForm:MouseDown := .F.
         ::CurForm:CtrlOldPt := NIL
         IF ::Application:Project:PasteOn

            // Paste ---------------------------------------------------------------------------------------
            aActions := {}

            aPt := { x, y }

            _ClientToScreen( ::hWnd, aPt )
            _ScreenToClient( ::CurForm:CtrlParent:hWnd, aPt )

            x := aPt[1]
            y := aPt[2]

            FOR EACH aCtrl IN ::Application:Project:CopyBuffer

                DEFAULT nX TO aCtrl[2]
                DEFAULT nY TO aCtrl[3]

                nLeft := aCtrl[2] + ( x - nX )
                nTop  := aCtrl[3] + ( y - nY )

                AADD( aActions, { DG_ADDCONTROL, n, nLeft, nTop, .F., ::CurForm:CtrlParent, aCtrl[1],, aCtrl[4], aCtrl[5], {}, } )
            NEXT

            ::Application:Project:SetAction( aActions )

            AEVAL( aActions, {|aCtrl| aCtrl[6] := NIL } )
            aActions := NIL

            hb_gcAll()

            ::Application:Project:PasteOn := .F.
            // ---------------------------------------------------------------------------------------------

            ::CurForm:SelectControl( ::CurForm )
            ::BringWindowToTop()
            ::SetFocus()
            ::SetMouseShape( MCS_NONE )

            RETURN 0
         ENDIF
         ::CurForm:CheckMouse( x, y, .T., n )
         ::Application:Project:EditReset(1)
       ELSEIF ::CurForm:CtrlParent != NIL
         aPt := { x, y }

         _ClientToScreen( ::hWnd, aPt )
         _ScreenToClient( ::CurForm:CtrlParent:hWnd, aPt )

         x := aPt[1]
         y := aPt[2]

         ::Application:Project:SetAction( { { DG_ADDCONTROL, n, x, y, .T., ::CurForm:CtrlParent, ::Application:CurCursor,,,1, {}, } }, ::Application:Project:aUndo )
         //::CurForm:AddControl( ::CurForm:CtrlParent, ::Application:CurCursor, x, y, , n )

         ::CurForm:CtrlParent := NIL
      ENDIF
    ELSE
      ::CurForm:MouseDown := .F.
   ENDIF
RETURN NIL

METHOD OnLButtonDown( nwParam, x, y ) CLASS ControlMask
   LOCAL pt, oControl, oPrj := ::Application:Project
   ( nwParam )
   ::SetFocus()

   IF ! ::lOrderMode .AND. ::CurForm != NIL .AND. ::CurForm:ControlSelect( x, y ) == -2
      ::PostMessage( WM_USER + 2222 )

    ELSEIF ::lOrderMode .AND. ::CurForm != NIL

      pt := (struct POINT)
      pt:x := x
      pt:y := y

      ClientToScreen( ::hWnd, @pt )
      oControl := ::CurForm:GetChildFromPoint( pt )

      IF oPrj:__oTabStop != NIL .AND. oControl:Parent:hWnd <> oPrj:__oTabStop:hWnd
         oControl := NIL
      ENDIF

      IF oControl != NIL
         IF oPrj:__oTabStop == NIL
            oControl:Parent:__CurrentPos := 1
            oPrj:__oTabStop := oControl:Parent
         ENDIF

         oControl:TabOrder := oControl:Parent:__CurrentPos
         oControl:Parent:__CurrentPos++

         ::Application:Props:StatusBarPos:Caption := "Next Tab " + XSTR( oControl:Parent:__CurrentPos )
         ::DrawOrder( ::CurForm, "", oControl:Parent )

         ::InvalidateRect()
         ::UpdateWindow()

         IF oControl:Parent:__CurrentPos > LEN( oControl:Parent:Children )
            WITH OBJECT ::Application:Props[ "TabOrderBttn" ]
               :Checked := .F.
               ::Application:Project:TabOrder( :this )
            END
         ENDIF
         IF !::Application:Project:Modified
            ::Application:Project:Modified := .T.
         ENDIF
      ENDIF
   ENDIF
RETURN 0

METHOD OnMouseMove( nwParam, nlParam ) CLASS ControlMask
   ::Super:OnMouseMove( nwParam, nlParam )
   IF ::CurForm != NIL .AND. ! ::lOrderMode
      ::CurForm:MouseDown := ( nwParam == MK_LBUTTON )
      ::CurForm:CheckMouse( LOWORD(nlParam), HIWORD(nLParam),, nwParam )
   ENDIF
RETURN 0

METHOD OnEraseBkGnd() CLASS ControlMask
   IF ::lOrderMode
      ::DrawOrder( ::CurForm, "" )
   ENDIF
RETURN 1

METHOD OnPaint() CLASS ControlMask
   LOCAL x, nLeft, nTop, nRight, nBottom, lDC := .T.
   LOCAL aControl, aPoints, aPoint, aRect, hDC
   LOCAL i := 0
   LOCAL j := 0

   IF ::lOrderMode
      RETURN NIL
   ENDIF

   IF ( ::CurForm == NIL .OR. !::DrawBand  .OR. ! ::CurForm:IsWindow() ) .AND. ! ::lOrderMode
      ::aPrevRect := NIL
      RETURN NIL
   ENDIF

   IF ::CurForm:InActive .OR. Empty( ::CurForm:Selected ) .OR. __clsParent( ::CurForm:Selected[1][1]:ClassH, "COMPONENT" ) .OR. ::CurForm:Selected[1][1]:ClsName == "MenuBar"
      RETURN NIL
   ENDIF


   aRect := ::CurForm:GetSelRect()

   hDC := ::BeginPaint()

   IF aRect != NIL
      nLeft   := aRect[1]
      nTop    := aRect[2]
      nRight  := aRect[3]
      nBottom := aRect[4]

      _DrawFocusRect( hDC, { nLeft   + (::CurForm:SelPointSize/2),;
                             nTop    + (::CurForm:SelPointSize/2),;
                             nRight  - (::CurForm:SelPointSize/2),;
                             nBottom - (::CurForm:SelPointSize/2) } )
   ENDIF

   IF ::Application:CurCursor == NIL
      SelectObject( hDC, GetStockObject( WHITE_BRUSH ) )
      FOR EACH aControl IN ::CurForm:Selected
          IF aControl[1]:Parent != NIL .AND. ! __clsParent( aControl[1]:ClassH, "COMPONENT" ) .AND. ! aControl[1]:ClassName IN {"MENUITEM", "MENUSTRIPITEM"}
             aPoints := ::CurForm:GetPoints( aControl[1] )

             FOR x := 1 TO LEN( aPoints )
                 IF !aControl[1]:__CustomOwner .AND. aControl[1]:__lResizeable[x]
                    aPoint := ACLONE( aPoints[x] )
                    aPoint[3]+=aPoint[1]
                    aPoint[4]+=aPoint[2]
                    Rectangle( hDC, aPoint[1], aPoint[2], aPoint[3], aPoint[4] )
                 ENDIF
             NEXT
          ENDIF
      NEXT

      IF ::CurForm:SelInitPoint != NIL .AND. ::CurForm:SelEndPoint != NIL
         SelectObject( hDC, GetStockObject( NULL_BRUSH ) )
         Rectangle( hDC, ::CurForm:SelInitPoint[1], ::CurForm:SelInitPoint[2], ::CurForm:SelEndPoint[1], ::CurForm:SelEndPoint[2]  )
      ENDIF

      IF ::lOrderMode
         ::DrawOrder( ::CurForm, "" )
      ENDIF
   ENDIF
   ::EndPaint()
RETURN 0

METHOD DrawSelRect( lClear ) CLASS ControlMask
   LOCAL hDC
   static aRect

   DEFAULT aRect TO ARRAY(4)

   hDC := GetDC( ::hWnd )

   IF !lClear .AND. ::CurForm:SelInitPoint != NIL .AND. ::CurForm:SelEndPoint != NIL
      aRect[1] := MIN( ::CurForm:SelInitPoint[1], ::CurForm:SelEndPoint[1] )
      aRect[2] := MIN( ::CurForm:SelInitPoint[2], ::CurForm:SelEndPoint[2] )

      aRect[3] := MAX( ::CurForm:SelInitPoint[1], ::CurForm:SelEndPoint[1] )
      aRect[4] := MAX( ::CurForm:SelInitPoint[2], ::CurForm:SelEndPoint[2] )
   ENDIF

   IF !EMPTY( aRect )
      _DrawFocusRect( hDC, aRect ) //{ ::CurForm:SelInitPoint[1], ::CurForm:SelInitPoint[2], ::CurForm:SelEndPoint[1], ::CurForm:SelEndPoint[2] } )
   ENDIF
   IF lClear
      aRect := NIL
   ENDIF

   ReleaseDC( ::hWnd, hDC )

RETURN NIL


METHOD DrawOrder( oParent, cOrder, oRedraw ) CLASS ControlMask
   LOCAL aRect, aPt, cData, aAlign, x, y, n, hDC, hWnd, hPen, hBrush
   LOCAL hOldFont, hOldPen, hOldBrush

   IF ( oRedraw == NIL .OR. oParent == oRedraw ) .AND. oParent:Children != NIL

      hPen   := CreatePen( PS_SOLID, 1, DarkenColor( GetSysColor( COLOR_BTNFACE ), 40 ) )
      hBrush := CreateSolidBrush( MidColor(GetSysColor(COLOR_WINDOW),GetSysColor(COLOR_HIGHLIGHT)) )

      FOR n := 1 TO LEN( oParent:Children )
          IF __ObjHasMsg( oParent:Children[n], "xTabOrder" )
             oParent:Children[n]:xTabOrder := n
             aPt := {0,0}
             hWnd := oParent:Children[n]:hWnd
             hDC := GetDC( hWnd )
             IF hDC <> 0

                TRY
                   cData := cOrder + ALLTRIM( STR( n ) )

                   SetTextColor( hDC, RGB( 255, 255, 255 ) )
                   hOldFont := SelectObject( hDC, ::hOrderFont )
                   hOldPen   := SelectObject( hDC, GetStockObject( WHITE_PEN ) ) //hPen )
                   hOldBrush := SelectObject( hDC, GetStockObject( BLACK_BRUSH ) ) //hBrush )


                   SetBkMode( hDC, TRANSPARENT )

                   aAlign := _GetTextExtentPoint32( hDC, cData )

                   aRect := { aPt[1], aPt[2], aPt[1]+aAlign[1]+5, aPt[2]+aAlign[2] }

                   Rectangle( hDC, aRect[1], aRect[2], aRect[3], aRect[4] )

                   x := aRect[1] + ((aRect[3]-aRect[1])/2) - (aAlign[1]/2)
                   y := aRect[2]

                   _ExtTextOut( hDC, x, y, ETO_CLIPPED, aRect, cData )

                   SelectObject( hDC, hOldPen )
                   SelectObject( hDC, hOldBrush )
                   SelectObject( hDC, hOldFont )
                   SetTextColor( hDC, RGB( 0,0,0 ) )

                   ReleaseDC( hWnd, hDC )

                 CATCH

                   ReleaseDC( hWnd, hDC )
                   cData := cOrder
                END

                ::DrawOrder( oParent:Children[n], "", oRedraw )
             ENDIF
          ENDIF
      NEXT
      DeleteObject( hPen )
      DeleteObject( hBrush )
   ENDIF
RETURN Self

METHOD OnUserMsg() CLASS ControlMask
   SWITCH ::Msg
      CASE WM_USER + 2222
           MessageBox( GetActiveWindow(), "Only controls in the same parent can be selected", "Wrong Selection", MB_ICONEXCLAMATION )
           RETURN 0
   END
RETURN NIL

METHOD OnContextMenu( x, y ) CLASS ControlMask
   LOCAL aRect, aPt, oMenu, Item, oItem, n
   IF ::CurForm != NIL .AND. LEN( ::CurForm:Selected )==1 .AND. __ObjhasMsg( ::CurForm:Selected[1][1], "GetRectangle" )
      aRect := ::CurForm:Selected[1][1]:GetRectangle()

      aPt := {x,y}
      _ScreenToClient( ::CurForm:Selected[1][1]:Parent:hWnd, aPt )

      IF _PtInRect( aRect, aPt )
         IF __ObjHasMsg( ::CurForm:Selected[1][1], "__IdeContextMenuItems" ) .AND. !EMPTY( ::CurForm:Selected[1][1]:__IdeContextMenuItems )
            n := ::Application:Cursor

            ::Application:Cursor := ::System:Cursor:Arrow
            oMenu := ContextMenu( Self )
            oMenu:Create()

            FOR EACH Item IN ::CurForm:Selected[1][1]:__IdeContextMenuItems
                oItem := MenuItem( oMenu )
                oItem:Text    := Item[1]
                oItem:Action  := Item[2]
                oItem:Cargo   := aPt
                oItem:Create()
            NEXT
            oMenu:Show( x, y )
            ::Application:Cursor := n

         ENDIF
      ENDIF
   ENDIF
RETURN NIL


//-------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------

FUNCTION RectScreenToClient( hWnd, aRect )

   LOCAL aPt

   aPt := { aRect[ 1 ], aRect[ 2 ] }
   _ScreenToClient( hWnd, aPt )
   aRect[ 1 ] := aPt[ 1 ]
   aRect[ 2 ] := aPt[ 2 ]

   aPt := { aRect[ 3 ], aRect[ 4 ] }
   _ScreenToClient( hWnd, aPt )
   aRect[ 3 ] := aPt[ 1 ]
   aRect[ 4 ] := aPt[ 2 ]

RETURN( aRect )

#pragma BEGINDUMP

#include <windows.h>
#include <shlobj.h>

#include "hbapi.h"

HB_FUNC( PAINTRULERS )
{

   HRGN   hRegion;
   HWND   hWnd           = (HWND) hb_parnl(1);
   //WPARAM nwParam        = (WPARAM) hb_parnl(2);
   int    RulerWeight   = hb_parni(3);
   int    nWidth         = hb_parni(4);
   LONG   nHeight        = hb_parnl(5);

   //LONG   hChild         = hb_parnl(6);

   LONG   HorzScrollPos    = hb_parnl(7);
   LONG   VertScrollPos    = hb_parnl(8);
   HANDLE RulerFont     = (HANDLE) hb_parnl(9);
   HANDLE RulerVertFont = (HANDLE) hb_parnl(10);
   int    RulerBorder   = hb_parni(11);
   int    CaptionHeight  = hb_parni(13);
   double iFactor  = hb_parnd(14);
   char buffer[3];
//   HANDLE hOldPen;
   HDC    hDC;
   RECT   rc;
   LPRECT rChild = (LPRECT) hb_param( 6, HB_IT_STRING )->item.asString.value;
   RECT   rPaint;
   POINT  pt;
   float  nPxI;
   float  n10;
   int    n, y, p;
   int    nGap = hb_parni(16);
   float  x, z, i;
   HBRUSH  hFace  = (HBRUSH) hb_parnl(15);//GetSysColorBrush( COLOR_BTNFACE );
   HBRUSH  hWhite = (HBRUSH) hb_parnl(12);

   hRegion = CreateRectRgn( 0, CaptionHeight, nWidth, RulerWeight );

   hDC       = GetDCEx( hWnd, hRegion, DCX_WINDOW | DCX_PARENTCLIP | DCX_CLIPSIBLINGS | DCX_VALIDATE );
   nPxI      = GetDeviceCaps( hDC, LOGPIXELSX )*iFactor;

   //paint the corner
   rc.left   = nGap;
   rc.top    = CaptionHeight + nGap;
   rc.right  = RulerWeight + nGap;
   rc.bottom = CaptionHeight + RulerWeight + nGap;
   FillRect( hDC, &rc, hFace );

   rc.left   = 0;
   rc.top    = 0;
   rc.right  = 0;
   rc.bottom = 0;

   if( rChild )
   {
      pt.x = rChild->left;
      pt.y = rChild->top;
   /*
      // get updated child size
      GetWindowRect( (HWND) hChild, &rChild );
      pt.x = rChild.left;
      pt.y = rChild.top;
      ScreenToClient( hWnd, &pt );
*/
      // Draw not used left space
      if ( pt.x > 0 )
      {
         rc.left   = RulerWeight + nGap;
         rc.top    = CaptionHeight + nGap;
         rc.right  = pt.x + RulerWeight + nGap ;
         rc.bottom = CaptionHeight + RulerWeight + nGap;

         FillRect( hDC, &rc, hFace );
      }


      // Draw the ruler
      rc.left   = ( pt.x - HorzScrollPos > 0 ? pt.x - HorzScrollPos : 0 ) + RulerWeight;
      rc.top    = CaptionHeight + nGap;
      rc.right  = ( ( pt.x + rChild->right - rChild->left - HorzScrollPos ) > 0 ? pt.x + rChild->right - rChild->left - HorzScrollPos : 0 ) + RulerWeight + nGap;
      rc.right  = rc.right < nWidth-5 ? rc.right : nWidth-5;

      rc.bottom = CaptionHeight + RulerWeight + nGap;

      // Draw the ruler

      rPaint.left   = rc.left;
      rPaint.top    = rc.top;
      rPaint.right  = rc.right;
      rPaint.bottom = rc.top+RulerBorder;
      FillRect( hDC, &rPaint, hFace );

      rPaint.left   = rc.left;
      rPaint.top    = rc.bottom-RulerBorder;
      rPaint.right  = rc.right;
      rPaint.bottom = rc.bottom;
      FillRect( hDC, &rPaint, hFace );

      rPaint.left   = rc.left+nGap;
      rPaint.top    = rc.top+RulerBorder;
      rPaint.right  = rc.right  ;
      rPaint.bottom = rc.bottom-RulerBorder;
      FillRect( hDC, &rPaint, hWhite );

      rc.left   = rPaint.right;
      rc.top    = CaptionHeight + nGap;
      rc.right  = nWidth-nGap;
      rc.bottom = CaptionHeight + RulerWeight+nGap;

      if ( rc.left < rc.right )
      {
         FillRect( hDC, &rc, hFace );
      }
    }
    else
    {
      rc.left   = nGap;
      rc.top    = nGap;
      rc.right  = nWidth-nGap;
      rc.bottom = CaptionHeight + RulerWeight + nGap;
      FillRect( hDC, &rc, hFace );
   }

   SetBkMode( hDC, TRANSPARENT );
   SelectObject( hDC, RulerFont );

   y = 10;
   if( iFactor == 0.39 )
   {
      y = 4;
   }
   x = (float) (nPxI / y);

   n = 0;
   for ( i = 0; i < nWidth; i+= nPxI)
   {
       wsprintf(buffer, "%i", n ) ;
       n10  = i - HorzScrollPos + RulerWeight + 1;

       if( n10 > RulerWeight )
       {
          MoveToEx( hDC, n10, CaptionHeight + RulerBorder+3, NULL );
          LineTo( hDC, n10, CaptionHeight + RulerWeight - RulerBorder - 5 );
          TextOut( hDC, n10-2, CaptionHeight + RulerWeight - (RulerBorder*2)-1, buffer, strlen(buffer)  );
       }
       n++;

       for( z = 0; z<y; z++)
       {
          p = 7;
          if( z == (y/2)-1 )
          {
            p = 5;
          }
          if( n10 + (x*(z+1)) > RulerWeight )
          {
             MoveToEx( hDC, n10 + (x*(z+1)), CaptionHeight + RulerBorder+3, NULL );
             LineTo( hDC, n10 + (x*(z+1)), CaptionHeight + RulerWeight - RulerBorder - p );
          }
       }
   }

   ReleaseDC( hWnd, hDC );
   DeleteObject( hRegion );
   hRegion = CreateRectRgn( 0, CaptionHeight+RulerWeight, RulerWeight, nHeight );
   hDC = GetDCEx( hWnd, hRegion, DCX_WINDOW | DCX_PARENTCLIP | DCX_CLIPSIBLINGS | DCX_VALIDATE );

   if( rChild )
   {
      // Draw unused top space

      if ( pt.y > 0 )
      {
         rc.left   = nGap;
         rc.top    = CaptionHeight + RulerWeight + nGap;
         rc.right  = RulerWeight + nGap;
         rc.bottom = pt.y + RulerWeight + nGap + CaptionHeight;

         FillRect( hDC, &rc, hFace );
      }

      // Draw the ruler
      rc.left   = nGap;
      rc.top    = ( pt.y - VertScrollPos > 0 ? pt.y - VertScrollPos : 0 ) + CaptionHeight + RulerWeight;
      rc.right  = RulerWeight + nGap;
      rc.bottom = ( ( pt.y + rChild->bottom - rChild->top - VertScrollPos ) > 0 ? pt.y + rChild->bottom - rChild->top - VertScrollPos : 0 ) + RulerWeight + nGap;
      rc.bottom = (rc.bottom < nHeight-5 ? rc.bottom : nHeight-5)+ CaptionHeight;

      rPaint.left   = rc.left;
      rPaint.top    = rc.top;
      rPaint.right  = rc.left+RulerBorder;
      rPaint.bottom = rc.bottom;
      FillRect( hDC, &rPaint, hFace );

      rPaint.left   = rc.right-RulerBorder;
      rPaint.top    = rc.top;
      rPaint.right  = rc.right;
      rPaint.bottom = rc.bottom;
      FillRect( hDC, &rPaint, hFace );

      rPaint.left   = rc.left+RulerBorder;
      rPaint.top    = rc.top+nGap;
      rPaint.right  = rc.right-RulerBorder;
      rPaint.bottom = rc.bottom;
      FillRect( hDC, &rPaint, hWhite );

      rc.left   = nGap;
      rc.top    = rPaint.bottom > nHeight-5 ? nHeight-5 : rPaint.bottom;
      rc.right  = RulerWeight+nGap;
      rc.bottom = nHeight;

      if ( rc.top < rc.bottom )
      {
         FillRect( hDC, &rc, hFace );
      }
    }
    else
    {
      rc.left   = nGap;
      rc.top    = nGap;
      rc.right  = RulerWeight + nGap;
      rc.bottom = nHeight-nGap;
      FillRect( hDC, &rc, hFace );
   }

   SetBkMode( hDC, TRANSPARENT );
   SelectObject( hDC, RulerVertFont );

   n = 0;
   for ( i = 0; i < nHeight; i+= nPxI)
   {
       wsprintf(buffer, "%i", n ) ;
       n10  = i - VertScrollPos + RulerWeight + 1;

       if( n10 > RulerWeight )
       {
          MoveToEx( hDC, RulerBorder+3, CaptionHeight + n10, NULL );
          LineTo( hDC, RulerWeight - RulerBorder - 5, CaptionHeight + n10 );
          TextOut( hDC, RulerWeight - (RulerBorder*2)-1, CaptionHeight + n10+3, buffer, strlen(buffer)  );
       }
       n++;

       for( z = 0; z<y; z++)
       {
          p = 7;
          if( z == (y/2)-1 )
          {
            p = 5;
          }
          if( n10 + (x*(z+1)) > RulerWeight )
          {
             MoveToEx( hDC, RulerBorder+3, CaptionHeight + n10 + (x*(z+1)), NULL );
             LineTo( hDC, RulerWeight - RulerBorder - p, CaptionHeight + n10 + (x*(z+1)));
          }
       }
   }

   ReleaseDC( hWnd, hDC );
   DeleteObject( hRegion );
}
#pragma ENDDUMP
