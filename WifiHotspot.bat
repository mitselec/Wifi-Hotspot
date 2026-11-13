:: Batch File for Creating a Wifi Hotspot on a Laptop   ::
::       Made by Dimitrios Dimopoulos 2016              ::
:: Refreshed 2026: fixed input handling, added admin    ::
:: check, validation, a status view and a shortcut to   ::
:: the built-in Windows 10/11 Mobile Hotspot.           ::
:: comments and suggestions at mitselec.wordpress.com   ::

::Echoing off the messages and setting color::
@echo off
color 0A

:: All netsh commands below need administrator rights.  ::
:: If this window is not elevated, relaunch it elevated. ::
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Menu Screen::
:Start
:: Clear the previous choice so an empty Enter counts as invalid input::
set "_option="
cls
echo *************************************************
echo * Welcome to Hotspot Creation. Make your choice *
echo * 1.Check if your Laptop can be a Hotspot.      *
echo * 2.Set your Network parameters.                *
echo * 3.Start the Network.                          *
echo * 4.Stop the Network.                           *
echo * 5.Show the Network status.                    *
echo * 6.Open Windows Mobile Hotspot (Win10/11)      *
echo * 7.Exit                                        *
echo *************************************************

::          Variables                   ::
:: _option   = menu choice              ::
:: _SSID     = name of the network      ::
:: _password = password for the network ::


:: Main Program  ::
:: Input of user ::
set /p _option=Enter your input,then press Enter :

:: Option cases and result ::
:: Quoted comparisons, so spaces and special characters are safe::

::Hosted Network Supported option should be Yes::
if "%_option%"=="1" goto CheckSupport
if "%_option%"=="2" goto SetNetwork
if "%_option%"=="3" goto StartNetwork
if "%_option%"=="4" goto StopNetwork
if "%_option%"=="5" goto ShowStatus
if "%_option%"=="6" goto MobileHotspot
if "%_option%"=="7" exit /b

::Any other keystroke (also empty Enter)::
pause
goto Start

:: Check if the Wi-Fi driver still supports the Hosted Network ::
:CheckSupport
echo.
netsh wlan show drivers | findstr /i /c:"Hosted network supported"
echo.
echo "Yes" : this script works on this machine.
echo "No"  : your Wi-Fi driver dropped the old Hosted Network
echo        feature. This is typical on Windows 10/11 with modern
echo        Wi-Fi adapters - use option 6 or MobileHotspot.ps1.
echo.
pause
goto Start

::Set the SSID and Password of the Hosted Network::
:SetNetwork
echo.
set /p _SSID=Enter the name of your Network (1-32 chars, no double quotes) :
call :GetLen "%_SSID%" _len
if %_len% GEQ 1 if %_len% LEQ 32 goto AskPassword
echo The network name must be 1-32 characters long.
goto SetNetwork

:AskPassword
set /p _password=Enter the password of your Network (8-63 chars, no double quotes) :
call :GetLen "%_password%" _len
if %_len% GEQ 8 if %_len% LEQ 63 goto ApplyNetwork
echo The password must be 8-63 characters long (WPA2 requirement).
goto AskPassword

:ApplyNetwork
:: Quoting ssid and key so spaces in them do not split the command::
netsh wlan set hostednetwork mode=allow ssid="%_SSID%" key="%_password%"
if errorlevel 1 (
    echo.
    echo Could not save the network parameters - see the message above.
) else (
    echo.
    echo Network parameters saved.
)
pause
goto Start

::Start Network::
:StartNetwork
netsh wlan start hostednetwork
if errorlevel 1 (
    echo.
    echo Could not start the network. Common causes:
    echo  - Option 1 reported "No": this driver has no Hosted Network
    echo    support. Use option 6 or MobileHotspot.ps1 instead.
    echo  - Option 2 was never run, or the password is invalid.
) else (
    echo.
    echo Note: the hotspot does not share your Ethernet by itself.
    echo One-time setup:
    echo   Control Panel ^> Network and Sharing Center ^>
    echo   Change adapter settings ^> right-click your Ethernet
    echo   adapter ^> Properties ^> Sharing tab ^> tick
    echo   "Allow other network users to connect..." and select
    echo   the "Local Area Connection*" adapter.
)
pause
goto Start

::Stop Network::
:StopNetwork
netsh wlan stop hostednetwork
pause
goto Start

:ShowStatus
netsh wlan show hostednetwork
pause
goto Start

:: Built-in Win10/11 Mobile Hotspot (Wi-Fi Direct, works on all ::
:: modern Wi-Fi drivers - no manual ICS configuration needed)   ::
:MobileHotspot
echo.
echo Opening the built-in Mobile Hotspot settings (Windows 10/11 only)...
start "" ms-settings:network-mobilehotspot
echo.
echo Turn the hotspot on there and pick your Ethernet adapter as the
echo connection to share. Windows handles the sharing automatically.
pause
goto Start

:: Counts the characters of the string given as %1 and stores the ::
:: result in the variable named by %2.                            ::
:GetLen
setlocal
set "s=%~1"
set /a n=0
:GetLenLoop
if not defined s goto GetLenDone
set "s=%s:~1%"
set /a n+=1
goto GetLenLoop
:GetLenDone
endlocal & set "%~2=%n%"
goto :eof
