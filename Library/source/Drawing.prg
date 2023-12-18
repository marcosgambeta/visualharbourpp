/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// Drawing.prg                                                                                          *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#include "vxh.ch"

//------------------------------------------------------------------------------------------------
static s_oSelf

CLASS Drawing
   DATA Owner       EXPORTED
   DATA xhDC        EXPORTED
   DATA cPaint      EXPORTED
   DATA __aFonts     PROTECTED

   ACCESS hDC       INLINE ::RefreshDC(), ::xhDC

   METHOD Init() CONSTRUCTOR

   METHOD Destroy()
   METHOD RefreshDC()
   METHOD GetTextExtentPoint32()
   METHOD GetTextExtentExPoint()
   METHOD DrawFrameControl()
   METHOD FillRect()
   METHOD Rectangle()
   METHOD EnumFonts()
   METHOD BeginPaint()
   METHOD GetDC()                                        INLINE ::xhDC := GetDC( ::Owner:hWnd ), Self
   METHOD ReleaseDC()                                    INLINE ReleaseDC( ::Owner:hWnd, ::xhDC ),  ::xhDC := NIL, Self
   METHOD EndPaint()                                     INLINE _EndPaint( ::Owner:hWnd, ::cPaint), ::xhDC := NIL, ::cPaint := NIL, Self
   METHOD SelectObject( hObj )                           INLINE SelectObject( ::hDC, hObj )
   METHOD SetPixel( x, y, nColor )                       INLINE SetPixel( ::hDC, x, y, nColor )
   METHOD GetPixel( x, y )                               INLINE GetPixel( ::hDC, x, y )
   METHOD SetBkColor( nColor )                           INLINE SetBkColor( ::hDC, nColor )
   METHOD SetTextColor( nColor )                         INLINE SetTextColor( ::hDC, nColor )
   METHOD SetTextAlign( nAlign )                         INLINE SetTextAlign( ::hDC, nAlign )
   METHOD ExtTextOut( x, y, nFlags, aRect, cText, aDx )  INLINE _ExtTextOut( ::hDC, x, y, nFlags, aRect, cText, aDx )
   METHOD PolyLine( aReg )                               INLINE _PolyLine( ::hDC, aReg )
   METHOD DrawFocusRect( aRect )                         INLINE _DrawFocusRect( ::hDC, aRect )
   METHOD GetClipBox()
   METHOD GetDeviceCaps( nFlags )                        INLINE GetDeviceCaps( ::hDC, nFlags )
   METHOD SetBkMode( nMode )                             INLINE SetBkMode( ::hDC, nMode )
   METHOD DrawText( cText, aRect, nFlags )               INLINE _DrawText( ::hDC, cText, aRect, nFlags )
   METHOD GetTextMetrics()
   METHOD DrawEdge( aRect, nFlags, nState )              INLINE _DrawEdge( ::hDC, aRect, nFlags, nState )
   METHOD DrawThemeParentBackground( aRect )             INLINE DrawThemeParentBackground( ::Owner:hWnd, ::hDC, aRect )
   METHOD DrawIcon( nLeft, nTop, hIcon )                 INLINE DrawIcon( ::hDC, nLeft, nTop, hIcon )
   METHOD DrawSpecialChar( aRect, nSign, lBold, nPoint ) INLINE __DrawSpecialChar( ::hDC, aRect, nSign, lBold, nPoint )

   METHOD DrawThemeBackground( hTheme, nPartId, nStateId, aRect, aClipRect ) INLINE DrawThemeBackground( hTheme, ::hDC, nPartId, nStateId, aRect, aClipRect )
   METHOD Draw3DRect( rcItem, oTopLeftColor, oBottomRightColor )             INLINE __Draw3DRect( ::hDC, rcItem, oTopLeftColor, oBottomRightColor )
   METHOD CleanEnumFont() INLINE ::__aFonts := NIL
ENDCLASS

//------------------------------------------------------------------------------------------------

METHOD Drawing:Init( oOwner )
   ::Owner := oOwner
RETURN Self

//------------------------------------------------------------------------------------------------

METHOD Drawing:RefreshDC()
   IF ::xhDC == NIL
      ::GetDC()
   ENDIF
RETURN Self

//------------------------------------------------------------------------------------------------

METHOD Drawing:GetTextExtentPoint32( cText )
   LOCAL hFont, aExt
   DEFAULT cText TO ::Owner:Caption
   IF ::Owner:Font != NIL .AND. ::Owner:Font:Handle != NIL
      hFont := SelectObject( ::hDC, ::Owner:Font:Handle )
   ENDIF
   aExt := _GetTextExtentPoint32( ::hDC, cText )
   IF hFont != NIL
      ::SelectObject( hFont )
   ENDIF
RETURN aExt

//------------------------------------------------------------------------------------------------

METHOD Drawing:GetTextExtentExPoint( cText, nMaxWidth, nFit )
   LOCAL hFont, aExt
   IF ::Owner:Font != NIL .AND. ::Owner:Font:Handle != NIL
      hFont := SelectObject( ::hDC, ::Owner:Font:Handle )
   ENDIF
   aExt := _GetTextExtentExPoint( ::hDC, cText, nMaxWidth, @nFit )
   IF hFont != NIL
      ::SelectObject( hFont )
   ENDIF
RETURN aExt

//------------------------------------------------------------------------------------------------

METHOD Drawing:GetTextMetrics()
   LOCAL cBuffer, tm := (struct TEXTMETRIC)
   cBuffer := GetTextMetrics( ::hDC, @tm )
RETURN tm

//------------------------------------------------------------------------------------------------

METHOD Drawing:GetClipBox( aRect )
   LOCAL nRet
   DEFAULT aRect TO {,,,}
   nRet := GetClipBox( ::hDC, @aRect )
RETURN nRet

//------------------------------------------------------------------------------------------------

METHOD Drawing:Destroy()
   IF ::xhDC != NIL
      IF ::cPaint == NIL
         ::ReleaseDC()
       ELSE
         ::EndPaint()
      ENDIF
      ::xhDC := NIL
   ENDIF
RETURN Self

//------------------------------------------------------------------------------------------------

METHOD Drawing:BeginPaint()
   LOCAL cPaint
   ::Destroy()
   ::xhDC := _BeginPaint( ::Owner:hWnd, @cPaint )
   ::cPaint := cPaint
RETURN Self

//------------------------------------------------------------------------------------------------

METHOD Drawing:FillRect( aRect, hBrush )
   DEFAULT aRect  TO { 0, 0, ::Owner:Width, ::Owner:Height }
   DEFAULT hBrush TO IIF( ::Owner:BkBrush != NIL, ::Owner:BkBrush, ::Owner:ClassBrush )
   _FillRect( ::hDC, aRect, hBrush )
RETURN Self

//------------------------------------------------------------------------------------------------

METHOD Drawing:Rectangle( nLeft, nTop, nRight, nBottom, nColor, hBrush, nPen )
   LOCAL hOldBrush, hOldPen, hPen, aRect := ::Owner:GetRectangle()

   DEFAULT nLeft     TO aRect[1]
   DEFAULT nTop      TO aRect[2]
   DEFAULT nRight    TO aRect[3]
   DEFAULT nBottom   TO aRect[4]

   IF nColor != NIL
      DEFAULT nPen TO 1
      hPen    := CreatePen( PS_SOLID, nPen, nColor )
      hOldPen := SelectObject( ::hDC, hPen )
   ENDIF

   IF hBrush != NIL
      hOldBrush := SelectObject( ::hDC, hBrush )
   ENDIF

   Rectangle( ::hDC, nLeft, nTop, nRight, nBottom )

   IF hOldBrush != NIL
      SelectObject( ::hDC, hOldBrush )
   ENDIF
   IF hOldPen != NIL
      SelectObject( ::hDC, hOldPen )
      DeleteObject( hPen )
   ENDIF
RETURN Self

//------------------------------------------------------------------------------------------------

METHOD Drawing:DrawFrameControl( aRect, nStyle, nFlags )
   DEFAULT aRect  TO { 0, 0, ::Owner:Width, ::Owner:Height }
   _DrawFrameControl( ::hDC, aRect, nStyle, nFlags )
RETURN Self


METHOD Drawing:EnumFonts( cFaceName )
   s_oSelf := Self
   ::__aFonts := {}
   _EnumFonts( ::hDC, cFaceName, "VXHENUMFONTS" )
RETURN ::__aFonts

FUNCTION VXHENUMFONTS( plf, ptm )
   LOCAL lf, tm
   lf := (struct LOGFONT*) plf
   tm := (struct TEXTMETRIC*) ptm
   IF lf:lfFaceName[1] != "@"
      AADD( s_oSelf:__aFonts, { lf, tm } )
   ENDIF
RETURN 1

