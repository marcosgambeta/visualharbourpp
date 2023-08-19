/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// Link.prg                                                                                             *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#include "vxh.ch"

#define LM_HITTEST        (WM_USER + 768)
#define LM_GETIDEALHEIGHT (WM_USER + 769)
#define LM_SETITEM        (WM_USER + 770)
#define LM_GETITEM        (WM_USER + 771)

/* SysLink links flags */

#define LIF_ITEMINDEX   (1)
#define LIF_STATE       (2)
#define LIF_ITEMID      (4)
#define LIF_URL         (8)

/* SysLink links states */

#define LIS_FOCUSED     (1)
#define LIS_ENABLED     (2)
#define LIS_VISITED     (4)

//-----------------------------------------------------------------------------------------------

CLASS Link INHERIT Control
   DATA AllowUnDock          EXPORTED INIT FALSE
   DATA AllowClose           EXPORTED INIT FALSE

   PROPERTY Text GET ::GetText() SET ::SetText(v) DEFAULT ""

   METHOD Init()  CONSTRUCTOR
   METHOD Create()
   METHOD OnParentNotify()
   METHOD GetText()
   METHOD SetText()
ENDCLASS

//-----------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS Link
   ::__xCtrlName := "SysLink"
   ::ClsName     := "SysLink"
   ::Style       := hb_bitor(WS_CHILD, WS_VISIBLE, WS_TABSTOP, WS_CLIPCHILDREN, WS_CLIPSIBLINGS)
   ::Width       := 80
   ::Height      := 16
   ::xText    := E"Sample link to web <A HREF=\"http://www.microsoft.com\">Microsoft</A>, and to <A HREF=\"http://www.xharbour.com\">xHarbour</A>"
   ::Super:Init( oParent )
RETURN Self

METHOD GetText() CLASS Link
   LOCAL cText := ::xText
//   cText := StrTran( cText , "\\", "\" )
//   cText := StrTran( cText , '\"', '"' )
RETURN cText

METHOD SetText() CLASS Link
   LOCAL cText := ::xText
   cText := StrTran( cText , "\", "\\" )
   cText := StrTran( cText , '"', '\"' )
   ::xText := cText
   SetWindowText( ::hWnd, ::xText )
RETURN cText

METHOD Create() CLASS Link
   ::xText := StrTran( ::xText, "\\", "\" )
   ::xText := StrTran( ::xText, '\"', '"' )
   Super:Create()
RETURN Self

METHOD OnParentNotify( nwParam, nlParam, hdr ) CLASS Link
   LOCAL n, pNmLink, cText := "", aArray
   (nwParam)
   SWITCH hdr:code
      CASE NM_RETURN
      CASE NM_CLICK
           pNmLink := (struct NMLINK*) nlparam

           aArray := ACLONE( pNmLink:item:szUrl:Array )
           FOR n := 1 TO LEN( aArray )
               IF aArray[n] > 0
                  cText += CHR( aArray[n] )
               ENDIF
           NEXT

           SWITCH pNmLink:item:iLink
              CASE 0
                  EXIT
              CASE 1
                  EXIT
           END
           EXIT
   END
RETURN NIL
