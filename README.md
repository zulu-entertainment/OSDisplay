# OSDisplay
macOS application to have a BezelUI like OSD

Install:
----
Build with xcode and copy OSDisplay.app to /Applications

Usage:
----
/Applications/OSDisplay.app/Contents/MacOS/OSDisplay -h

    Arguments:
 
      -i	path to image-file
   
      -m	message (string)
   
      -l	value (0-100 @5)
   
      -d	delay (1.0-60.0 seconds)
   
      -t	auto|open|close|eject (external cd/dvd writer)
   
      -h	(show help text)
   
 Images become resized (max x150) and tinted to support the activated color-mode (light or dark).
 
 Supported formats are: .png .pdf .tiff
 
    Built-In images can be used with:
 
      -i	brightness
   
      -i	contrast
   
      -i	eject
   
      -i	monitor
   
      -i	information
   
      -i	monster


Examples:
----
/Applications/OSDisplay.app/Contents/MacOS/OSDisplay -m 'OSDisplay'  -i 'monster' -d '5'
/Applications/OSDisplay.app/Contents/MacOS/OSDisplay -l '50'  -i 'monitor' -d '5'
