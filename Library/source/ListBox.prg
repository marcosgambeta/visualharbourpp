/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// ListBox.prg                                                                                          *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#include "vxh.ch"
#include "uxtheme.ch"

#define CB_SETMINVISIBLE 0x1701
#define CS_DROPSHADOW 131072

//--------------------------------------------------------------------------------------------------------------

CLASS ListBox FROM TitleControl

   ACCESS CurSel       INLINE    ::GetCurSel()

   DATA ImageList      EXPORTED
   DATA OnSelChanged   EXPORTED
   DATA EnumOwnerDraw  EXPORTED  INIT { { "No", "Fixed", "Variable" }, {1,2,3} }

   DATA ImageIndex     PROTECTED
   DATA __nWidth       PROTECTED INIT 0
   DATA __nItemTip     PROTECTED INIT 0
   DATA __tipWnd       PROTECTED
   DATA __OriginalSel  PROTECTED INIT LB_ERR
   DATA __pTipCallBack PROTECTED
   DATA __nTipProc     PROTECTED

   PROPERTY VertScroll        SET ::SetStyle( WS_VSCROLL, v )                     DEFAULT .F.
   PROPERTY HorzScroll        SET ::SetStyle( WS_HSCROLL, v )                     DEFAULT .F.
   PROPERTY IntegralHeight    SET ::SetIntegralHeight( LBS_NOINTEGRALHEIGHT, v )  DEFAULT .F.
   PROPERTY ExtendedSel       SET ::SetStyle( LBS_EXTENDEDSEL, v )                DEFAULT .F.
   PROPERTY MultiColumn       SET ::SetStyle( LBS_MULTICOLUMN, v )                DEFAULT .F.
   PROPERTY NoRedraw          SET ::SetStyle( LBS_NOREDRAW, v )                   DEFAULT .F.
   PROPERTY Notify            SET ::SetStyle( LBS_NOTIFY, v )                     DEFAULT .T.
   PROPERTY Sort              SET ::SetStyle( LBS_SORT, v )                       DEFAULT .F.
   PROPERTY UseTabStops       SET ::SetStyle( LBS_USETABSTOPS, v )                DEFAULT .F.
   PROPERTY WantKeyboardInput SET ::SetStyle( LBS_WANTKEYBOARDINPUT, v )          DEFAULT .F.
   PROPERTY DisableNoScroll   SET ::SetStyle( LBS_DISABLENOSCROLL, v )            DEFAULT .F.
   PROPERTY HasStrings        SET ::SetStyle( LBS_HASSTRINGS, v )                 DEFAULT .T.
   PROPERTY OwnerDraw         SET ::SetDrawStyle(v)                               DEFAULT 1
   PROPERTY ItemToolTips      SET ::__SetItemToolTips(v)                          DEFAULT .F.

   METHOD Init()  CONSTRUCTOR
   METHOD Create()

   METHOD GetString()
   METHOD GetItemRect()
   METHOD GetSelItems()
   METHOD SetDrawStyle()
   METHOD AddItem( cText, lSel )           INLINE ::AddString( cText, lSel )
   METHOD SetCurSel(nLine)                 INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETCURSEL, nLine-1, 0), NIL )
   METHOD SetSel(nLine,lSel)               INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETSEL, IIF(lSel,1,0), MAKELPARAM(nLine, 0)), NIL )
   METHOD FindString(nStart,cStr)          INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_FINDSTRING, IFNIL(nStart,-1,nStart), cStr)+1, NIL )
   METHOD FindStringExact(nStart,cStr)     INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_FINDSTRINGEXACT, IFNIL(nStart,-1,nStart), cStr), NIL )
   METHOD GetCount()                       INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETCOUNT, 0, 0), NIL )
   METHOD GetCurSel()                      INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETCURSEL, 0, 0)+1, NIL )
   METHOD Dir(nAttr, cFileSpec)            INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_DIR, nAttr, cFileSpec), NIL )
   METHOD GetSelCount()                    INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETSELCOUNT, 0, 0), NIL )

   METHOD SelItemRangeEx(nFirst, nLast)    INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SELITEMRANGEEX, nFirst, nLast ), NIL )
   METHOD ResetContent()                   INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_RESETCONTENT, 0, 0 ) , NIL )
   METHOD GetSel(nLine)                    INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETSEL, nLine, 0 ), NIL )
   METHOD GetTextLen( nLine )              INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETTEXTLEN, nLine-1, 0 ), NIL )
   METHOD SelectString( nLine, cText )     INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SELECTSTRING, nLine, cText ), NIL )
   METHOD GetTopIndex( nLine )             INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETTOPINDEX, nLine, 0 ) , NIL )
   //METHOD GetSelItems( nMax, cBuffer )  INLINE IIF( ::hWnd != NIL, SendMessage( ::hWnd, LB_GETSELITEMS, nMax, @cBuffer ), NIL )
   METHOD SetTabStops( nTabs, abTabs )     INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETTABSTOPS, nTabs, abTabs ) , NIL )
   METHOD GetHorizontalExtent()            INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETHORIZONTALEXTENT, 0, 0 ) , NIL )
   METHOD GetText( nLine, cBuffer )
   METHOD GetItemText( nItem )             INLINE ::GetText( nItem )
   METHOD SetHorizontalExtent(nWidth)
   METHOD SetColumnWidth( nWidth )         INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETCOLUMNWIDTH, nWidth, 0 ) , NIL )
   METHOD AddFile( cFile )                 INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_ADDFILE, 0, cFile ), NIL )
   METHOD SetTopIndex( nLine )             INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETTOPINDEX, nLine, 0 ), NIL )
   //METHOD GetItemRect( nLine, bRect )   INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETITEMRECT, nLine, bRect ) , NIL )
   METHOD GetItemData( nLine )             INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETITEMDATA, nLine-1, 0 ) , NIL )
   METHOD SetItemData( nLine, cData )      INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETITEMDATA, nLine-1, cData ) , NIL )
   METHOD SelItemRange( nFrom, nTo, lSel ) INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SELITEMRANGE, IIF( lSel, 1, 0 ), MAKELONG( nFrom, nTo ) ) , NIL )
   METHOD SetAnchorIndex( nLine )          INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETANCHORINDEX, nLine, 0 ), NIL )
   METHOD GetAnchorIndex()                 INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETANCHORINDEX, 0, 0 ) , NIL )
   METHOD SetCaretIndex( nLine, lScroll)   INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETCARETINDEX, nLine, IF (lScroll, 1, 0 ) ) , NIL )
   METHOD GetCaretIndex()                  INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETCARETINDEX, 0, 0 )+1 , NIL )
   METHOD SetItemHeight( nLine, nHeight )  INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETITEMHEIGHT, nLine, nHeight ) , NIL )
   METHOD GetItemHeight( nLine )           INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETITEMHEIGHT, nLine, 0 ) , NIL )
   METHOD SetLocale( nID )                 INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETLOCALE, nID, 0 ) , NIL )
   METHOD GetLocale()                      INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_GETLOCALE, 0, 0 ), NIL )
   METHOD SetCount(nCount)                 INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_SETCOUNT, nCount, 0 ) , NIL )
   METHOD InitStorage( nItems, nBytes )    INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_INITSTORAGE, nItems, nBytes ) , NIL )
   METHOD ItemFromPoint( x,y )             INLINE IIF( ::hWnd != NIL, ::SendMessage( LB_ITEMFROMPOINT, 0, MAKELONG( x, y ) ) , NIL )
   METHOD SetItemText( n, cText, l )       INLINE l := ::GetCurSel() == n, ::DeleteString( n ), ::InsertString( n, cText ), IIF( l, ::SetCurSel(n), )
   METHOD OnDestroy()                      INLINE Super:OnDestroy(), ::__SetItemToolTips(.F.), NIL

   METHOD __SetScrollBars()                INLINE Self

   METHOD AddString()
   METHOD InsertString(nLine,cText)
   MESSAGE DeleteItem METHOD DeleteString
   METHOD DeleteString(nLine)

   METHOD OnGetDlgCode( msg )              INLINE IIF( msg != NIL .AND. msg:message == WM_KEYDOWN .AND. ( msg:wParam == VK_TAB .OR. msg:wParam == VK_ESCAPE ), NIL, DLGC_WANTMESSAGE )

   METHOD OnParentCommand()

   METHOD OnSelChange()    VIRTUAL
   METHOD OnDblClk()       VIRTUAL
   METHOD OnErrSpace()     VIRTUAL
   METHOD OnLBNKillFocus() VIRTUAL
   METHOD OnLBNSetFocus()  VIRTUAL

   METHOD OnHScroll() INLINE NIL
   METHOD OnVScroll() INLINE NIL
   METHOD OnCtlColorListBox()
   METHOD SetIntegralHeight( n, lSet ) INLINE ::SetStyle( n, !lSet )
   METHOD OnMouseMove()
   //METHOD OnEraseBkGnd()
   METHOD __SetItemToolTips()
   METHOD __TipCallBack()
   METHOD __ListBoxMouseMove()
   METHOD __HandleOnPaint()
   METHOD __HandleOnTimer()
   METHOD __TrackMouseEvent()
   METHOD ResetFrame() INLINE ::SetWindowPos(,0,0,0,0,hb_bitor(SWP_FRAMECHANGED, SWP_NOMOVE, SWP_NOSIZE, SWP_NOZORDER))
ENDCLASS

METHOD ListBox:Init( oParent )
   ::ClsName      := "ListBox"
   DEFAULT ::Style   TO hb_bitor(WS_CHILD, WS_VISIBLE, WS_TABSTOP, LBS_NOTIFY, LBS_HASSTRINGS, LBS_NOINTEGRALHEIGHT, WS_CLIPCHILDREN, WS_CLIPSIBLINGS)
   DEFAULT ::__xCtrlName TO "ListBox"
   ::Border       := WS_EX_CLIENTEDGE
   ::Super:Init( oParent )
   ::Width        := 80
   ::Height       := 80
   ::DeferRedraw  := .F.
   IF !EMPTY( ::Events )
      AADD( ::Events[2][2], { "OnSelChange" , "", "" } )
      AADD( ::Events[2][2], { "OnDblClk" , "", "" } )
      AADD( ::Events[2][2], { "OnErrSpace" , "", "" } )
      AADD( ::Events[2][2], { "OnLBNKillFocus" , "", "" } )
      AADD( ::Events[2][2], { "OnLBNSetFocus" , "", "" } )
   ENDIF
RETURN Self

METHOD ListBox:Create()
   ::Super:Create()
   IF ::ItemToolTips
      ::__SetItemToolTips( .T. )
   ENDIF
RETURN Self

//METHOD ListBox:OnEraseBkGnd()
//   IF ::Transparent
//      RETURN 1
//   ENDIF
//RETURN NIL


METHOD ListBox:GetText( nItem )
   LOCAL cBuffer := ""
   IF ::hWnd != NIL
      DEFAULT nItem TO ::GetCurSel()
      IF nItem > 0
         cBuffer := SPACE( ::GetTextLen( nItem ) )
         ::SendMessage( LB_GETTEXT, nItem-1, @cBuffer )
      ENDIF
   ENDIF
RETURN cBuffer

//----------------------------------------------------------------------------------------------------------------
METHOD ListBox:__SetItemToolTips( lTips )
   LOCAL wcex
   IF lTips

      IF IsWindow( ::hWnd )
         wcex := (struct WNDCLASSEX)
         wcex:cbSize         := wcex:SizeOf()
         wcex:style          := hb_bitor(CS_OWNDC, CS_DBLCLKS, CS_SAVEBITS, CS_DROPSHADOW)
         wcex:hInstance      := ::AppInstance
         wcex:hbrBackground  := COLOR_BTNFACE+1
         wcex:lpszClassName  := "CBTT"
         wcex:hCursor        := LoadCursor(, IDC_ARROW )
         wcex:lpfnWndProc    := DefWindowProcAddress()
         RegisterClassEx( wcex )

         ::__tipWnd := CreateWindowEx( WS_EX_TOOLWINDOW, "CBTT", "", WS_POPUP, 0, 0, 0, 0, 0, 0, ::AppInstance )

         IF IsWindow( ::__tipWnd )
            ::__pTipCallBack := WinCallBackPointer( HB_ObjMsgPtr( Self, "__TipCallBack" ), Self )
            ::__nTipProc := SetWindowLong( ::__tipWnd, GWL_WNDPROC, ::__pTipCallBack )
         ENDIF
      ENDIF

    ELSE

      IF IsWindow( ::__tipWnd ) .AND. ::__nTipProc != NIL
         SetWindowLong( ::__tipWnd, GWL_WNDPROC, ::__nTipProc )
         ::__nTipProc := NIL
         //VXH_FreeCallBackPointer( ::__pTipCallBack )
         //::__pTipCallBack := NIL
         ::Parent:PostMessage( WM_VXH_FREECALLBACK, ::__pTipCallBack )
         DestroyWindow( ::__tipWnd )
      ENDIF

   ENDIF
RETURN Self

METHOD ListBox:__TipCallBack( hWnd, nMsg, nwParam, nlParam )
   static lMouseHover := .F.
   SWITCH nMsg
      CASE WM_MOUSEMOVE
           IF ! lMouseHover
              lMouseHover := .T.
              ::__TrackMouseEvent( hWnd, TME_LEAVE )
           ENDIF
           RETURN 0

      CASE WM_PAINT
           RETURN ::__HandleOnPaint( hWnd )

      CASE WM_TIMER
           ::__HandleOnTimer( nwParam )
           EXIT

      CASE WM_LBUTTONDOWN
           lMouseHover := .F.
           ShowWindow( hWnd, SW_HIDE )
           PostMessage( ::hWnd, nMsg, nwParam, nlParam )
           RETURN 0

      CASE WM_MOUSELEAVE
           lMouseHover := .F.
           ::__OriginalSel := LB_ERR
           ShowWindow( hWnd, SW_HIDE )
           RETURN 0
   END
RETURN CallWindowProc( ::__nTipProc, hWnd, nMsg, nwParam, nlParam )

METHOD ListBox:__TrackMouseEvent( hWnd, nFlags )
   LOCAL tme := (struct TRACKMOUSEEVENT)
   tme:cbSize      := tme:SizeOf()
   tme:dwFlags     := nFlags
   tme:hwndTrack   := hWnd
   tme:dwHoverTime := HOVER_DEFAULT
   TrackMouseEvent( tme )
RETURN Self

METHOD ListBox:__ListboxMouseMove( nwParam, aPt )
   LOCAL hDC, hOldFont, cBuf, pt := (struct POINT)
   LOCAL rcBounds := (struct RECT)
   LOCAL rcDraw := (struct RECT)
   LOCAL cRect := space(16)
   LOCAL nCurSel := SendMessage( ::hWnd, LB_ITEMFROMPOINT, 0, MAKELONG( aPt[1], aPt[2] ) )
   HB_SYMBOL_UNUSED(nwParam)

   IF ::__OriginalSel == nCurSel
      RETURN NIL
   ENDIF
   IF nCurSel == 65540 .AND. IsWindowVisible( ::__tipWnd )
      ShowWindow( ::__tipWnd, SW_HIDE )
      ::__OriginalSel := nCurSel
      RETURN NIL
   ENDIF
   IF nCurSel == LB_ERR .OR. nCurSel < 0 .OR. nCurSel >= SendMessage( ::hWnd, LB_GETCOUNT, 0, 0 )
      RETURN NIL
   ENDIF

   ::__OriginalSel := nCurSel

   hDC := GetDC( ::__tipWnd )
   hOldFont := SelectObject( hDC, ::Font:Handle )

   cBuf := space( SendMessage( ::hWnd, LB_GETTEXTLEN, nCurSel, 0 ) + 1 )
   SendMessage( ::hWnd, LB_GETTEXT, nCurSel, @cBuf)

   SendMessage( ::hWnd, LB_GETITEMRECT, nCurSel, @rcBounds)
   rcDraw:left   := rcBounds:left
   rcDraw:top    := rcBounds:top
   rcDraw:right  := rcBounds:right
   rcDraw:bottom := rcBounds:bottom

   DrawText( hDC, cBuf, @rcDraw, hb_bitor(DT_CALCRECT, DT_SINGLELINE, DT_CENTER, DT_VCENTER, DT_NOPREFIX) )

   SelectObject( hDC, hOldFont )
   ReleaseDC( ::__tipWnd, hDC )

   IF rcDraw:right <= rcBounds:right
      ShowWindow( ::__tipWnd, SW_HIDE )
      RETURN NIL
   ENDIF

   InflateRect( @rcDraw, 2, 2 )

   pt:x := rcDraw:left
   pt:y := rcDraw:top
   ClientToScreen( ::hWnd, @pt )
   rcDraw:left := pt:x
   rcDraw:top  := pt:y

   pt:x := rcDraw:right
   pt:y := rcDraw:bottom
   ClientToScreen( ::hWnd, @pt )
   rcDraw:right  := pt:x
   rcDraw:bottom := pt:y

   SetWindowText( ::__tipWnd, cBuf )

   ShowWindow( ::__tipWnd, SW_HIDE )

   SetWindowPos( ::__tipWnd, HWND_TOPMOST, rcDraw:left+1, rcDraw:top, rcDraw:Right-rcDraw:left+4, rcDraw:Bottom-rcDraw:top, hb_bitor(SWP_NOACTIVATE, SWP_SHOWWINDOW) )
   SetTimer( ::__tipWnd, 1, 9000, NIL )
RETURN NIL

//----------------------------------------------------------------------------------------------------------------
METHOD ListBox:__HandleOnPaint( hWnd )
   LOCAL hDC, cPaint, aRect, cText, hOldFont, hTheme
   hDC := _BeginPaint( hWnd, @cPaint )
   aRect := _GetClientRect( hWnd )

   hTheme := OpenThemeData(,"TOOLTIP")
   DrawThemeBackground( hTheme, hDC, TTP_STANDARD, 0, { 0, 0, aRect[3], aRect[4] } )
   CloseThemeData( hTheme )

//   SelectObject( hDC, GetSysColorbrush( COLOR_INFOBK ) )
//   Rectangle( hDC, 0, 0, aRect[3], aRect[4] )

   cText := _GetWindowText( hWnd )
   SetBkMode( hDC, TRANSPARENT )
   hOldFont := SelectObject( hDC, ::Font:Handle )

   _DrawText( hDC, cText, aRect, hb_bitor(DT_SINGLELINE, DT_CENTER, DT_VCENTER, DT_NOPREFIX) )

   SelectObject( hDC, hOldFont )
   _EndPaint( hWnd, cPaint)
RETURN 0

METHOD ListBox:__HandleOnTimer( nwParam )
   KillTimer( ::__tipWnd, nwParam )
   ShowWindow( ::__tipWnd, SW_HIDE)
RETURN Self

//----------------------------------------------------------------------------------------------------------------

METHOD ListBox:AddString( cText, lSel )
   LOCAL n
   IF ::hWnd != NIL
      ::SendMessage( LB_ADDSTRING, 0, cText )
      IF ::HorzScroll
         n := ::Drawing:GetTextExtentPoint32( cText )[1]
         IF n > ::__nWidth
            ::SetHorizontalExtent( n + 3 )
            ::__nWidth := n
         ENDIF
      ENDIF
      DEFAULT lSel TO .F.
      IF lSel
         ::SetCurSel( ::GetCount() )
      ENDIF
   ENDIF
RETURN NIL

METHOD ListBox:InsertString(nLine,cText)
   LOCAL n
   IF ::hWnd != NIL
      ::SendMessage( LB_INSERTSTRING, nLine-1, cText )
      IF ::HorzScroll
         n := ::Drawing:GetTextExtentPoint32( cText )[1]
         IF n > ::__nWidth
            ::SetHorizontalExtent( n + 3 )
            ::__nWidth := n
         ENDIF
      ENDIF
   ENDIF
RETURN NIL

METHOD ListBox:DeleteString(nLine)
   IF ::hWnd != NIL
      ::SendMessage( LB_DELETESTRING, nLine-1, 0)
   ENDIF
RETURN NIL

METHOD ListBox:SetHorizontalExtent( nWidth )
   LOCAL x, nCnt, n
   IF ::hWnd != NIL
      IF nWidth == NIL
         nWidth := 0
         nCnt := ::GetCount()
         FOR x := 1 TO nCnt
             n := ::Drawing:GetTextExtentPoint32( ::GetItemText(x) )[1]
             IF n > nWidth
                nWidth := n
             ENDIF
         NEXT
      ENDIF
      ::SendMessage( LB_SETHORIZONTALEXTENT, nWidth, 0 )
   ENDIF
RETURN NIL

//--------------------------------------------------------------------------------------------------------------

METHOD ListBox:SetDrawStyle(n)
   SWITCH n
      CASE 1
         ::SetStyle( LBS_OWNERDRAWFIXED, .F. )
         ::SetStyle( LBS_OWNERDRAWVARIABLE, .F. )
         EXIT
      CASE 2
         ::SetStyle( LBS_OWNERDRAWVARIABLE, .F. )
         ::SetStyle( LBS_OWNERDRAWFIXED, .T. )
         EXIT
      CASE 3
         ::SetStyle( LBS_OWNERDRAWFIXED, .F. )
         ::SetStyle( LBS_OWNERDRAWVARIABLE, .T. )
         EXIT
   END
RETURN Self

//----------------------------------------------------------------------------------------------------------------

METHOD ListBox:GetString(nLine)
   LOCAL nLen
   LOCAL cBuf
   DEFAULT nLine TO ::CurSel
   cBuf := space(SendMessage(::hWnd, LB_GETTEXTLEN, nLine-1, 0) + 1)
   nLen := SendMessage(::hWnd, LB_GETTEXT, nLine-1, @cBuf)
RETURN( IIF(nLen == LB_ERR, nil, left(cBuf, nLen) ) )

//----------------------------------------------------------------------------------------------------------------

METHOD ListBox:GetItemRect( nLine)
   LOCAL rc := (struct RECT)
   SendMessage( ::hWnd, LB_GETITEMRECT, nLine+1, @rc)
RETURN rc:Array

//----------------------------------------------------------------------------------------------------------------

METHOD ListBox:GetSelItems()
RETURN ListBoxGetSelItems( ::hWnd )

//----------------------------------------------------------------------------------------------------------------

METHOD ListBox:OnParentCommand( nId, nCode, nlParam )
   LOCAL nRet
   DO CASE
      CASE nCode == LBN_SELCHANGE
           nRet := ExecuteEvent( "OnSelChange", Self )
           DEFAULT nRet TO ::OnSelChange( nId, nCode, nlParam )
           IF ::OnSelChanged != NIL
              EVAL( ::OnSelChanged, Self, nCode )
           ENDIF

      CASE nCode == LBN_DBLCLK
           nRet := ExecuteEvent( "OnDblClk", Self )
           DEFAULT nRet TO ::OnDblClk( nId, nCode, nlParam )

      CASE nCode == LBN_ERRSPACE
           nRet := ExecuteEvent( "OnErrSpace", Self )
           DEFAULT nRet TO ::OnErrSpace( nId, nCode, nlParam )

      CASE nCode == LBN_KILLFOCUS
           nRet := ExecuteEvent( "OnLBNKillFocus", Self )
           DEFAULT nRet TO ::OnLBNKillFocus( nId, nCode, nlParam )

      CASE nCode == LBN_SETFOCUS
           nRet := ExecuteEvent( "OnLBNSetFocus", Self )
           DEFAULT nRet TO ::OnLBNSetFocus( nId, nCode, nlParam )

   ENDCASE
RETURN nRet

//----------------------------------------------------------------------------------------------------------------
METHOD ListBox:OnMouseMove( nwParam, nlParam )
   LOCAL x, y, aRect := _GetClientRect( ::hWnd )

   ::Super:OnMouseMove( nwParam, nlParam )

   x := LOWORD( nlParam )
   y := HIWORD( nlParam )

   IF _PtInRect( aRect, {x,y} )
      ::__ListboxMouseMove( nwParam, {x,y} )
   ENDIF
RETURN NIL
/*
//----------------------------------------------------------------------------------------------------------------
METHOD ListBox:OnCtlColorListBox( nwParam )
   LOCAL hBkGnd := ::BkBrush
   IF ::ForeColor != NIL .AND. ::ForeColor != ::__SysForeColor
      SetTextColor( nwParam, ::ForeColor )
   ENDIF
   IF hBkGnd != NIL
      SetBkMode( nwParam, TRANSPARENT )
      RETURN hBkGnd
    ELSEIF ::ForeColor != NIL .AND. ::ForeColor != ::__SysForeColor
      SetBkMode( nwParam, TRANSPARENT )
      IF ::BackColor == ::__SysBackColor
         RETURN GetSysColorBrush( COLOR_BTNFACE )
      ENDIF
   ENDIF
RETURN NIL
*/
//---------------------------------------------------------------------------------------------------
METHOD ListBox:OnCtlColorListBox( nwParam )
   LOCAL hBrush, nFore, nBack, nBorder, nLeftBorder

   nFore := ::ForeColor
   nBack := ::BackColor

   IF nFore != NIL
      SetTextColor( nwParam, nFore )
   ENDIF
   IF nBack != NIL
      SetBkColor( nwParam, nBack )
   ENDIF

   hBrush := ::BkBrush

   IF ::Transparent
      hBrush := ::Parent:BkBrush
      SelectObject( nwParam, hBrush )
      SetBkMode( nwParam, TRANSPARENT )
      nBorder    := (::Height - ( ::ClientHeight + IIF( ! Empty(::Text), ::TitleHeight, 0 ) ) ) / 2
      nLeftBorder:= (::Width-::ClientWidth)/2
      SetBrushOrgEx( nwParam, ::Parent:ClientWidth-::Left-nLeftBorder, ::Parent:ClientHeight-::Top-IIF( ! Empty(::Text), ::TitleHeight, 0 )-nBorder )
   ENDIF

   DEFAULT hBrush TO GetSysColorBrush( COLOR_WINDOW )
RETURN hBrush

