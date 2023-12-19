/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// ImageList.prg                                                                                        *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#Include "commdlg.ch"
#Include "vxh.ch"

//----------------------------------------------------------------------------------------------------

CLASS ImageList INHERIT Component

   PROPERTY Images                               DEFAULT {}
   PROPERTY IconWidth   SET ::__RefreshHandle(v) DEFAULT 16
   PROPERTY IconHeight  SET ::__RefreshHandle(v) DEFAULT 16
   PROPERTY Palette     SET ::__RefreshHandle(v) DEFAULT ILC_COLOR32 //ILC_COLORDDB

   DATA EnumPalette EXPORTED INIT { {"Color","Color DDB","Color 4","Color 8","Color 16","Color 24","Color 32"},;
                                    {ILC_COLOR,ILC_COLORDDB,ILC_COLOR4,ILC_COLOR8,ILC_COLOR16,ILC_COLOR24,ILC_COLOR32} }

   PROPERTY MaskColor   ROOT "Colors" SET ::__RefreshHandle(v)

   DATA Handle      EXPORTED
   DATA Events      EXPORTED INIT {  {"General", { { "OnCreate"     , "", "" } } } }
   ACCESS Count INLINE ImageListGetImageCount( ::Handle )

   DATA __lAdd      PROTECTED INIT .F.

   METHOD Init()     CONSTRUCTOR
   METHOD Create()
   METHOD Destroy()
   METHOD Clean()
   METHOD AddBitmap()
   METHOD AddImage()
   METHOD AddIcon()
   METHOD Add( hImage, hMask )    INLINE ImageListAdd( ::Handle, hImage, hMask )
   METHOD RemoveImage(n)          INLINE ImageListRemove( ::Handle, n )
   METHOD ReplaceImage(n, hImage) INLINE ImageListReplaceIcon( ::Handle, n, hImage )
   METHOD DrawDisabled()
   METHOD DrawImage()
   METHOD FromToolBar( oBar ) INLINE ImageListDestroy( ::Handle ), ::Handle := oBar:SendMessage( TB_GETIMAGELIST, 0, 0 )

   METHOD GetImage( nIndex, nType )  INLINE ImageListGetIcon( ::Handle, nIndex-1, IIF( nType == NIL, ILD_NORMAL, nType ) )
   METHOD GetBitmap()
   METHOD __RefreshHandle()
   METHOD GetImages()

   METHOD BeginDrag(i,x,y)    INLINE ImageListBeginDrag( ::Handle, i, x, y )
   METHOD EndDrag()           INLINE ImageListEndDrag()
   METHOD DragMove(x,y)       INLINE ImageListDragMove( x, y )
   METHOD DragEnter(hWnd,x,y) INLINE ImageListDragEnter( hWnd, x, y )
   METHOD DragShowNolock(l)   INLINE ImageListDragShowNolock(l)
   METHOD RemoveAll()         INLINE ImageListRemoveAll( ::Handle )

   METHOD ComboBox( oParent ) INLINE __ImageListComboBox( oParent, Self )
   METHOD DrawIndirect()
   METHOD SaveImage(n, cFile) INLINE ImageListSaveImage( ::Handle, n-1, cFile )

   METHOD InvalidateRect()    INLINE NIL
ENDCLASS

//----------------------------------------------------------------------------------------------------

METHOD ImageList:Init( oOwner, x, y, nPalette, lAdd )
   ::__xCtrlName := "ImageList"
   ::ComponentType := "ImageList"
   ::ClsName := "ImageList"

   DEFAULT lAdd TO .T.
   IF lAdd
      ::Super:Init( oOwner )
    ELSE
      ::Owner := oOwner
   ENDIF
   DEFAULT nPalette TO ::Palette
   DEFAULT x        TO ::IconWidth
   DEFAULT y        TO ::IconHeight
   ::xIconWidth  := x
   ::xIconHeight := y
   ::xPalette    := nPalette
   ::__lAdd      := lAdd
RETURN SELF

//----------------------------------------------------------------------------------------------------

METHOD ImageList:Create()
   LOCAL oComp, aImage, cEvent, nStyle := hb_bitor(::Palette, ILC_MASK)

   IF VALTYPE( ::Form ) == "O"
      FOR EACH oComp IN ::Form:Components
          IF ! oComp == Self .AND. oComp:HasMessage( "ImageList" ) .AND. VALTYPE( oComp:ImageList ) == "C" .AND. UPPER( oComp:ImageList ) == UPPER( ::Name )
             oComp:ImageList := Self
             oComp:__ResetImageList( Self )
          ENDIF
      NEXT
   ENDIF

   ::Handle := ImageListCreate( ::IconWidth, ::IconHeight, nStyle, 1, 0 )
   FOR EACH aImage IN ::Images
       ::AddImage( aImage[1], aImage[2], aImage[3], aImage[4], aImage[5], aImage[6], .F. )
   NEXT
   IF ::EventHandler != NIL .AND. HGetPos( ::EventHandler, "OnCreate" ) != 0
      cEvent := ::EventHandler[ "OnCreate" ]
      IF ::Form != NIL .AND. __objHasMsg( ::Form, cEvent )
         ::Form:&cEvent( Self )
      ENDIF
   ENDIF
RETURN Self

//----------------------------------------------------------------------------------------------------
METHOD ImageList:Destroy()
   ImageListDestroy( ::Handle )
   ::Owner := NIL
   IF ::__lAdd
      ::Super:Destroy()
   ENDIF
RETURN NIL

//----------------------------------------------------------------------------------------------------
METHOD ImageList:GetBitmap( nIndex )
   LOCAL hMemDC, hMemBitmap, hDC := GetDC( 0 )
   hMemDC     := CreateCompatibleDC( hDC )
   hMemBitmap := CreateImageListBitmap( ::Handle, nIndex-1, hDC, hMemDC, ::IconWidth, ::IconHeight )
   DeleteDC( hMemDC )
   ReleaseDC( 0, hDC )
RETURN hMemBitmap

//----------------------------------------------------------------------------------------------------

METHOD ImageList:Clean( oControl )
   LOCAL oChild
   TRY
      IF __objHasMsg( oControl, "IMAGELIST" )
         IF oControl:ImageList != NIL .AND. oControl:ImageList:Handle == ::Handle
            oControl:ImageList := NIL
         ENDIF
         FOR EACH oChild IN oControl:Children
             TRY
                oChild:ImageIndex := -1
              catch
             END
             ::Clean( oChild )
         NEXT
      ENDIF
    catch
  END
RETURN Self

//----------------------------------------------------------------------------------------------------

METHOD ImageList:__RefreshHandle()
   IF ::Handle != NIL
      ImageListDestroy( ::Handle )
      ::Handle := NIL
      ::Create()
   ENDIF
RETURN Self

//----------------------------------------------------------------------------------------------------

METHOD ImageList:AddImage( cImage, nMask, hInst, nLoad, nType, cFile, lAdd, lParser )
   LOCAL hImage, hTool, tbb, nRet, hList, pImageInfo := (struct IMAGEINFO)
   DEFAULT lAdd TO .T.
   DEFAULT nType TO IMAGE_ICON
   DEFAULT lParser TO .F.

   hInst := ::AppInstance

   IF lParser
      cImage := cFile
      nLoad  := LR_LOADFROMFILE //| LR_CREATEDIBSECTION
   ENDIF

   IF ::DesignMode
      IF AT( "\", cImage ) == 0
         DirChange( ::Application:Project:Properties:Path + "\" + ::Application:Project:Properties:Resource )
      ENDIF

      ::Application:Project:AddImage( cImage, nType, Self )
   ENDIF

   IF lAdd
      AADD( ::Images, { cImage, nMask, hInst, nLoad, nType, cFile } )
   ENDIF

   DEFAULT nMask TO ::MaskColor

   IF ::Handle != NIL
      IF VALTYPE( cImage ) == "N"
         hTool := CreateWindowEx( WS_EX_TOOLWINDOW, "ToolBarWindow32", "", WS_CHILD, 0, 0, 1500, ::IconHeight, IIF( ::Owner != NIL, IIF( ::Owner:Parent != NIL, ::Owner:Parent:hWnd, ::Owner:hWnd ), GetDesktopWindow()), 0, ::AppInstance )

         tbb := (struct TBBUTTON)
         SendMessage( hTool, TB_BUTTONSTRUCTSIZE, tbb:SizeOf(), 0 )
         SendMessage( hTool, TB_SETBITMAPSIZE, 0, MAKELPARAM( ::IconWidth, ::IconHeight ) )
         SendMessage( hTool, TB_LOADIMAGES, cImage, -1 )


         ShowWindow( hTool, SW_HIDE )

         hList := SendMessage( hTool, TB_GETIMAGELIST, 0, 0 )

         ImageListDestroy( ::Handle )
         ::Handle := hList

         DestroyWindow( hTool )

       ELSE
         IF ( hImage := LoadImage( hInst, cImage, nType,,, nLoad ) ) != 0
            nRet := hImage

            IF nType == IMAGE_ICON
               ImageListReplaceIcon(::Handle, -1, hImage )
               DestroyIcon( hImage )
             ELSE
               IF ::MaskColor != NIL
                  ImageListAddMasked( ::Handle, hImage, ::MaskColor )
                 ELSE
                  ImageListAdd( ::Handle, hImage, ::MaskColor )
               ENDIF
               DeleteObject( hImage )
            ENDIF
         ENDIF
      ENDIF
   ENDIF
RETURN nRet

//----------------------------------------------------------------------------------------------------

METHOD ImageList:AddBitmap( cImage, nMask, hInst, nLoad )
   LOCAL hBmp
   hInst := ::AppInstance
   hBmp := LoadImage( hInst, cImage, IMAGE_BITMAP,,, nLoad )
   DEFAULT nMask TO ::MaskColor
   IF ::MaskColor != NIL
      ImageListAddMasked( ::Handle, hBmp, ::MaskColor )
    ELSE
      ImageListAdd( ::Handle, hBmp, ::MaskColor )
   ENDIF
   DeleteObject( hBmp )
RETURN SELF

//----------------------------------------------------------------------------------------------------

METHOD ImageList:AddIcon( hIcon, hInst )
   IF VALTYPE( hIcon ) == "C"
      hInst := ::AppInstance
      hIcon := LoadIcon( hInst, hIcon )
   ENDIF
   ImageListAddIcon(::Handle, hIcon)
RETURN SELF

//----------------------------------------------------------------------------------------------------

METHOD ImageList:DrawDisabled( hDC, nIndex, x, y, hBrush )
   LOCAL nStyle := DST_ICON, hIcon := ImageListGetIcon( ::Handle, nIndex-1, ILD_NORMAL )
   IF hBrush == NIL
      hBrush := 0
      nStyle := hb_bitor(nStyle, DSS_DISABLED)
    ELSE
      nStyle := hb_bitor(nStyle, DSS_MONO)
   ENDIF
   DrawState( hDC, hBrush, hIcon, 0, x, y, 0, 0, nStyle )
   DestroyIcon( hIcon )
RETURN SELF

//----------------------------------------------------------------------------------------------------
#define ILD_DPISCALE 0x4000
#define ILS_ALPHA    0x00000008
#define ILS_SHADOW   0x00000002
#define ILS_SATURATE 0x00000004

METHOD ImageList:DrawIndirect( hDC, nIndex, x, y, xBmp, yBmp, lDisabled, nFlags, nRop )
   LOCAL ildp   := (struct IMAGELISTDRAWPARAMS)

   DEFAULT lDisabled TO .F.
   DEFAULT nFlags TO ILD_TRANSPARENT

   IF lDisabled
      nFlags := hb_bitor(nFlags, ILS_SHADOW)
   ENDIF

   ildp:cbSize  := ildp:sizeof()
   ildp:i       := nIndex-1
   ildp:himl    := ::handle
   ildp:hdcDst  := hDC
   ildp:x       := x
   ildp:y       := y
   ildp:fStyle  := nFlags
   ildp:xBitmap := xBmp
   ildp:yBitmap := yBmp
   ildp:dwRop   := nRop

RETURN ImageListDrawIndirect( ildp )

//----------------------------------------------------------------------------------------------------

METHOD ImageList:DrawImage( hDC, nIndex, x, y, nFlags, nColor, nBackColor )
   DEFAULT nColor TO CLR_NONE
   DEFAULT nBackColor TO CLR_NONE
   ImageListDrawEx( ::Handle, nIndex-1, hDC, x, y, 0, 0, nBackColor, nColor, nFlags )
RETURN SELF

//----------------------------------------------------------------------------------------------------

METHOD ImageList:GetImages()
   LOCAL n, hIcon, aImages := {}
   FOR n := 1 TO ImageListGetImageCount( ::Handle )
       hIcon := ::GetImage( n )
       AADD( aImages, hIcon )
   NEXT
RETURN SELF

CLASS __ImageListComboBox INHERIT ComboBox
   PROPERTY ImageList  GET __ChkComponent( Self, @::xImageList )

   METHOD Init() CONSTRUCTOR
   METHOD Create()
   METHOD OnParentDrawItem()
ENDCLASS

METHOD __ImageListComboBox:Init( oParent, oImageList )
   ::ImageList := oImageList
   ::Super:Init( oParent )
   ::Style     := hb_bitor(WS_CHILD, WS_VISIBLE, WS_TABSTOP, WS_VSCROLL, CBS_HASSTRINGS, CBS_OWNERDRAWFIXED, CBS_DROPDOWNLIST, WS_CLIPCHILDREN, WS_CLIPSIBLINGS)
RETURN Self

METHOD __ImageListComboBox:Create()
   LOCAL n
   ::Super:Create()
   ::AddItem( "None" )
   FOR n := 1 TO ::ImageList:Count
       ::AddItem( XSTR(n) )
       ::SendMessage( CB_SETITEMHEIGHT, n-1, ::ImageList:IconHeight )
   NEXT
RETURN Self

METHOD __ImageListComboBox:OnParentDrawItem( nwParam, nlParam, dis )
   LOCAL n, y, lSelected, nLen, itemTxt, aSize
   HB_SYMBOL_UNUSED(nwParam)
   HB_SYMBOL_UNUSED(nlParam )
   IF dis:hwndItem == ::hWnd
      lSelected := (dis:itemState & ODS_SELECTED) != 0

      IF (dis:itemAction & ODA_DRAWENTIRE) == ODA_DRAWENTIRE .OR. (dis:itemAction & ODA_SELECT) == ODA_SELECT
         SetTextColor( dis:hDC, GetSysColor(IF( lselected,COLOR_HIGHLIGHTTEXT,COLOR_WINDOWTEXT )) )
         SetBkColor( dis:hDC, GetSysColor(IF( lselected,COLOR_HIGHLIGHT,COLOR_WINDOW )) )

         nLen    := SendMessage( dis:hwndItem, CB_GETLBTEXTLEN, dis:itemID, 0 )
         itemTxt := Space( nLen + 1 )
         SendMessage( dis:hwndItem, CB_GETLBTEXT, dis:itemID, @itemTxt )
         itemTxt := Left( itemTxt, nLen )
         n := dis:itemID +1

         aSize := _GetTextExtentPoint32( dis:hDC, itemTxt )
         y := dis:rcItem:Top + ((dis:rcItem:Bottom-dis:rcItem:Top)/2) - (aSize[2]/2)

         IF n > 0
            ExtTextOut( dis:hDC, ::ImageList:IconWidth+20, y, ETO_OPAQUE + ETO_CLIPPED, dis:rcItem, itemTxt )
            IF (dis:itemState & ODS_COMBOBOXEDIT) == 0
               DrawIconEx( dis:hDC, 3, dis:rcItem:Top, ::ImageList:GetImage(n), ::ImageList:IconWidth, ::ImageList:IconHeight, 0, NIL,  DI_NORMAL )
            ENDIF
          ELSE
            ExtTextOut( dis:hDC, ( dis:rcItem:right - aSize[1] )/2, y, ETO_OPAQUE + ETO_CLIPPED, dis:rcItem, itemTxt )
         ENDIF
      ENDIF
   ENDIF
RETURN 0
