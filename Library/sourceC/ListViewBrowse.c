#include "hbapi.h"

#define DUMMYUNIONNAME

// Don't move, must precede any #include of Windows to fix guiddef.h BUG!!!
#include "cinterface.h"
#include <Windows.h>
#include <commctrl.h>
#include <shlobj.h>

#define TOTAL_COLS 4

static BOOL s_bShowFolders;

BOOL ListViewBrowseInsertItem(HWND hWndListView, LPSHELLFOLDER lpsf, LPITEMIDLIST lpi, LPITEMIDLIST lpifq, ULONG uAttr);
void ListViewBrowseOnViewStyle(HWND hWndListView, UINT uiStyle, HWND hWndMain);
BOOL ListViewBrowseShowPopupStyleMenu(HWND hWndListView, HINSTANCE appInstance);
void ListViewBrowseGetTypeOf(LPITEMIDLIST pit, LPSTRRET lpName);
BOOL GetName (LPSHELLFOLDER lpsf, LPITEMIDLIST lpi, DWORD dwFlags, LPSTR lpFriendlyName);
int GetNormalIcon(LPITEMIDLIST lpifq);
LPITEMIDLIST CopyItemID(LPMALLOC g_pMalloc, LPITEMIDLIST pidl);
LPITEMIDLIST Concatenate(LPMALLOC lpMalloc, LPCITEMIDLIST pidl1, LPCITEMIDLIST pidl2);
void FolderListSet(HWND hWndListView, LPSHELLFOLDER pFolder, LPITEMIDLIST lpi);
void ListViewBrowseGetSelectedItem(HWND hWndListView, LPNMHDR lpnmh , LV_ITEM* lvItem);

typedef struct
{
   BOOL bRoot;
   LPSHELLFOLDER lpsfParent;
   LPITEMIDLIST  lpi;
   LPITEMIDLIST  lpifq;
   ULONG         ulAttribs;
   LPSHELLFOLDER pRoot;
}LVITEMDATA, *LPLVITEMDATA;

typedef struct {
   BOOL bRoot;
   LPSHELLFOLDER lpsfParent;
   LPITEMIDLIST  lpi;
   LPITEMIDLIST  lpifq;
   ULONG         ulAttribs;
   LPSHELLFOLDER pRoot;
}LPTVITEMDATA;

enum SubItems
{
   SUBITEM_NAME, SUBITEM_SIZE, SUBITEM_TYPE, SUBITEM_MODIFIED
};

#define IDS_SCCSID                      1
#define IDR_MAINMENU                    101
#define IDC_STATUSBAR                   101
#define IDC_TOOLBAR                     102
#define IDB_TOOLBAR                     103
#define IDR_VIEW_POPUP                  103
#define ID_VIEW_LARGEICONS              104
#define ID_VIEW_SMALLICONS              105
#define IDI_MAINICON                    105
#define ID_VIEW_LISTS                   106
#define ID_VIEW_DETAIL                  107
#define IDC_SPLIT_CURSOR                107
#define IDM_VIEW_LARGEICONS             108
#define IDM_VIEW_SMALLICONS             109
#define IDM_VIEW_LIST                   110
#define IDM_VIEW_DETAIL                 111
#define ID_SPLITTER                     1000
#define ID_TREEVIEW                     1002
#define ID_LISTVIEW                     1003
#define IDM_FILE_EXIT                   40001
#define IDM_SPLIT_HORZ                  40002
#define IDM_SPLIT_VERT                  40003
#define IDM_SPLIT_WIDE                  40004
#define IDM_HELP_ABOUT                  40005
#define IDM_SPLIT_CONSTRAIN             40006
#define IDM_SPLIT_SHOWPOS               40007
#define IDM_SPLIT_SHOWWIDTH             40008
#define IDM_SPLIT_SWAPVIEWS             40009
#define ID_VIEW_REFRESH                 40010

#define SFGAO_STREAM 0x00400000L

int  giRowCtr = 0;

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( LISTVIEWBROWSEINIT )
{
   HWND hwnd = (HWND) hb_parnl(1);
   LV_COLUMN lvColumn;
   int       i;
   TCHAR     szString[TOTAL_COLS][20] = {"Name", "Size", "Type", "Modified"};
   int       szColWidth[TOTAL_COLS] = {180, 80, 100, 110};
   int       szColAlign[TOTAL_COLS] = {LVCFMT_LEFT, LVCFMT_RIGHT, LVCFMT_LEFT, LVCFMT_CENTER};
   SHFILEINFO  sfi;
   HIMAGELIST  himlSmall;
   HIMAGELIST  himlLarge;

   s_bShowFolders = hb_parl(4);

   himlSmall = (HIMAGELIST)SHGetFileInfo( TEXT("C:\\"), 0, &sfi, sizeof(SHFILEINFO), SHGFI_SYSICONINDEX | SHGFI_SMALLICON);
   himlLarge = (HIMAGELIST)SHGetFileInfo( TEXT("C:\\"), 0, &sfi, sizeof(SHFILEINFO), SHGFI_SYSICONINDEX | SHGFI_LARGEICON);

   if (himlSmall && himlLarge)
   {
      SendMessage( hwnd, LVM_SETIMAGELIST, (WPARAM)LVSIL_SMALL, (LPARAM)himlSmall);
      SendMessage( hwnd, LVM_SETIMAGELIST, (WPARAM)LVSIL_NORMAL, (LPARAM)himlLarge);
   }

   ListView_DeleteAllItems(hwnd);
   lvColumn.mask = LVCF_FMT | LVCF_WIDTH | LVCF_TEXT | LVCF_SUBITEM;

   for(i = 0; i < TOTAL_COLS; i++)
   {
      lvColumn.fmt = szColAlign[i];
      lvColumn.pszText = szString[i];
      lvColumn.cx = szColWidth[i];
      ListView_InsertColumn(hwnd, i, &lvColumn);
   }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
BOOL ListViewBrowseInsertItem( HWND hWndListView, LPSHELLFOLDER lpsf, LPITEMIDLIST lpi, LPITEMIDLIST lpifq, ULONG uAttr )
{
   LPMALLOC lpMalloc;
   LPLVITEMDATA lptvid = NULL;
   LV_ITEM lvi;

   lvi.mask     = LVIF_TEXT | LVIF_IMAGE | LVIF_PARAM;
   lvi.iItem    = giRowCtr++;
   lvi.iSubItem = 0;
   lvi.pszText  = LPSTR_TEXTCALLBACK;

   lpsf->lpVtbl->AddRef(lpsf);

   SHGetMalloc(&lpMalloc);
   lptvid = (LPLVITEMDATA) lpMalloc->lpVtbl->Alloc (lpMalloc, sizeof (LVITEMDATA));

   lptvid->lpsfParent = lpsf;
   lptvid->lpi        = CopyItemID(lpMalloc, lpi);
   lptvid->lpifq      = Concatenate(lpMalloc, lpifq, lpi);
   lptvid->ulAttribs  = uAttr;

   lvi.iImage = GetNormalIcon(lptvid->lpifq);
   lvi.lParam = (LPARAM)lptvid;
   lpMalloc->lpVtbl->Release(lpMalloc);

   ListView_InsertItem (hWndListView, &lvi);
   return TRUE;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( FOLDERLISTPOPULATEBYID )
{
   LPSHELLFOLDER lpsf = NULL;
   LPSHELLFOLDER pRoot = NULL;
   SHGetDesktopFolder (&lpsf);
   BOOL bRoot = ISNIL(3)?FALSE:hb_parl(3);

   if( ! bRoot )
   {
      LPITEMIDLIST lpi = (LPITEMIDLIST) hb_parnl(2);
      lpsf->lpVtbl->BindToObject( lpsf, lpi, NULL, &IID_IShellFolder, (LPVOID *) &pRoot);
      FolderListSet( (HWND) hb_parnl(1), pRoot, lpi );
   }
   else
   {
      LPITEMIDLIST lpi;
      SHGetSpecialFolderLocation( NULL, CSIDL_DESKTOP, &lpi);
      FolderListSet( (HWND) hb_parnl(1), lpsf, lpi );
   }
   lpsf->lpVtbl->Release( lpsf );
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void FolderListSet(HWND hWndListView, LPSHELLFOLDER pFolder, LPITEMIDLIST lpi)
{
   WIN32_FIND_DATA fd;
   LPSHELLFOLDER lpsf;

   ULONG celtFetched;
   LPENUMIDLIST ppenum;
   LPITEMIDLIST pidlItems;

   giRowCtr = 0;
   SetCursor(LoadCursor(NULL,IDC_WAIT));
   SendMessage(hWndListView, WM_SETREDRAW, FALSE, 0L);
   ListView_DeleteAllItems(hWndListView);

   SHGetDesktopFolder( &lpsf );

   if( s_bShowFolders )
   {
      pFolder->lpVtbl->EnumObjects(pFolder, NULL,SHCONTF_FOLDERS, &ppenum);
      while( ppenum && ( ppenum->lpVtbl->Next(ppenum, 1,&pidlItems, &celtFetched) ) == S_OK && celtFetched == 1)
      {
         ULONG uAttr = SFGAO_FOLDER;
         pFolder->lpVtbl->GetAttributesOf(pFolder, 1, (LPCITEMIDLIST *) &pidlItems, &uAttr);
         SHGetDataFromIDList(pFolder, pidlItems, SHGDFIL_FINDDATA , &fd, sizeof(WIN32_FIND_DATA));

         if( fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY || (lpsf == pFolder) )
         {
            ListViewBrowseInsertItem( hWndListView, pFolder, pidlItems, lpi, uAttr);
         }
      }
   }

   if( pFolder != lpsf )
   {
      pFolder->lpVtbl->EnumObjects(pFolder, NULL, SHCONTF_FOLDERS | SHCONTF_NONFOLDERS, &ppenum);
      while( ppenum && ( ppenum->lpVtbl->Next(ppenum, 1,&pidlItems, &celtFetched) ) == S_OK && celtFetched == 1)
      {
         ULONG uAttr = SFGAO_STREAM;
         pFolder->lpVtbl->GetAttributesOf(pFolder, 1, (LPCITEMIDLIST *) &pidlItems, &uAttr);
         SHGetDataFromIDList(pFolder, pidlItems, SHGDFIL_FINDDATA , &fd, sizeof(WIN32_FIND_DATA));

         if ( !(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) || (uAttr & SFGAO_STREAM) )
         {
            ListViewBrowseInsertItem( hWndListView, pFolder, pidlItems, lpi, uAttr);
         }
      }
   }

   SetCursor(LoadCursor(NULL,IDC_ARROW));
   SendMessage(hWndListView, WM_SETREDRAW, TRUE, 0L);
   InvalidateRect(hWndListView, NULL, TRUE);

   lpsf->lpVtbl->Release( lpsf );
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( FOLDERFROMIDLIST )
{
   char lpBuffer[ MAX_PATH + 1 ];
   SHGetPathFromIDList( (LPITEMIDLIST) hb_parnl(1), lpBuffer);
   hb_retc( lpBuffer );
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( FOLDERIDFROMFOLDERNAME )
{
   LPITEMIDLIST lpi;
   char *cFolder = (char*) hb_parc(1);
   int iFolder = hb_parni(2);

   if( cFolder != NULL )
   {
      LPSHELLFOLDER lpsf;
      OLECHAR olePath[MAX_PATH];
      ULONG chEaten;
      ULONG dwAttributes;
      MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, cFolder, -1, olePath, MAX_PATH);
      SHGetDesktopFolder (&lpsf);
      lpsf->lpVtbl->ParseDisplayName(lpsf,NULL,NULL,olePath,&chEaten,&lpi,&dwAttributes);
      lpsf->lpVtbl->Release( lpsf );

   }
   else
   {
      SHGetSpecialFolderLocation( NULL, iFolder, &lpi);
   }
   hb_retnl( (long) lpi );
}


//-------------------------------------------------------------------------------------------------------------------------------------------------
void ListViewBrowseOnViewStyle(HWND hWndListView, UINT uiStyle, HWND hWndMain)
{
   DWORD dwStyle = GetWindowLong(hWndListView, GWL_STYLE);
   dwStyle &= ~LVS_TYPEMASK;

   CheckMenuItem (GetMenu (hWndMain), IDM_VIEW_LARGEICONS , uiStyle == IDM_VIEW_LARGEICONS ? MF_CHECKED : MF_UNCHECKED);
   CheckMenuItem (GetMenu (hWndMain), IDM_VIEW_SMALLICONS , uiStyle == IDM_VIEW_SMALLICONS ? MF_CHECKED : MF_UNCHECKED);
   CheckMenuItem (GetMenu (hWndMain), IDM_VIEW_LIST       , uiStyle == IDM_VIEW_LIST       ? MF_CHECKED : MF_UNCHECKED);
   CheckMenuItem (GetMenu (hWndMain), IDM_VIEW_DETAIL     , uiStyle == IDM_VIEW_DETAIL    ? MF_CHECKED : MF_UNCHECKED);

   switch (uiStyle)
   {
   case IDM_VIEW_LARGEICONS:
      dwStyle |= LVS_ICON;
      break;
   case IDM_VIEW_SMALLICONS:
      dwStyle |= LVS_SMALLICON;
      break;
   case IDM_VIEW_LIST:
      dwStyle |= LVS_LIST;
      break;
   case IDM_VIEW_DETAIL:
      dwStyle |= LVS_REPORT;
      break;
   default:
      return;
   }
   SetWindowLong(hWndListView, GWL_STYLE, dwStyle);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
BOOL ListViewBrowseShowPopupStyleMenu(HWND hWndListView, HINSTANCE appInstance)
{
   static POINT point;
   HMENU hMenu;
   UINT id;
   HMENU hMenuTrackPopup;

   GetCursorPos(&point);
   hMenu = LoadMenu( appInstance, MAKEINTRESOURCE(IDR_VIEW_POPUP));
   hMenuTrackPopup = GetSubMenu (hMenu, 0);
   id = TrackPopupMenu(hMenuTrackPopup, TPM_LEFTALIGN | TPM_RETURNCMD | TPM_RIGHTBUTTON, point.x, point.y,0, hWndListView, NULL);
   ListViewBrowseOnViewStyle(hWndListView, id, hWndListView);
   DestroyMenu(hMenu);
   return TRUE;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void ListViewBrowseGetSelectedItem(HWND hWndListView, LPNMHDR lpnmh , LV_ITEM* lvItem)
{
   LPNMLISTVIEW lpnmlv = (LPNMLISTVIEW)lpnmh;
   lvItem->mask = LVIF_PARAM;
   lvItem->iItem = lpnmlv->iItem;
   ListView_GetItem(hWndListView, lvItem);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void ListViewBrowseSetDisplayInfo(LV_DISPINFO *lpdi)
{
   LPMALLOC pMalloc;
   HRESULT hr;
   LPLVITEMDATA pData = NULL;
   char refTime[20];
   WIN32_FIND_DATA fd;
   STRRET srName;

   lpdi->item.mask |= LVIF_DI_SETITEM;
   hr = SHGetMalloc(&pMalloc);

   if(FAILED(hr))
      return;

   pData = (LPLVITEMDATA) pMalloc->lpVtbl->Alloc(pMalloc, sizeof (LVITEMDATA));
   if (! pData)
   {
      return;
   }

   pData = (LPLVITEMDATA)lpdi->item.lParam;
   if(pData == NULL)
      return;

   memset(&fd, 0, sizeof(WIN32_FIND_DATA));

   if(lpdi->item.iSubItem)
   {
      if(lpdi->item.mask & LVIF_TEXT)
      {
         switch (lpdi->item.iSubItem)
         {
         case SUBITEM_MODIFIED:
            {
                SYSTEMTIME st;
                hr = SHGetDataFromIDList(pData->lpsfParent , pData->lpi, SHGDFIL_FINDDATA , (WIN32_FIND_DATA*)&fd , sizeof(fd));
                if(FAILED(hr))
                   break;

                FileTimeToSystemTime( &(fd.ftLastWriteTime), &st );
                wsprintf(refTime, "%02u/%02u/%04u %02u:%02u" , st.wMonth, st.wDay, st.wYear, st.wHour, st.wMinute );
                lstrcpy(lpdi->item.pszText, refTime);
            }
            break;

         case SUBITEM_TYPE:
            {
               ListViewBrowseGetTypeOf(pData->lpifq, &srName);
               lstrcpy(lpdi->item.pszText, srName.cStr);
            }
            break;

         case SUBITEM_SIZE:
            {
                hr = SHGetDataFromIDList( pData->lpsfParent, pData->lpi, SHGDFIL_FINDDATA , (WIN32_FIND_DATA*)&fd , sizeof(WIN32_FIND_DATA));

                if(fd.nFileSizeLow)
                {
                   char sNumBuff[30];
                   if(fd.nFileSizeLow != 0)
                   {
                      //_ltoa((long)fd.nFileSizeLow,sNumBuff,10);

                      wsprintf(sNumBuff, "%10u", fd.nFileSizeLow );
                   }
                   else
                   {
                      strcpy(sNumBuff,"");
                   }
                   lstrcpy(lpdi->item.pszText, sNumBuff);
                }
            }
            break;
         }
      }
    }
    else
    {
       if(lpdi->item.mask & LVIF_TEXT)
       {
          char szBuff[MAX_PATH+1];
          GetName(pData->lpsfParent, pData->lpi, SHGDN_NORMAL , szBuff);
          lpdi->item.pszText = (LPSTR)szBuff;
          lpdi->item.cchTextMax = lstrlen(szBuff);
       }
   }
   pMalloc->lpVtbl->Release(pMalloc);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( LISTBROWSESETDISPLAYINFO )
{
   LPARAM lParam = (LPARAM) hb_parnl(1);
   LV_DISPINFO *lpdi = (LV_DISPINFO *)(LPNMHDR)lParam;
   ListViewBrowseSetDisplayInfo(lpdi);
   lpdi->item.mask |= LVIF_DI_SETITEM;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void ListViewBrowseGetTypeOf(LPITEMIDLIST pit, LPSTRRET lpName)
{
   SHFILEINFO sfi;

   lpName->uType = STRRET_CSTR;
   lpName->cStr[0] = '\0';
   if( SHGetFileInfo((LPTSTR)pit, 0, &sfi, sizeof(sfi), SHGFI_USEFILEATTRIBUTES | SHGFI_TYPENAME | SHGFI_PIDL) )
   {
      lstrcpy(lpName->cStr, sfi.szTypeName);
   }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( LISTVIEWSHOWSTDMENU )
{
   HWND hWnd = (HWND) hb_parnl(1);
   LPARAM lParam = (LPARAM) hb_parnl(2);

   LVITEM lvi;

   HRESULT hr;
   HMENU hMenuPopup;
   IContextMenu *icm;
   LPMALLOC m_pMalloc;
   LPLVITEMDATA lptvid = NULL;
   UINT id;
   static POINT pt;
   CMINVOKECOMMANDINFO  ici;

   ZeroMemory(&lvi, sizeof(lvi));
   ListViewBrowseGetSelectedItem( hWnd, (LPNMHDR)lParam , &lvi);

   if(!lvi.lParam)
   {
      // Click on an empty area of Listview
      hb_retl( TRUE );
      return;
   }

   hr = SHGetMalloc(&m_pMalloc);

   if( FAILED(hr) )
   {
      hb_retl( FALSE );
      return;
   }

   lptvid = (LPLVITEMDATA) m_pMalloc->lpVtbl->Alloc( m_pMalloc, sizeof (LVITEMDATA) );
   if (! lptvid)
      goto Done;

   lptvid = (LPLVITEMDATA)lvi.lParam;
   if(lptvid == NULL)
      goto Done;

   hr = lptvid->lpsfParent->lpVtbl->GetUIObjectOf( lptvid->lpsfParent, hWnd, 1, (LPCITEMIDLIST*)&lptvid->lpi, &IID_IContextMenu, NULL, (LPVOID*)&icm);
   hMenuPopup = CreatePopupMenu();
   if( !hMenuPopup )
      goto Done;

   hr = icm->lpVtbl->QueryContextMenu(icm , hMenuPopup, 0, 1, FCIDM_SHVIEWLAST, CMF_NORMAL | CMF_EXPLORE | CMF_DEFAULTONLY);
   if( FAILED(hr) )
      goto Done;

   GetCursorPos(&pt);

   ici.cbSize = sizeof(CMINVOKECOMMANDINFO);

   id = TrackPopupMenu( hMenuPopup, TPM_LEFTALIGN | TPM_RETURNCMD | TPM_RIGHTBUTTON, pt.x, pt.y, 0, hWnd, NULL );
   ici.lpVerb = (LPCSTR)(INT_PTR)(id - 1);

   if(!id)
      goto Done;

   ici.fMask = CMIC_MASK_FLAG_NO_UI;
   ici.hwnd = hWnd;
   ici.lpParameters = NULL;
   ici.lpDirectory = NULL;
   ici.nShow = SW_SHOWNORMAL;
   ici.dwHotKey = 0;
   ici.hIcon = NULL;

   hr = icm->lpVtbl->InvokeCommand(icm , &ici);

Done:
   m_pMalloc->lpVtbl->Release(m_pMalloc);
   hb_retl( TRUE );
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( FOLDERBROWSEPOPULATE )
{
   HWND hWnd = (HWND) hb_parnl(1);
   LPARAM lParam = (LPARAM) hb_parnl(2);
   LVITEM lvi;
   LPMALLOC pMalloc;
   LPLVITEMDATA lplvid = NULL;
   LPSHELLFOLDER pFolder;

   ZeroMemory(&lvi, sizeof(lvi));
   ListViewBrowseGetSelectedItem( hWnd, (LPNMHDR)lParam , &lvi);

   SHGetMalloc( &pMalloc );

   lplvid = (LPLVITEMDATA) pMalloc->lpVtbl->Alloc( pMalloc, sizeof (LVITEMDATA) );
   lplvid = (LPLVITEMDATA)lvi.lParam;

   lplvid->lpsfParent->lpVtbl->BindToObject( lplvid->lpsfParent, lplvid->lpi, NULL, &IID_IShellFolder, (LPVOID *) &pFolder);
   FolderListSet( hWnd, pFolder, lplvid->lpifq);
   hb_retnl( (long)lplvid->lpifq);

   pFolder->lpVtbl->Release(pFolder);
   pMalloc->lpVtbl->Release(pMalloc);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( LISTVIEWBROWSEPOPULATEFROMTREE )
{
   HWND hWnd = (HWND) hb_parnl(1);
   LPARAM lParam = (LPARAM) hb_parnl(2);
   LPMALLOC pMalloc;
   LPTVITEMDATA* lptvid = NULL;
   LPSHELLFOLDER pFolder;
   TVITEM tvi = ((NM_TREEVIEW*)lParam)->itemNew;

   SHGetMalloc( &pMalloc );

   lptvid = (LPTVITEMDATA*)pMalloc->lpVtbl->Alloc( pMalloc, sizeof (LVITEMDATA) );
   lptvid = (LPTVITEMDATA*)tvi.lParam;

   if(lptvid->bRoot)
   {
      LPITEMIDLIST lpi;
      SHGetDesktopFolder(&pFolder);
      SHGetSpecialFolderLocation( NULL, CSIDL_DESKTOP, &lpi);
      FolderListSet( hWnd, pFolder, lpi );
      hb_retnl( (long)lpi);
   }
   else
   {
      lptvid->lpsfParent->lpVtbl->BindToObject( lptvid->lpsfParent, lptvid->lpi, NULL, &IID_IShellFolder, (LPVOID *) &pFolder);
      FolderListSet( hWnd, pFolder, lptvid->lpifq);
      hb_retnl( (long)lptvid->lpifq);
   }
   pFolder->lpVtbl->Release(pFolder);
   pMalloc->lpVtbl->Release(pMalloc);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
HB_FUNC( FOLDERLISTSETFOLDER )
{
   OLECHAR olePath[MAX_PATH];
   ULONG chEaten;
   ULONG dwAttributes;
   LPITEMIDLIST lpi = (LPITEMIDLIST) hb_parnl(4);
   int iFolder = hb_parni(3);
   LPSHELLFOLDER lpsf;
   LPSHELLFOLDER pFolder = NULL;
   char *cFolder = (char*) hb_parc(2);

   SHGetDesktopFolder (&lpsf);

   if( cFolder != NULL )
   {
      MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, cFolder, -1, olePath, MAX_PATH);
      lpsf->lpVtbl->ParseDisplayName(lpsf,NULL,NULL,olePath,&chEaten,&lpi,&dwAttributes);
      lpsf->lpVtbl->BindToObject( lpsf, lpi, NULL, &IID_IShellFolder, (LPVOID *) &pFolder);
   }
   else
   {
      if( lpi == NULL )
      {
         SHGetSpecialFolderLocation( NULL, iFolder, &lpi);
      }
   }

   if( lpi )
   {
      if( (cFolder == NULL) && (iFolder == CSIDL_DESKTOP) )
      {
         FolderListSet( (HWND) hb_parnl(1), lpsf, lpi );
      }
      else
      {
         if( pFolder == NULL )
         {
            lpsf->lpVtbl->BindToObject( lpsf, lpi, NULL, &IID_IShellFolder, (LPVOID *) &pFolder);
         }
         FolderListSet( (HWND) hb_parnl(1), pFolder, lpi );
      }
      hb_retnl( (long) lpi );
   }

   if( pFolder != NULL )
   {
      pFolder->lpVtbl->Release(pFolder);
   }
   lpsf->lpVtbl->Release(lpsf);
}
