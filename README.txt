#### WifiHotspot.bat ####

 Batch File for Creating a Wifi Hotspot on a Laptop
       Made by Dimitrios Dimopoulos 2016
 Refreshed 2026 (input validation, admin check,
 Windows 10/11 notes and a PowerShell companion)
comments and suggestions at mitselec.wordpress.com


## What it does

Turns a laptop with both an Ethernet and a Wi-Fi adapter into a
wireless access point, so phones and tablets can use its internet.

The original mechanism is the Windows 7 "Hosted Network" feature
(netsh wlan set/start hostednetwork).


## Compatibility

- Windows 7/8:  fully supported.
- Windows 10/11: only if the Wi-Fi driver still supports Hosted
  Network. Microsoft deprecated it in Windows 10 1607 and most
  modern Wi-Fi 5/6 drivers report "Hosted network supported : No"
  (use menu option 1 to check yours).

On Windows 10/11 machines without Hosted Network support, use the
built-in Mobile Hotspot instead:

- Manually: Settings > Network & Internet > Mobile hotspot
  (or menu option 6 of the batch file, which opens that page).
- Automated: MobileHotspot.ps1 (see below). It uses Wi-Fi Direct,
  works on every Win10/11 Wi-Fi adapter, and needs no manual
  connection-sharing setup.


## Using WifiHotspot.bat (run as administrator)

1. Option 1: check that your driver reports "Hosted network
   supported : Yes".
2. Option 2: set the network name (1-32 chars) and password
   (8-63 chars, WPA2 requirement).
3. One-time setup - share the Ethernet connection:
   Control Panel > Network and Sharing Center > Change adapter
   settings > right-click your Ethernet adapter > Properties >
   Sharing tab > tick "Allow other network users to connect..."
   and select the "Local Area Connection*" adapter (the hosted
   network's virtual adapter). Starting the hotspot does NOT do
   this by itself.
4. Option 3: start the network. Option 4: stop it.
   Option 5: show the current status.

Notes: the password must not contain double quotes; if you
double-click the .bat without admin rights it will ask for
elevation via UAC.


## Using MobileHotspot.ps1 (Windows 10 1607+ / Windows 11)

Run with Windows PowerShell (powershell.exe), no admin rights needed:

    powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action Status
    powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action On
    powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action Off
    powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action Toggle

"Status" shows the hotspot name, password, state and connected
client count. The name and password are configured once in
Settings > Network & Internet > Mobile hotspot.
