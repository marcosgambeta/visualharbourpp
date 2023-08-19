/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// Pager.prg                                                                                            *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "vxh.ch"
#include "debug.ch"

//----------------------------------------------------------------------------------------------------

CLASS PageScroller INHERIT Control

   PROPERTY PageChild    SET ::SetChild(v)
   PROPERTY ButtonHeight SET ::SetButtonHeight(v) DEFAULT 12
   PROPERTY Position     SET ::SetPosition(v)     DEFAULT 0
   PROPERTY ScrollUnits                           DEFAULT 12

   DATA ImageList    EXPORTED
   DATA AllowUnDock  EXPORTED  INIT FALSE
   DATA AllowClose   EXPORTED  INIT FALSE
   DATA EnumPosition EXPORTED  INIT { { "Vertical", "Horizontal" }, {1,2} }

   DATA ImageIndex   PROTECTED

   METHOD Init() CONSTRUCTOR
   METHOD SetChild()
   METHOD SetButtonHeight(n) INLINE ::SendMessage( PGM_SETBUTTONSIZE, 0, n )
   METHOD RecalSize()        INLINE ::SendMessage( PGM_RECALCSIZE, 0, 0 )
   METHOD __OnParentSize()
   METHOD OnParentNotify()
   METHOD Create()           INLINE Super:Create(), ::SetButtonHeight( ::ButtonHeight ), ::SetChild( ::PageChild ), Self
   METHOD SetPosition()
ENDCLASS

//----------------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS PageScroller
   ::ClsName      := "SysPager"
   DEFAULT ::__xCtrlName TO "PageScroller"
   InitCommonControlsEx( ICC_PAGESCROLLER_CLASS + ICC_BAR_CLASSES )
   ::xLeft     := 0
   ::xTop      := 0
   ::xWidth    := oParent:ClientWidth
   ::xHeight   := oParent:ClientHeight
   ::Style     := hb_bitor(WS_CHILD, WS_VISIBLE, WS_CLIPCHILDREN, WS_CLIPSIBLINGS)
   ::Super:Init( oParent )
RETURN Self

//----------------------------------------------------------------------------------------------------

METHOD SetPosition(n) CLASS PageScroller
   ::SetStyle( ::xPosition, .F. )
   ::SetStyle( n, .T. )
RETURN Self

//----------------------------------------------------------------------------------------------------

METHOD SetChild(o) CLASS PageScroller
   IF ::hWnd != NIL
      IF o != NIL
         ::SendMessage( PGM_SETCHILD, 0, o:hWnd )
         ::ScrollUnits := IIF( o:ClsName == "ToolBarWindow32", LoWord( o:GetButtonSize() ), IIF( ::xPosition == 0, o:Height, o:Width ) )
         SetParent( o:hWnd, ::hWnd )
       ELSE
         ::SendMessage( PGM_SETCHILD, 0, NIL )
         ::ScrollUnits := 12
         IF ::PageChild != NIL
            SetParent( ::PageChild:hWnd, ::Parent:hWnd )
         ENDIF
      ENDIF
   ENDIF
RETURN Self

//----------------------------------------------------------------------------------------------------

METHOD __OnParentSize() CLASS PageScroller
   ::xLeft   := 0
   ::xTop    := 0
   ::xWidth  := ::Parent:ClientWidth
   ::xHeight := ::Parent:ClientHeight
   SetWindowPos( ::hWnd, , ::Left, ::Top, ::Width, ::Height, hb_bitor(SWP_NOACTIVATE, SWP_NOOWNERZORDER, SWP_NOZORDER, IIF( ::Application:OsVersion:dwMajorVersion < 5, SWP_DEFERERASE, 0 ) ))
RETURN(self)


//----------------------------------------------------------------------------------------------------

METHOD OnParentNotify( nwParam, nlParam, hdr ) CLASS PageScroller
   LOCAL pg, pgs
   (nwParam)

   DO CASE

      CASE hdr:code == NM_RELEASEDCAPTURE
           RETURN 0

      CASE hdr:code == PGN_SCROLL
           IF ::ScrollUnits != NIL
              pgs := (struct NMPGSCROLL*) nlParam
              pgs:iScroll := ::ScrollUnits
              pgs:CopyTo( nlParam )
           ENDIF
           RETURN 0

      CASE hdr:code == PGN_CALCSIZE
           pg := (struct NMPGCALCSIZE*) nlParam

           SWITCH pg:dwFlag
              CASE PGF_CALCWIDTH
                   IF ::PageChild != NIL
                      IF ::PageChild:ClsName == "ToolBarWindow32"
                         pg:iWidth := ::PageChild:GetHeight()
                       ELSE
                         pg:iWidth := ::PageChild:Width
                      ENDIF
                   ENDIF
                   EXIT
              CASE PGF_CALCHEIGHT
                   IF ::PageChild != NIL
                      IF ::PageChild:ClsName == "ToolBarWindow32"
                         pg:iHeight := ::PageChild:GetHeight()
                       ELSE
                         pg:iHeight := ::PageChild:Height
                      ENDIF
                   ENDIF
                   EXIT
           END
           pg:CopyTo( nlParam )
           RETURN 0

   ENDCASE

RETURN NIL


//----------------------------------------------------------------------------------------------------

