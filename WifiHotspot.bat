:: Batch File for Creating a Wifi Hotspot on a Laptop   ::
::       Made by Dimitrios Dimopoulos 2016              ::
:: comments and suggestions at mitselec.wordpress.com   ::

::Echoing off the messages and setting color::
@echo off
color 0A
::Setlocal is to enable updating the variables::
Setlocal EnableDelayedExpansion 

:: Menu Screen::
:Start
cls
echo *************************************************
echo * Welcome to Hotspot Creation. Make your choice *
echo * 1.Check if your Laptop can be a Hotspot.      *
echo * 2.Set your Network parameters.                *
echo * 3.Start the Network.                          *
echo * 4.Stop the Network.                           *
echo * 5.Exit                                        *
echo *************************************************

::          Variables                   ::
:: _option = menu choice                ::
:: _SSID = name of the network          ::
:: _password = password for the network ::


:: Main Program  ::
:: Input of user ::
set /p _option=Enter your input :

:: Option cases and result ::

::Hosted Network Supported option should be Yes::
If %_option%==1 (netsh wlan show drivers | more
	set /p=Hit Enter to return to the menu...
	goto Start)
	
::Set the SSID and Password of the Hosted Network::
If %_option%==2 ( set /p _SSID=Enter the name of your Network :
	set /p _password=Enter the password of your Network :
	netsh wlan set hostednetwork mode=allow ssid=!_SSID! key=!_password!
	goto Start)
	
::Start Network::
if %_option%==3 (netsh wlan start hostednetwork
	goto Start)
	
::Stop Network::	
if %_option%==4 (netsh wlan stop hostednetwork
	goto Start)
	
::  Exit  ::	
If %_option%==5 exit

::Any other keystroke::
set /p=Invalid input.Press Enter to return to menu...
goto Start 
	