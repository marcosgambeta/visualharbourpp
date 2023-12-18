/*
 * $Id$
 */

#include "debug.ch"
#include "vxh.ch"
#include "colors.ch"
#ifdef __XHARBOUR__
   #include "sqlrdd.ch"
#endif

//-------------------------------------------------------------------------------------------------------
CLASS SqlConnector INHERIT Component
   PROPERTY ConnectionString
   PROPERTY AutoConnect      DEFAULT .T.
   PROPERTY Server           DEFAULT CONNECT_ODBC

   DATA Sql              EXPORTED
   DATA ConnectionID     EXPORTED          // to be used as dbUseArea() parameter
   DATA Connected        EXPORTED INIT .F.


   // Private use
   DATA EnumServer       EXPORTED INIT { { "AutoDetect", "ODBC", "RPC", "MySQL", "Postgres", "Oracle", "Firebird","MariaDb" }, {0,1,2,3,4,5,6,7} }
   DATA aIncLibs         EXPORTED INIT   { NIL, NIL, NIL, "libmysql.lib", "libpq", "oci", "fbclient_ms.lib","libmysql.lib" }
   DATA Events           EXPORTED INIT {  {"General", { { "OnConnect"     , "", "" },;
                                                        { "OnDisconnect" , "", "" } } } }

   METHOD Init() CONSTRUCTOR
   METHOD Connect( cConnString )
   METHOD Disconnect()
   METHOD Create()
   METHOD Commit()
   METHOD RollBack()
   METHOD Execute( cCommand )
   METHOD Exec( cCommand, lMsg, lFetch, aArray, cFile, cAlias, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate )
   METHOD Fetch( aLine )
   METHOD FieldGet( nField, aField, cFromWhere, nFieldJoin, nHandle, lTranslate )
   METHOD Getline( aFields, lTranslate, nHandle, nStart )
   METHOD GetStruct( cTable )
   METHOD BuildString()
ENDCLASS

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:Init( oOwner )
   DEFAULT oOwner TO ::Application
   ::Connected     := .F.
   ::ConnectionID  := 0
   ::__xCtrlName   := "SqlConnector"
   ::ClsName       := "SqlConnector"
   ::ComponentType := "SqlConnector"
   ::lCreated      := .T.
   ::Super:Init( oOwner )
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:Create()
   LOCAL cStr, cLib
   IF ::DesignMode
      IF ::Server > 0
         cStr := ::aIncLibs[ ::Server + 1 ]
         IF cStr != NIL .AND. ASCAN( ::Application:Project:__ExtraLibs, cStr,,, .T. ) == 0
            AADD( ::Application:Project:__ExtraLibs, cStr )
         ENDIF
       ELSE
         FOR EACH cLib IN ::aIncLibs
            IF cLib != NIL .AND. ASCAN( ::Application:Project:__ExtraLibs, cLib,,, .T. ) == 0
               AADD( ::Application:Project:__ExtraLibs, cLib )
            ENDIF
         NEXT
      ENDIF
   ENDIF
   IF ::AutoConnect .AND. ::ConnectionString != NIL
      ::Connect()
   ENDIF
RETURN Self


//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:BuildString()
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:Connect( cConnString )
   LOCAL nCnn, cEvent, nServer

   DEFAULT cConnString TO ::ConnectionString

   If valtype( ::Sql ) == "O"         // reconnect ?
      ::Sql:End()
   EndIf

   ::Connected     := .F.
   ::ConnectionID  := 0
   ::Sql           := NIL

   IF VALTYPE( ::Server ) == "C"
      ::Server := ASCAN( ::EnumServer[1], {|c| UPPER(c)==UPPER(::Server)} )
   ENDIF
   nServer := ::Server
   IF nServer == 0
      nServer := DetectDBFromDSN( cConnString )
   ENDIF

   IF ! ::DesignMode .AND. ( nCnn := SR_AddConnection( nServer, cConnString ) ) > 0
      ::Connected     := .T.
      ::ConnectionID  := nCnn
      ::Sql           := SR_GetConnection( nCnn )

      IF HGetPos( ::EventHandler, "OnConnect" ) != 0
         cEvent := ::EventHandler[ "OnConnect" ]
         IF __objHasMsg( ::Form, cEvent )
            ::Form:&cEvent( Self )
         ENDIF
      ENDIF
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:Disconnect()
   If valtype( ::Sql ) == "O"         // reconnect ?
      ::Sql:End()
   EndIf

   ::Connected     := .F.
   ::ConnectionID  := 0
   ::Sql           := NIL
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:Commit()
   IF ::Connected
      ::Sql:Commit()
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:RollBack()
   If ::Connected
      ::Sql:RollBack()
   EndIf
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:Execute( cCommand )
   If ::Connected
      ::Sql:Execute( cCommand )
   EndIf
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SqlConnector:Exec( cCommand, lMsg, lFetch, aArray, cFile, cAlias, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate )
   If ::Connected
      ::Sql:Exec( cCommand, lMsg, lFetch, aArray, cFile, cAlias, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate )
   EndIf
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD SqlConnector:Fetch( aLine )
   If ::Connected
      ::Sql:Fetch( aLine )
   EndIf
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD SqlConnector:FieldGet( nField, aField, cFromWhere, nFieldJoin, nHandle, lTranslate )
   If ::Connected
      ::Sql:FieldGet( nField, aField, cFromWhere, nFieldJoin, nHandle, lTranslate )
   EndIf
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD SqlConnector:Getline( aFields, lTranslate, nHandle, nStart )
   If ::Connected
      ::Sql:Getline( aFields, lTranslate, nHandle, nStart )
   EndIf
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD SqlConnector:GetStruct( cTable )
   If ::Connected
      ::Sql:GetStruct( cTable )
   EndIf
RETURN Self

//-------------------------------------------------------------------------------------------------------

CLASS BindingSource INHERIT SqlConnector
ENDCLASS

CLASS DataConnector INHERIT SqlConnector
ENDCLASS