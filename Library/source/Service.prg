/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// Service.prg                                                                                        *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#ifdef VXH_ENTERPRISE
   #define VXH_PROFESSIONAL
#endif

#ifdef VXH_PROFESSIONAL

#include "vxh.ch"
#include "debug.ch"
#include "colors.ch"
#include "Service.ch"

#define SERVICE_NO_CHANGE     0xffffffff
#define SERVICE_DEMAND_START  0x00000003
#define SERVICE_DISABLED      0x00000004

//-----------------------------------------------------------------------------------------------

CLASS Service
   PROPERTY ServiceName SET ::__SetServiceName(v) DEFAULT ""
   PROPERTY File            DEFAULT ""
   PROPERTY DisplayName     DEFAULT ""
   PROPERTY Description     DEFAULT ""

   DATA hServiceManager     EXPORTED
   DATA hService            EXPORTED
   DATA ServiceStatusStruct EXPORTED
   DATA ServiceStatusHandle EXPORTED
   DATA StopServiceEvent    EXPORTED
   DATA EventBlock          EXPORTED
   DATA TimeOut             EXPORTED INIT 5000
   DATA __pMainCallBackPtr  EXPORTED
   DATA __pProcCallBackPtr  EXPORTED

   DATA aStatus             PROTECTED INIT { "Stopped",;
                                             "Start pending",;
                                             "Stop pending",;
                                             "Running",;
                                             "Continue pending",;
                                             "Pause pending",;
                                             "Paused" }
   DESTRUCTOR __ExitService

   ACCESS Status INLINE ::aStatus[ ::GetStatus ]

   METHOD Install()
   METHOD Run()
   METHOD Enable()      INLINE ChangeServiceConfig( ::hService, SERVICE_NO_CHANGE, SERVICE_AUTO_START, SERVICE_NO_CHANGE )
   METHOD Disable()     INLINE ChangeServiceConfig( ::hService, SERVICE_NO_CHANGE, SERVICE_DISABLED, SERVICE_NO_CHANGE )
   METHOD Start()       INLINE StartService( ::hService, 0 )
   METHOD Stop( nTime ) INLINE StopService( ::hServiceManager, ::hService, .T., IIF( nTime != NIL, nTime, 60000 ) ), Self
   METHOD Delete()      INLINE DeleteService( ::hService ),;
                               CloseServiceHandle( ::hService ),;
                               ::hService := NIL,;
                               Self
   METHOD __ServiceMain()
   METHOD __ServiceProc()
   METHOD __SetServiceName()
   METHOD GetStatus()
   METHOD QueryData()
ENDCLASS

METHOD Service:Install()
   LOCAL osv, aProcs := {}
   IF EMPTY( ::hServiceManager )
      ::hServiceManager := OpenSCManager( NIL, NIL, SC_MANAGER_ALL_ACCESS )
   ENDIF
   IF EMPTY( ::hService )
      ::hService := OpenService( ::hServiceManager, ::ServiceName,  SERVICE_ALL_ACCESS )
   ENDIF
   IF ::hService == 0
      ::hService := CreateService( ::hServiceManager,;
                                   ::ServiceName,;
                                   IIF( ::DisplayName != NIL, ::DisplayName, ::ServiceName ),;
                                   SC_MANAGER_ALL_ACCESS,;
                                   SERVICE_WIN32_OWN_PROCESS/* | SERVICE_INTERACTIVE_PROCESS*/,;
                                   SERVICE_AUTO_START,;
                                   SERVICE_ERROR_NORMAL,;
                                   ::File )

      osv := (struct OSVERSIONINFOEX)
      GetVersionEx( @osv )
      IF osv:dwMajorVersion < 6 .OR. osv:dwMinorVersion < 2
         ChangeServiceDescription( ::hService, ::Description )
      ENDIF
      StartService( ::hService, 0 )
   ENDIF
RETURN Self

METHOD Service:QueryData()
   LOCAL n, aServices, sd, lRet, qsc := (struct QUERY_SERVICE_CONFIG)
   IF ( lRet := QueryServiceConfig( ::hService, @qsc ) )
      ::File := qsc:lpBinaryPathName
      ::DisplayName  := qsc:lpDisplayName
   ENDIF
   aServices := __EnumServices()
   IF ( n := ASCAN( aServices, {|a|a[2]==::DisplayName} ) ) > 0
      ::xServiceName := aServices[n][1]
   ENDIF
   sd := (struct SERVICE_DESCRIPTION)
   IF ( lRet := QueryServiceConfig2( ::hService, 1, @sd ) )
      ::Description := sd:lpDescription
   ENDIF
RETURN lRet

METHOD Service:__SetServiceName( cName )
   IF ::xServiceName != cName
      IF EMPTY( ::hServiceManager )
         ::hServiceManager := OpenSCManager( NIL, NIL, SC_MANAGER_ALL_ACCESS )
      ENDIF
      IF !EMPTY( ::hService )
         CloseServiceHandle( ::hService )
      ENDIF
      ::hService := OpenService( ::hServiceManager, cName,  SERVICE_ALL_ACCESS )
   ENDIF
RETURN cName

METHOD Service:GetStatus()
   LOCAL ss
   IF !EMPTY( ::hService )
      ss := (struct SERVICE_STATUS)
      QueryServiceStatus( ::hService, @ss )
      RETURN ss:dwCurrentState
   ENDIF
RETURN 0

METHOD Service:Run()
   ::ServiceStatusStruct := (struct SERVICE_STATUS)
   ::__pMainCallBackPtr := WinCallBackPointer( HB_ObjMsgPtr( Self, "__ServiceMain" ), Self )
   RunService( ::ServiceName, ::__pMainCallBackPtr )
RETURN Self

PROCEDURE __ExitService CLASS Service
   IF ::hService != NIL
      CloseServiceHandle( ::hService )
   ENDIF

   IF ::hServiceManager != NIL
      CloseServiceHandle( ::hServiceManager )
   ENDIF
   IF ::__pMainCallBackPtr != NIL
      VXH_FreeCallBackPointer( ::__pMainCallBackPtr )
   ENDIF
   IF ::__pProcCallBackPtr != NIL
      VXH_FreeCallBackPointer( ::__pProcCallBackPtr )
   ENDIF
RETURN

METHOD Service:__ServiceMain()
   ::ServiceStatusStruct:dwServiceType             := SERVICE_WIN32
   ::ServiceStatusStruct:dwCurrentState            := SERVICE_STOPPED
   ::ServiceStatusStruct:dwControlsAccepted        := 0
   ::ServiceStatusStruct:dwWin32ExitCode           := NO_ERROR
   ::ServiceStatusStruct:dwServiceSpecificExitCode := NO_ERROR
   ::ServiceStatusStruct:dwCheckPoint              := 0
   ::ServiceStatusStruct:dwWaitHint                := 0

   ::__pProcCallBackPtr := WinCallbackPointer( HB_ObjMsgPtr( Self, "__ServiceProc" ), Self )
   ::ServiceStatusHandle := RegisterServiceCtrlHandler( ::ServiceName, ::__pProcCallBackPtr )

   IF ::ServiceStatusHandle != 0
      ::ServiceStatusStruct:dwCurrentState := SERVICE_START_PENDING
      SetServiceStatus( ::ServiceStatusHandle, ::ServiceStatusStruct )

      ::StopServiceEvent                 := CreateEvent( 0, .F., .F., 0 )

      ::ServiceStatusStruct:dwControlsAccepted := hb_bitor(::ServiceStatusStruct:dwControlsAccepted, SERVICE_ACCEPT_STOP, SERVICE_ACCEPT_SHUTDOWN)
      ::ServiceStatusStruct:dwCurrentState     := SERVICE_RUNNING
      SetServiceStatus( ::ServiceStatusHandle, ::ServiceStatusStruct )

      WHILE ( WaitForSingleObject( ::StopServiceEvent, ::TimeOut ) == WAIT_TIMEOUT ) .AND. ::ServiceStatusStruct:dwCurrentState == SERVICE_RUNNING
         IF VALTYPE( ::EventBlock ) == "B"
            EVAL( ::EventBlock, Self )
         ENDIF
      ENDDO

      ::ServiceStatusStruct:dwCurrentState := SERVICE_STOP_PENDING
      SetServiceStatus( ::ServiceStatusHandle, ::ServiceStatusStruct )
      CloseHandle( ::StopServiceEvent )
      ::StopServiceEvent := 0
      ::ServiceStatusStruct:dwControlsAccepted := ::ServiceStatusStruct:dwControlsAccepted & NOT(hb_bitor(SERVICE_ACCEPT_STOP, SERVICE_ACCEPT_SHUTDOWN))
      ::ServiceStatusStruct:dwCurrentState     := SERVICE_STOPPED
      SetServiceStatus( ::ServiceStatusHandle, ::ServiceStatusStruct )
   ENDIF
RETURN 0


METHOD Service:__ServiceProc( nCode )
   SWITCH nCode
      CASE SERVICE_CONTROL_INTERROGATE
           EXIT

      CASE SERVICE_CONTROL_STOP
           ::ServiceStatusStruct:dwCurrentState := SERVICE_STOP_PENDING
           SetServiceStatus( ::ServiceStatusHandle, ::ServiceStatusStruct )
           SetEvent( ::StopServiceEvent )
           RETURN 0

      CASE SERVICE_CONTROL_PAUSE
           EXIT

      CASE SERVICE_CONTROL_CONTINUE
           EXIT
   END
   SetServiceStatus( ::ServiceStatusHandle, ::ServiceStatusStruct )
RETURN 0

CLASS ServiceController INHERIT Component, Service
   DATA File                EXPORTED  INIT ""
   METHOD Init() CONSTRUCTOR
   METHOD Create()
   METHOD Stop( nTime ) INLINE StopService( ::hServiceManager, ::hService, .T., IIF( nTime != NIL, nTime, 1000 ) ), Self
ENDCLASS

METHOD ServiceController:Init( oOwner )
   ::__xCtrlName := "ServiceController"
   ::ClsName     := "ServiceController"
   ::ComponentType := "ServiceController"
   ::Super:Init( oOwner )
   ::lCreated := .T.
RETURN Self

METHOD ServiceController:Create()
   ::hServiceManager := OpenSCManager( NIL, NIL, SC_MANAGER_ALL_ACCESS )
   ::hService        := OpenService( ::hServiceManager, ::ServiceName,  SERVICE_ALL_ACCESS )
RETURN Self
#endif