#define SERVICE_CONTROL_STOP                 0x00000001
#define SERVICE_CONTROL_PAUSE                0x00000002
#define SERVICE_CONTROL_CONTINUE             0x00000003
#define SERVICE_CONTROL_INTERROGATE          0x00000004
#define SERVICE_CONTROL_SHUTDOWN             0x00000005

#define SERVICE_WIN32_OWN_PROCESS            0x00000010
#define SERVICE_WIN32_SHARE_PROCESS          0x00000020

#define SERVICE_WIN32  (SERVICE_WIN32_OWN_PROCESS|SERVICE_WIN32_SHARE_PROCESS)

#define SERVICE_STOPPED                      0x00000001
#define SERVICE_START_PENDING                0x00000002
#define SERVICE_STOP_PENDING                 0x00000003
#define SERVICE_RUNNING                      0x00000004
#define SERVICE_CONTINUE_PENDING             0x00000005
#define SERVICE_PAUSE_PENDING                0x00000006
#define SERVICE_PAUSED                       0x00000007

#define SERVICE_ACCEPT_STOP                  0x00000001
#define SERVICE_ACCEPT_PAUSE_CONTINUE        0x00000002
#define SERVICE_ACCEPT_SHUTDOWN              0x00000004
#define SERVICE_ACCEPT_PARAMCHANGE           0x00000008
#define SERVICE_ACCEPT_NETBINDCHANGE         0x00000010
#define SERVICE_ACCEPT_HARDWAREPROFILECHANGE 0x00000020
#define SERVICE_ACCEPT_POWEREVENT            0x00000040

#define NO_ERROR                             0L
#define WAIT_TIMEOUT                         258L

#include "debug.ch"

#define SC_MANAGER_CONNECT                   0x0001
#define SC_MANAGER_CREATE_SERVICE            0x0002
#define SC_MANAGER_ALL_ACCESS                (0xF003F)

#define STANDARD_RIGHTS_REQUIRED             0x000F0000L

#define SERVICE_QUERY_CONFIG                 0x0001
#define SERVICE_CHANGE_CONFIG                0x0002
#define SERVICE_QUERY_STATUS                 0x0004
#define SERVICE_ENUMERATE_DEPENDENTS         0x0008
#define SERVICE_START                        0x0010
#define SERVICE_STOP                         0x0020
#define SERVICE_PAUSE_CONTINUE               0x0040
#define SERVICE_INTERROGATE                  0x0080
#define SERVICE_USER_DEFINED_CONTROL         0x0100
#define SERVICE_ALL_ACCESS  (STANDARD_RIGHTS_REQUIRED|SERVICE_QUERY_CONFIG|SERVICE_CHANGE_CONFIG|SERVICE_QUERY_STATUS|SERVICE_ENUMERATE_DEPENDENTS|SERVICE_START|SERVICE_STOP|SERVICE_PAUSE_CONTINUE|SERVICE_INTERROGATE|SERVICE_USER_DEFINED_CONTROL)

#ifndef SERVICE_WIN32_OWN_PROCESS
 #define SERVICE_WIN32_OWN_PROCESS           0x00000010
#endif 
#define SERVICE_INTERACTIVE_PROCESS          0x00000100

#define SERVICE_AUTO_START                   0x00000002

#define SERVICE_ERROR_NORMAL                 0x00000001
#define DELETE                               0x00010000L
