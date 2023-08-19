/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// StatusBar.prg                                                                                        *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "vxh.ch"
#include "debug.ch"

//----------------------------------------------------------------------------------------------------

CLASS StatusBar INHERIT Control
   PROPERTY ImageIndex  SET ::SetImageIndex(v) DEFAULT -1
   PROPERTY ImageList   GET __ChkComponent( Self, ::xImageList )
   PROPERTY BackColor   ROOT "Colors" SET ::SendMessage( SB_SETBKCOLOR, 0, v ) DEFAULT GetSysColor( COLOR_BTNFACE )
   PROPERTY Text        SET IIF( ::IsWindow(),;
                               ( ::SendMessage( SB_SIMPLE, LEN( ::Children ) == 0, 0 ),;
                                 ::SendMessage( SB_SETTEXT, SB_SIMPLEID, v ) ), ) DEFAULT ""

   DATA nCurPanelTip     PROTECTED

   ACCESS xCaption       INLINE ::xText
   ASSIGN xCaption(c)    INLINE ::xText := c

   ACCESS Caption        INLINE ::Text
   ASSIGN Caption(c)     INLINE ::Text := c


   EXPORTED:
      //DATA Height        INIT 0
      DATA Width         INIT 0
      DATA Left          INIT 0
      DATA Top           INIT 0
      DATA Border        INIT 0
      DATA AllowClose    INIT .F.
      DATA AllowUndock   INIT .F.
      DATA Dock
      DATA Anchor
      DATA TabStop       INIT .F.
      DATA Transparent   INIT .F.
      DATA ClipChildren  INIT .F.
      DATA ClipSiblings  INIT .F.
      DATA Enabled       INIT .T.

   METHOD Init()         CONSTRUCTOR
   METHOD Create()
   METHOD SetPanels()
   METHOD GetPanelRect()
   METHOD __OnParentSize()
   METHOD OnMouseMove()
   METHOD SetImageIndex()
//   METHOD OnDestroy()      INLINE ::Super:OnDestroy(),  AEVAL( ::Children, {|o| ObjFromHandle( o:hWnd, .T. ) } )
   METHOD OnDrawItem()
ENDCLASS

//----------------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS StatusBar
   ::ClsName   := "msctls_statusbar32"
   ::ThemeName := "Status"
   ::xHeight    := 30
   DEFAULT ::__xCtrlName TO "StatusBar"
   ::Style     := (WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS)
   //::IsContainer   := .T.
   ::Super:Init( oParent )
   IF ::DesignMode
      ::__IdeContextMenuItems := { { "Add Panel", {|| StatusBarPanel( Self ):Create(),;
                                                      ::Application:Project:Modified := .T. } }}
      ::Events := {}
      ::__lResizeable := {.F.,.F.,.F.,.F.,.F.,.F.,.F.,.F.}
      ::__lMoveable   := .F.
   ENDIF
RETURN SELF


//----------------------------------------------------------------------------------------------------

METHOD Create() CLASS StatusBar
   LOCAL n

   ::Top    := ::Parent:ClientHeight - ::Height
   ::Width  := ::Parent:ClientWidth

   ::Dock:Left   := ::Parent
   ::Dock:Right  := ::Parent
   ::Dock:Bottom := ::Parent

   ::Super:Create()

   ::Parent:StatusBar := Self

   TRY
      IF ::Parent:MDIClient != NIL
         ::Parent:MDIClient:Height -= ::Height
         ::Parent:MDIClient:MoveWindow()
      ENDIF
    CATCH
   END
   ::SetImageIndex( ::xImageIndex )
   IF ::DesignMode
      PostMessage( ::Parent:hWnd, WM_SIZE, 0, MAKELPARAM( ::Parent:ClientWidth, ::Parent:ClientHeight ) )
      ::Parent:InvalidateRect()
   ENDIF

   IF ( n := ASCAN( ::Parent:Children, {|o| VALTYPE(o:Dock:Bottom)=="O" .AND. o:Dock:Bottom == o:Parent} ) ) > 0
      ::Parent:Children[n]:Dock:Bottom := Self
      ::Parent:Children[n]:DockIt()
   ENDIF
   ::SendMessage( SB_SETBKCOLOR, 0, ::xBackColor )
RETURN Self

//----------------------------------------------------------------------------------------------------
METHOD SetImageIndex( n ) CLASS StatusBar
   IF ::ImageList != NIL .AND. ::hWnd != NIL
      ::SendMessage( SB_SETICON, 0, ::ImageList:GetImage( n ) )
   ENDIF
RETURN NIL

//----------------------------------------------------------------------------------------------------
METHOD OnDrawItem( nwParam, nlParam, dis ) CLASS StatusBar
   Super:OnDrawItem( nwParam, nlParam, dis )
RETURN NIL

//----------------------------------------------------------------------------------------------------

METHOD __OnParentSize() CLASS StatusBar
   ::Left   := 0
   ::Top    := ::Parent:ClientHeight-::Height
   ::Width  := ::Parent:ClientWidth
   ::SetWindowPos( , ::Left, ::Top, ::Width, ::Height, (SWP_NOACTIVATE|SWP_NOOWNERZORDER|SWP_NOZORDER|SWP_DEFERERASE))
   ::SetPanels( ::Parent:ClientWidth )
RETURN( NIL )

//----------------------------------------------------------------------------------------------------

METHOD OnMouseMove( nwParam, nlParam ) CLASS StatusBar
   LOCAL n, rc, pt := (struct POINT)

   ::Super:OnMouseMove( nwParam, nlParam )

   pt:x := LOWORD( nlParam )
   pt:y := HIWORD( nlParam )

   FOR n := 1 TO LEN( ::Children )
       rc := ::GetPanelRect( n-1 )
       IF PtInRect( rc, pt ) .AND. n != ::nCurPanelTip
          ::Tooltip:Text  := ::Children[n]:ToolTipText
          ::Tooltip:Title := ::Children[n]:ToolTipTitle
          ::Tooltip:Popup()
          ::nCurPanelTip := n
          EXIT
       ENDIF
   NEXT

RETURN 0

//----------------------------------------------------------------------------------------------------

METHOD GetPanelRect( nPanel ) CLASS StatusBar
   LOCAL rc := (struct RECT)
   SendMessage( ::hWnd, SB_GETRECT, nPanel, @rc )
RETURN rc

//----------------------------------------------------------------------------------------------------

METHOD SetPanels( nWidth ) CLASS StatusBar
   LOCAL cSizes := ""
   LOCAL nX     := 0
   LOCAL n, nPart
   LOCAL nParentWidth := IIF( nWidth == NIL, ::Width, nWidth )
   LOCAL nTotalPartsWidth := 0
   LOCAL rc, nLen

   aEval( ::Children, {|o| nTotalPartsWidth += IIF( o:Width <> -1, o:Width, 0 ) } )
   nLen := LEN( ::Children )
   FOR n := 1 TO LEN( ::Children )
      nPart := ::Children[ n ]:Width

      IF nPart == -1
         IF n == nLen
            nX := nPart
         ELSE
            nX += nParentWidth - nTotalPartsWidth
         ENDIF

      ELSE
         nX += nPart
      ENDIF

      cSizes += L2BIN( nX )

      IF LEN( ::Children[n]:Children ) > 0

         rc := ::GetPanelRect( n-1 )

         ::Children[n]:Children[1]:xLeft   := rc:Left + IIF( !::Application:IsThemedXP .OR. !::Theming, 1, 2 )
         ::Children[n]:Children[1]:xTop    := rc:Top  + IIF( !::Application:IsThemedXP .OR. !::Theming, 1, 2 )
         ::Children[n]:Children[1]:xWidth  := ::Children[n]:Width - IIF( !::Application:IsThemedXP .OR. !::Theming, 2, 6 )
         ::Children[n]:Children[1]:xHeight := rc:Bottom - rc:Top  - IIF( !::Application:IsThemedXP .OR. !::Theming, 2, 6 )

         IF ::Application:IsThemedXP .AND. ::Children[n]:Children[1]:__xCtrlName == "ToolBar"
            ::Children[n]:Children[1]:xTop    := 0
            ::Children[n]:Children[1]:xHeight := rc:Bottom
         ENDIF

         ::Children[n]:Children[1]:MoveWindow()
      ENDIF
   NEXT

   ::SendMessage( SB_SETPARTS, nLen, cSizes )
   ::UpdateWindow()
RETURN Self


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------

CLASS StatusBarPanel INHERIT Control
   PROPERTY Text         SET ::SetText(v)
   PROPERTY ImageIndex   SET ::SetImageIndex(v)
   PROPERTY ToolTipText
   PROPERTY ToolTipTitle
   PROPERTY Width        SET ( ::xWidth := v, ::Update() ) DEFAULT 0

   EXPORTED:
      DATA Border        INIT 0
      DATA ToolTip
      DATA Font
      DATA Theming       INIT .F.
      DATA AllowClose    INIT .F.
      DATA AllowUndock   INIT .F.
      DATA Dock
      DATA Anchor
      DATA TabStop       INIT .F.
      DATA Transparent   INIT .F.
      DATA Visible       INIT .T.
      DATA ClipChildren  INIT .F.
      DATA ClipSiblings  INIT .F.
      DATA Enabled       INIT .T.
      DATA BackColor
      DATA ForeColor
      DATA ContextMenu
      DATA Cursor
      DATA hWnd

   DATA Index      PROTECTED
   DATA TabOrder   EXPORTED

   ACCESS ImageList INLINE ::Parent:ImageList

   DATA xLeft                 EXPORTED INIT 0
   ACCESS Left                INLINE ::xLeft
   ASSIGN Left(n)             INLINE ::xLeft := n

   DATA xTop                  EXPORTED INIT 0
   ACCESS Top                 INLINE ::xTop
   ASSIGN Top(n)              INLINE ::xTop := n

   DATA xHeight               EXPORTED INIT 30
   ACCESS Height              INLINE ::xHeight
   ASSIGN Height(n)           INLINE ::xHeight := n

   //ACCESS hWnd                INLINE IIF( ::Parent != NIL, ::Parent:hWnd, 0 ) // Will use statusbar HANDLE for children

   ACCESS xCaption       INLINE ::xText
   ASSIGN xCaption(c)    INLINE ::xText := c

   ACCESS Caption        INLINE ::Text
   ASSIGN Caption(c)     INLINE ::Text := c

   METHOD Init() CONSTRUCTOR
   METHOD GetRect()
   METHOD GetRectangle()

   METHOD __OnParentSize() INLINE 0
   METHOD Create()
   METHOD SetText()
   METHOD SetImageIndex()
   METHOD MoveWindow()     INLINE ::Parent:SetPanels()
   METHOD GetWindowRect()  INLINE ::GetRect():Array
   METHOD SetWindowPos()   INLINE ::Parent:SetPanels()
   METHOD DeferWindowPos() INLINE ::Parent:SetPanels()
   METHOD Destroy()
   METHOD Update()         INLINE ::Parent:SetPanels()
   METHOD IsWindow()       INLINE .T.
   METHOD IsWindowVisible() INLINE .T.
//   error HANDLER OnError()
ENDCLASS

METHOD Init( oParent ) CLASS StatusBarPanel
   ::Parent        := oParent
   ::ImageIndex    := -1
   ::Width         := 30
   ::__lMoveable   := .F.
   ::__lCopyCut    := .F.
   ::ClsName       := ::__xCtrlName := "StatusBarPanel"
   ::__lResizeable := {.F.,.F.,.F.,.F.,.F.,.T.,.F.,.F.}
   ::IsContainer   := .T.
   //::Form          := oParent:Form
   ::__CreateProperty( "StatusBarPanel" )
   IF ::DesignMode
      __SetInitialValues( Self )
   ENDIF
   ::Style  := WS_VISIBLE
   ::Events := {}
   ::Index  := LEN( ::Parent:Children )

   //__SetWindowObjPtr( Self )
RETURN Self

METHOD Create() CLASS StatusBarPanel
   ::hWnd := Seconds()
   IF ::DesignMode
      ::Application:ObjectTree:Set( Self )
   ENDIF
   ::Parent:SendMessage( SB_SIMPLE, .F., 0 )
   AADD( ::Parent:Children, Self )
   ::Parent:SetPanels()
   ::SetImageIndex( ::xImageIndex )
   ::SetText( ::xCaption )
   ::GetRectangle()
   ::__aCltRect   := { ::Left, ::Top, ::Width, ::Height }
   ::__ClientRect := { ::Left, ::Top, ::Width, ::Height }
   ::OriginalRect := { ::Left, ::Top, ::Width, ::Height }
RETURN Self

METHOD Destroy() CLASS StatusBarPanel
   LOCAL n
   IF !EMPTY( ::Children )
      ::Children[1]:Destroy()
   ENDIF

   ADEL( ::Parent:Children, ::Index + 1, .T. )
   FOR n := 1 TO LEN( ::Parent:Children )
       ::Parent:Children[n]:Index := n - 1
   NEXT
   ::Parent:SetPanels()

   ::Parent:SendMessage( SB_SIMPLE, LEN( ::Parent:Children ) == 0, 0 )
   ::Parent:Caption := ::Parent:xCaption
   TRY
      HDel( ::Form:__hObjects, ::xName )
   CATCH
   END
RETURN Self

METHOD GetRectangle() CLASS StatusBarPanel
   LOCAL rc := ::Parent:GetPanelRect( ::Index )
   ::Left   := rc:left
   ::Top    := rc:top
//   ::Width  := rc:right - rc:left
   ::Height := rc:bottom - rc:top
RETURN rc:Array

METHOD GetRect() CLASS StatusBarPanel
   LOCAL pt := (struct POINT), rc := ::Parent:GetPanelRect( ::Index )
   pt:x := rc:left
   pt:y := rc:top
   ClientToScreen( ::Parent:hWnd, @pt )
   rc:left := pt:x
   rc:top  := pt:y

   pt:x := rc:right
   pt:y := rc:bottom
   ClientToScreen( ::Parent:hWnd, @pt )
   rc:right  := rc:left + ::Width //pt:x
   rc:bottom := pt:y
RETURN rc

METHOD SetText( cText ) CLASS StatusBarPanel
   IF ::Index != NIL .AND. ::Parent:IsWindow()
      DEFAULT cText TO ""
      ::Parent:SendMessage( SB_SETTEXT, ::Index, XSTR( cText ) )
   ENDIF
   ::Parent:InvalidateRect()
RETURN NIL

METHOD SetImageIndex( n ) CLASS StatusBarPanel
   IF ::Index != NIL .AND. ::Parent:IsWindow()
      ::Parent:SendMessage( SB_SETICON, ::Index, IIF( n > 0 .AND. ::Parent:ImageList != NIL, ::Parent:ImageList:GetImage( n ), NIL ) )
   ENDIF
RETURN NIL
