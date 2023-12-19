/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// Menu.prg                                                                                             *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*
static s_oItem

#include "debug.ch"
#include "vxh.ch"

#define DG_DELCONTROL      2

//-------------------------------------------------------------------------------------------------------

EXIT PROCEDURE __CleanMenu()
   s_oItem := NIL
RETURN


CLASS Menu INHERIT Object
   DATA aItems        EXPORTED
   DATA hMenu         EXPORTED
   DATA Parent        EXPORTED
   DATA Left          EXPORTED
   DATA Top           EXPORTED
   DATA Style         EXPORTED
   DATA CoolBar       EXPORTED INIT .F.
   DATA ImageBkColor  EXPORTED
   DATA ImageBkBorder EXPORTED INIT .T.
   DATA ThemeActive   EXPORTED INIT .F.
   DATA ParProc       PROTECTED
   DATA ClsName       EXPORTED INIT "Menu"
   DATA Children      EXPORTED
   DATA __PropFilter                 EXPORTED INIT {}
   //DATA __pCallBackPtr  EXPORTED
   ACCESS hWnd        INLINE ::hMenu
   DATA ImageList     EXPORTED
   DATA HotImageList  EXPORTED
   DATA Property      EXPORTED
   DATA ItemID        EXPORTED INIT 0

   METHOD Init()      CONSTRUCTOR
   METHOD Create()
   METHOD GetSubMenu()
   METHOD GetMenuByHandle()
   METHOD GetMenuById()
   METHOD CheckItem()
   METHOD DeleteItem()
   METHOD ODProc()
   METHOD GetItem()

   METHOD Set()             INLINE SetMenu( ::Parent:hWnd, ::hMenu )
   METHOD Destroy()         INLINE DestroyMenu( ::hMenu )
   METHOD DisableItem(nId ) INLINE ::EnableItem( nId, .F. )
   METHOD Context()
ENDCLASS

//-------------------------------------------------------------------------------------------------------

METHOD Menu:Init( oParent )
   ::Children := {}
   ::aItems:= {}
   ::Parent:= oParent

   IF oParent:DesignMode
      __SetInitialValues( Self )
   ENDIF
   ::ImageList    := ::Parent:ImageList
   ::HotImageList := ::Parent:HotImageList
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD Menu:Create()
   LOCAL Popup

   ::hMenu := CreateMenu()
   FOR EACH Popup IN ::aItems
       Popup:Create()
   NEXT
   SetMenu( ::Parent:hWnd, ::hMenu )
RETURN NIL

METHOD Menu:Context( hWnd, x, y )
    ::Application:oCurMenu := Self
    DEFAULT hWnd TO ::Parent:hWnd
    DEFAULT x    TO ::Left
    DEFAULT y    TO ::Top
    ::ItemID := 0
RETURN TrackPopupMenu( ::hMenu, ::Style, x, y, 0, hWnd )

//-------------------------------------------------------------------------------------------------------

METHOD Menu:OdProc( hWnd,nMsg,nwParam,nlParam )

   LOCAL mi
   LOCAL dis
   LOCAL oSub
   LOCAL oItem

   DO CASE
      CASE nMsg == WM_MEASUREITEM
           mi := (struct MEASUREITEMSTRUCT*) nlParam
           IF mi:CtlType == ODT_MENU
              FOR EACH oSub IN ::Parent:Menu:aItems
                 IF ( oItem := oSub:GetMenuById( mi:itemID ) )!= NIL
                    oItem:MeasureItem( mi, nlParam )
                    EXIT
                 ENDIF
              NEXT
              RETURN 1
           ENDIF

      CASE nMsg == WM_DRAWITEM
           dis := (struct DRAWITEMSTRUCT*) nlParam
           IF dis:CtlType == ODT_MENU
              FOR EACH oSub IN ::Parent:Menu:aItems
                 IF ( oItem := oSub:GetMenuById( dis:itemID ) )!= NIL
                    oItem:DrawItem( dis )
                    EXIT
                 ENDIF
              NEXT
              RETURN 1
           ENDIF

   ENDCASE

RETURN CallWindowProc(::ParProc,hWnd,nMsg,nwParam,nlParam)


//-----------------------------------------------------------------------------------------------------

METHOD Menu:GetSubMenu( hMenu )

   LOCAL oSubMenu
   LOCAL oMenu

   IF ::hMenu == hMenu
      RETURN Self
   ENDIF

   FOR EACH oSubMenu IN ::aItems
      IF ( oMenu:=oSubMenu:GetSubMenu( hMenu ) ) != NIL
         RETURN oMenu
      ENDIF
   NEXT

RETURN NIL

METHOD Menu:GetMenuById( nId )

   LOCAL oSubMenu
   LOCAL oMenu

   FOR EACH oSubMenu IN ::aItems
      IF ( oMenu:=oSubMenu:GetMenuById( nId ) ) != NIL
         RETURN oMenu
      ENDIF
   NEXT

RETURN NIL

METHOD Menu:GetMenuByHandle( hMenu )

   LOCAL oSubMenu
   LOCAL oMenu

   IF hMenu == ::hMenu
      RETURN Self
   ENDIF

   FOR EACH oSubMenu IN ::aItems
      IF ( oMenu:=oSubMenu:GetMenuByHandle( hMenu ) ) != NIL
         RETURN oMenu
      ENDIF
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------

METHOD Menu:DeleteItem( nId )

   LOCAL oSubMenu
   LOCAL oMenu
   LOCAL lRet := .F.

   FOR EACH oSubMenu IN ::aItems
      IF ( oMenu:=oSubMenu:GetMenuById(nId) ) != NIL
         oMenu:Delete()
         lRet := .T.
         EXIT
      ENDIF
   NEXT

RETURN lRet


//-------------------------------------------------------------------------------------------------------

METHOD Menu:CheckItem( nId, lCheck )

   LOCAL oSubMenu
   LOCAL oMenu
   LOCAL lRet := .F.

   DEFAULT lCheck TO .T.

   FOR EACH oSubMenu IN ::aItems
      IF ( oMenu:=oSubMenu:GetMenuById(nId) ) != NIL
         oMenu:Check(lCheck)
         lRet := .T.
         EXIT
      ENDIF
   NEXT

RETURN lRet

//-----------------------------------------------------------------------------------------------------

METHOD Menu:GetItem( nId )

   LOCAL oSubMenu
   LOCAL oMenu

   FOR EACH oSubMenu IN ::aItems
      IF ( oMenu:=oSubMenu:GetMenuById(nId) ) != NIL
         RETURN oMenu
      ENDIF
   NEXT

RETURN NIL


//-------------------------------------------------------------------------------------------------------

CLASS MenuPopup FROM Menu
   METHOD Init()      CONSTRUCTOR
   METHOD Create()
ENDCLASS

METHOD MenuPopup:Init( oParent )
   ::Children := {}
   ::aItems:= {}
   ::Parent:= oParent
   ::__hObjects     := Hash()
   HSetCaseMatch( ::__hObjects, .F. )

   IF oParent:DesignMode
      __SetInitialValues( Self )
   ENDIF
   IF __ObjHasMsg( ::Parent, "ImageList" )
      ::ImageList    := ::Parent:ImageList
   ENDIF
   IF __ObjHasMsg( ::Parent, "HotImageList" )
      ::HotImageList := ::Parent:HotImageList
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD MenuPopup:Create()

   ::hMenu := CreateMenu()

RETURN Self

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
CLASS MenuBar INHERIT Component
   PROPERTY BackColor   ROOT "Colors" SET ::SetBackColor(v)
   PROPERTY ImageList   GET __ChkComponent( Self, @::xImageList, .F. )
   PROPERTY ApplyToSubMenus DEFAULT .T.

   DATA hMenu          EXPORTED
   DATA xImageList     EXPORTED

   DATA __hBrush       PROTECTED

   METHOD Init() CONSTRUCTOR
   METHOD Create()
   METHOD __AddMenuItem()
   METHOD __ResetImageList()
   METHOD Destroy()
   METHOD GetMenuById()
   METHOD SetBackColor()
   METHOD InvalidateRect() INLINE DrawMenuBar( ::Owner:hWnd )
ENDCLASS

METHOD MenuBar:Init( oParent )
   DEFAULT ::__xCtrlName   TO "MenuBar"
   DEFAULT ::ComponentType TO "MenuBar"
   DEFAULT ::ClsName       TO "MenuBar"
   Super:Init( oParent )
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD MenuBar:Create()
   ::hMenu := CreateMenu()

   ::SetBackColor( ::xBackColor )

   IF VALTYPE( ::xImageList ) == "C"
      AADD( ::Parent:__aPostCreateProc, { Self, "__ResetImageList" } )
   ENDIF
   IF ::DesignMode
      ::__IdeContextMenuItems := { { "&Add MenuItem", {|| ::__AddMenuItem() } } }
      ::Application:ObjectTree:Set( Self )
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD MenuBar:SetBackColor(n)
   IF ::hMenu != NIL
      DEFAULT n TO ::xBackColor
      IF ::__hBrush != NIL
         DeleteObject( ::__hBrush )
      ENDIF
      ::__hBrush := CreateSolidBrush( n )

      VXH_SetMenuBackColor( ::hMenu, ::__hBrush )
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD MenuBar:__ResetImageList()
   LOCAL oSubMenu, mii

   IF ::ImageList != NIL
      FOR EACH oSubMenu IN ::Children
          WITH OBJECT oSubMenu
             IF :ImageIndex > 0 .AND. ! :xChecked
                DEFAULT :__hBitmap TO ::ImageList:GetBitmap( :ImageIndex, GetSysColorBrush( COLOR_MENU ) )

                mii := (struct MENUITEMINFO)
                mii:cbSize   := mii:SizeOf()
                mii:fMask    := MIIM_BITMAP
                mii:hbmpItem := :__hBitmap
                SetMenuItemInfo( ::hMenu, :Id, .F., mii )
             ENDIF
          END
      NEXT
   ENDIF
RETURN Self

METHOD MenuBar:Destroy()
   LOCAL n
   FOR n := 1 TO LEN( ::Children )
       ::Children[n]:Destroy()
       n--
   NEXT
   DestroyMenu( ::hMenu )
   IF ::__hBrush != NIL
      DeleteObject( ::__hBrush )
   ENDIF
RETURN Self

METHOD MenuBar:__AddMenuItem()
   ::Application:Project:SetAction( { { 1, 0, 0, 0, .T., Self, "MenuItem",,,1, {}, } }, ::Application:Project:aUndo )
RETURN Self

METHOD MenuBar:GetMenuById( nId )
   LOCAL oSubMenu, oMenu
   FOR EACH oSubMenu IN ::Children
       IF oSubMenu:Id == nId
          oMenu := oSubMenu
          EXIT
        ELSEIF ( oMenu := oSubMenu:GetMenuById( nId ) ) != NIL
          EXIT
       ENDIF
   NEXT
RETURN oMenu

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

CLASS ContextMenu INHERIT MenuBar
   METHOD Init() CONSTRUCTOR
   METHOD Create()
   METHOD Show()
ENDCLASS

METHOD ContextMenu:Init( oParent )
   ::__xCtrlName   := "ContextMenu"
   ::ComponentType := "ContextMenu"
   ::ClsName       := "ContextMenu"
   Super:Init( oParent )

   IF ::DesignMode
      ::__IdeContextMenuItems := { { "&Add MenuItem", {|| ::__AddMenuItem() } } }
      ::Application:ObjectTree:Set( Self )
      ::lCreated := .T.
   ENDIF
RETURN Self

METHOD ContextMenu:Create()
   ::hMenu := CreatePopupMenu()

   IF VALTYPE( ::xImageList ) == "C"
      AADD( ::Parent:__aPostCreateProc, { Self, "__ResetImageList" } )
   ENDIF
RETURN Self

METHOD ContextMenu:Show( x, y, nAlign )
   LOCAL nRes := 0
   DEFAULT x TO ::Left
   DEFAULT y TO ::Top
   DEFAULT nAlign TO hb_bitor(TPM_LEFTALIGN, TPM_TOPALIGN)
   TrackPopupMenu( ::hMenu, nAlign, x, y, 0, ::Parent:hWnd )
   ::Application:DoEvents()
RETURN nRes
