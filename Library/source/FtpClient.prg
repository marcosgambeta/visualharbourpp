#ifdef VXH_ENTERPRISE
   #define VXH_PROFESSIONAL
#endif

#ifdef VXH_PROFESSIONAL

#include "vxh.ch"
#include "debug.ch"
#include "wininet.ch"

#define INTERNET_INVALID_STATUS_CALLBACK -1
#define FILE_ATTRIBUTE_NORMAL 0x00000080

static __oFtp
static aEvents

CLASS FtpClient INHERIT Component
   PROPERTY Operation    DEFAULT 0
   PROPERTY OpenType     DEFAULT INTERNET_OPEN_TYPE_DIRECT
   PROPERTY Service      DEFAULT INTERNET_SERVICE_FTP
   PROPERTY Server
   PROPERTY UserName
   PROPERTY Password
   PROPERTY Port         DEFAULT INTERNET_DEFAULT_FTP_PORT
   PROPERTY Passive      DEFAULT .F.
   PROPERTY TransferType DEFAULT FTP_TRANSFER_TYPE_BINARY
   PROPERTY Timeout      DEFAULT 3

   DATA EnumTransferType EXPORTED INIT { { "ASCII", "Binary" }, { FTP_TRANSFER_TYPE_ASCII, FTP_TRANSFER_TYPE_BINARY } }
   DATA EnumOperation    EXPORTED INIT { { "Synchronous", "Asynchronous" }, { 0, INTERNET_FLAG_ASYNC } }
   DATA EnumService      EXPORTED INIT { { "FTP", "HTTP" }, { INTERNET_SERVICE_FTP, INTERNET_SERVICE_HTTP } }
   DATA EnumOpenType     EXPORTED INIT { { "Direct", "Pre-Config", "Proxy" }, { INTERNET_OPEN_TYPE_DIRECT, INTERNET_OPEN_TYPE_PRECONFIG, INTERNET_OPEN_TYPE_PROXY } }
   DATA Context, InternetStatus, StatusInformation, StatusInfoLength
   DATA hHandle          EXPORTED INIT 0
   DATA hFtp             EXPORTED

   METHOD Init() CONSTRUCTOR
   METHOD Create()

   METHOD Connect()
   METHOD DisConnect()
   METHOD GetDirectory()
   METHOD GetCurrentDirectory()
   METHOD PutFile( cLocalFile, cRemoteFile, nAttrib ) INLINE FtpPutFile( ::hFtp, cLocalFile, cRemoteFile, ::TransferType, IIF( nAttrib == NIL, FILE_ATTRIBUTE_NORMAL, nAttrib ) )
   METHOD GetFile( cRemoteFile, cLocalFile, nAttrib ) INLINE FtpGetFile( ::hFtp, cRemoteFile, cLocalFile, ::TransferType, IIF( nAttrib == NIL, FILE_ATTRIBUTE_NORMAL, nAttrib ) )
   METHOD DeleteFile( cRemoteFile )             INLINE FtpDeleteFile( ::hFtp, cRemoteFile )
   METHOD RenameFile( cExistingFile, cNewFile ) INLINE FtpRenameFile( ::hFtp, cExistingFile, cNewFile )
   METHOD CreateDirectory( cDirectory )         INLINE FtpCreateDirectory( ::hFtp, cDirectory )
   METHOD RemoveDirectory( cDirectory )         INLINE FtpRemoveDirectory( ::hFtp, cDirectory )
   METHOD SetCurrentDirectory( cDirectory )     INLINE FtpSetCurrentDirectory( ::hFtp, cDirectory )
   METHOD Command( cCmd )                       INLINE FtpCommand( ::hFtp, .F., ::TransferType, cCmd, 1 )
   //METHOD Read()
   METHOD GetLastResponseInfo()
   METHOD GetFileData()
ENDCLASS

//-------------------------------------------------------------------------------------------------------
METHOD Init( oOwner ) CLASS FtpClient
   LOCAL n
   ::__xCtrlName   := "FtpClient"
   ::ComponentType := "FtpClient"
   ::Super:Init( oOwner )

   DEFAULT aEvents TO {;
                        { INTERNET_STATUS_RESOLVING_NAME,       "ResolvingName" },;
                        { INTERNET_STATUS_NAME_RESOLVED,        "NameResolved" },;
                        { INTERNET_STATUS_CONNECTING_TO_SERVER, "ConnectingToServer" },;
                        { INTERNET_STATUS_CONNECTED_TO_SERVER,  "Connected" },;
                        { INTERNET_STATUS_SENDING_REQUEST,      "SendingRequest" },;
                        { INTERNET_STATUS_REQUEST_SENT,         "RequestSent" },;
                        { INTERNET_STATUS_RECEIVING_RESPONSE,   "ReceivingResponse" },;
                        { INTERNET_STATUS_RESPONSE_RECEIVED,    "ResponseReceived" },;
                        { INTERNET_STATUS_REDIRECT,             "Redirect" },;
                        { INTERNET_STATUS_CLOSING_CONNECTION,   "ClosingConnection" },;
                        { INTERNET_STATUS_CONNECTION_CLOSED,    "ConnectionClosed" },;
                        { INTERNET_STATUS_HANDLE_CREATED,       "HandleCreated" },;
                        { INTERNET_STATUS_HANDLE_CLOSING,       "HandleClosing" },;
                        { INTERNET_STATUS_STATE_CHANGE,         "StatusStateChange" },;
                        { INTERNET_STATUS_REQUEST_COMPLETE,     "RequestComplete" } }

   ::Events := { {"Status", {} } }
   FOR n := 1 TO LEN( aEvents )
       AADD( ::Events[1][2], { aEvents[n][2], "", "" } )
   NEXT

RETURN self

//-------------------------------------------------------------------------------------------------------
METHOD Create() CLASS FtpClient
   IF ! ::DesignMode
      ::hHandle := InternetOpen( ::Application:Name, ::OpenType, NIL, NIL, ::Operation )
      __oFtp := Self
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
FUNCTION FtpStatusCallback( hInternet, dwContext, dwInternetStatus, lpvStatusInformation, dwStatusInformationLength )
   LOCAL n
   (hInternet,dwStatusInformationLength)
   __oFtp:Context           := dwContext
   __oFtp:InternetStatus    := dwInternetStatus
   __oFtp:StatusInformation := lpvStatusInformation
   __oFtp:StatusInfoLength  := dwStatusInformationLength

   IF ( n := ASCAN( aEvents, {|a| a[1]==dwInternetStatus} ) ) > 0
      ExecuteEvent( aEvents[n][2], __oFtp )
   ENDIF
RETURN NIL

//-------------------------------------------------------------------------------------------------------
METHOD Connect() CLASS FtpClient
   IF ::hHandle == 0
      ::Create()
   ENDIF
   IF ::hHandle != NIL .AND. ::hHandle <> 0
      // Forces the OS to timeout if routers are delaying the denial.
      InternetSetTimeout( ::hHandle, INTERNET_OPTION_CONNECT_TIMEOUT, ::Timeout * 1000 )
      InternetSetTimeout( ::hHandle, INTERNET_OPTION_RECEIVE_TIMEOUT, ::Timeout * 1000 )
      InternetSetTimeout( ::hHandle, INTERNET_OPTION_SEND_TIMEOUT, ::Timeout * 1000 )
      InternetSetTimeout( ::hHandle, INTERNET_OPTION_DATA_RECEIVE_TIMEOUT, ::Timeout * 1000 )
      InternetSetTimeout( ::hHandle, INTERNET_OPTION_DATA_SEND_TIMEOUT, ::Timeout * 1000 )
      InternetSetTimeout( ::hHandle, INTERNET_OPTION_DISCONNECTED_TIMEOUT, ::Timeout * 1000 )
      IF ( ::hFtp := InternetConnect( ::hHandle, ::Server, IIF( ::Port == 0, INTERNET_DEFAULT_FTP_PORT, ::Port ), ::UserName, ::Password, ::Service, IIF( ::Passive, INTERNET_FLAG_PASSIVE, ), 1  ) ) <> NIL
         InternetSetStatusCallback( ::hFtp, ( @FtpStatusCallback() ) )
         RETURN .T.
      ENDIF
   ENDIF
RETURN .F.

//-------------------------------------------------------------------------------------------------------
METHOD DisConnect() CLASS FtpClient
   LOCAL lRet := .f.
   IF ::hFtp <> 0 .AND. InternetCloseHandle( ::hFtp )
      lRet := InternetCloseHandle( ::hHandle )
      ::hHandle := 0
   ENDIF
RETURN lRet

//-------------------------------------------------------------------------------------------------------
METHOD GetCurrentDirectory() CLASS FtpClient
   LOCAL cDirectory := space( 260 )
   FtpGetCurrentDirectory( ::hFtp, @cDirectory )
RETURN cDirectory

//-------------------------------------------------------------------------------------------------------
METHOD GetLastResponseInfo() CLASS FtpClient
   LOCAL nError, cRet := "", aRet
   InternetGetLastResponseInfo( @nError, @cRet )
   aRet := hb_aTokens( cRet, CRLF )
   IF ! EMPTY( aRet ) .AND. EMPTY( aRet[-1] )
      ADEL( aRet, -1, .T. )
   ENDIF
RETURN aRet

//-------------------------------------------------------------------------------------------------------
METHOD GetDirectory( cFileSpec ) CLASS FtpClient
   LOCAL hFind, aFile := {}, aDir := {}
   LOCAL pFindData := (struct WIN32_FIND_DATA)

   DEFAULT cFileSpec TO "*.*"

   IF ( hFind := FtpFindFirstFile( ::hFtp, cFileSpec, @pFindData, 0, 0 ) ) != 0
      AADD( aDir, ::GetFileData( pFindData ) )
      DO WHILE InternetFindNextFile( hFind, @pFindData )
         AADD( aDir, ::GetFileData( pFindData ) )
         ::Application:DoEvents()
      ENDDO
      InternetCloseHandle( hFind )
   ENDIF

RETURN aDir

METHOD GetFileData( pFindData ) CLASS FtpClient
   LOCAL pSysTime := (struct SYSTEMTIME)
   LOCAL aFile    := Array( 5 )
   aFile[1] := pFindData:cFileName:AsString()
   aFile[2] := pFindData:dwFileAttributes
   aFile[3] := pFindData:nFileSizeLow

   IF FileTimeToSystemTime( pFindData:ftLastWriteTime, @pSysTime )
      aFile[4] := STOD( STRZERO( pSysTime:wYear, 4 ) + STRZERO( pSysTime:wMonth, 2 ) + STRZERO( pSysTime:wDay, 2 ) )
      aFile[5] := STRZERO( pSysTime:wHour, 2 ) + ":" + STRZERO( pSysTime:wMinute, 2 ) + ":" + STRZERO( pSysTime:wSecond, 2 )
   ENDIF
RETURN aFile

#endif