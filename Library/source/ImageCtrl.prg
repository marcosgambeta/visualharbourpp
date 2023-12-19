/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// ImageCtrl.prg                                                                                        *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#include "vxh.ch"

//-----------------------------------------------------------------------------------------------

CLASS Image INHERIT Label

   METHOD Init() CONSTRUCTOR
   METHOD Create()
   METHOD SetImage()

   PROPERTY ImageName       SET ::SetImage(v)
   PROPERTY Sunken          SET ::SetStyle( SS_SUNKEN, v )      DEFAULT .F.
   PROPERTY CenterImage     SET ::SetStyle( SS_CENTERIMAGE, v ) DEFAULT .F.
   PROPERTY LoadFromFile                                        DEFAULT .F.
   PROPERTY ImageType                                           DEFAULT 1

   DATA EnumImageType   EXPORTED  INIT {{"Bitmap","Icon"},{IMAGE_BITMAP, IMAGE_ICON}}

   DATA RightAlign   PROTECTED
   DATA Sunken       PROTECTED
   DATA Simple       PROTECTED

   DATA ImageHandle  EXPORTED

   DATA __ExplorerFilter INIT {;
                              { "All Supported Graphics", "*.bmp;*.ico" },;
                              { "Windows Bitmap (*.bmp)", "*.bmp" },;
                              { "Icon Files (*.ico)", "*.ico" };
                              }

   METHOD OnSize(w,l)   INLINE Super:OnSize(w,l), ::InvalidateRect(,.F.), NIL
ENDCLASS

//-----------------------------------------------------------------------------------------------

METHOD Image:Init( oParent )
   DEFAULT ::__xCtrlName TO "Image"
   ::ClsName  := "static"
   ::Super:Init( oParent )
   ::Style := hb_bitor(WS_CHILD, WS_VISIBLE, SS_NOTIFY, WS_CLIPCHILDREN, WS_CLIPSIBLINGS)
RETURN Self

//-----------------------------------------------------------------------------------------------

METHOD Image:SetImage( chHandle )
   IF ::ImageHandle != NIL .AND. ::hWnd != NIL
      DeleteObject( ::ImageHandle )
      ::ImageHandle := NIL
   ENDIF
   IF !EMPTY( chHandle )
      ::ImageHandle := chHandle
      IF VALTYPE( chHandle ) == "C"
         IF AT( ".", chHandle ) > 0
            ::LoadFromFile := .T.
         ENDIF
         ::ImageHandle := LoadImage( ::AppInstance, chHandle, ::ImageTypes[ ::ImageType ],,, IIF( ::LoadFromFile, LR_LOADFROMFILE, NIL ) )

       ELSEIF VALTYPE( chHandle ) == "A"
         IF ::LoadFromFile .OR. EMPTY( chHandle[2] )
            ::ImageHandle := LoadImage( ::AppInstance, chHandle[1], ::ImageTypes[ ::ImageType ],,, LR_LOADFROMFILE )
          ELSE
            ::ImageHandle := LoadImage( ::AppInstance, chHandle[2], ::ImageTypes[ ::ImageType ] )
            IF EMPTY( ::ImageHandle )
               ::ImageHandle := LoadImage( ::AppInstance, chHandle[1], ::ImageTypes[ ::ImageType ],,, IIF( ::LoadFromFile, LR_LOADFROMFILE, NIL ) )
            ENDIF
         ENDIF
      ENDIF

      IF ::ImageTypes[ ::ImageType ] == IMAGE_BITMAP
         ::SetStyle( SS_ICON, .F. )
         ::SetStyle( SS_BITMAP, .T. )
         ::SendMessage( STM_SETIMAGE, ::ImageTypes[ ::ImageType ], ::ImageHandle )
       ELSE
         ::SetStyle( SS_BITMAP, .F. )
         ::SetStyle( SS_ICON, .T. )
         ::SendMessage( STM_SETICON, ::ImageHandle )
      ENDIF
   ENDIF
RETURN Self

METHOD Image:Create()
   LOCAL w := ::Width, h := ::Height

   ::Super:Create()

   IF ::ImageHandle != NIL
      IF ::ImageHandle == 0
         ::ImageHandle := LoadImage( ::AppInstance, ::ImageName, ::ImageTypes[ ::ImageType ],,, IIF( ::LoadFromFile, LR_LOADFROMFILE, NIL ) )
      ENDIF
      IF ::ImageTypes[ ::ImageType ] == IMAGE_ICON
         ::SendMessage( STM_SETICON, ::ImageHandle )
       ELSE
         ::SendMessage( STM_SETIMAGE, ::ImageTypes[ ::ImageType ], ::ImageHandle )
      ENDIF
      ::MoveWindow(,,w,h,.F.)
   ENDIF
RETURN Self
