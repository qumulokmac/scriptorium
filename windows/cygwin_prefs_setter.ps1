  # Define the path to the .minttyrc file
$minttyrcPath = "C:\Cygwin64\home\$env:USERNAME\.minttyrc"

# Define the settings to be added to the .minttyrc file
$minttyrcContent = @"
# Font settings
Font=Consolas
FontHeight=11

# Terminal background and foreground colors
BackgroundColour=0,0,0
ForegroundColour=255,0,255
ForegroundHue=200,240,120

# Cursor settings
CursorColour=255,0,0
CursorType=block

# Scrollback buffer size
ScrollbackLines=100000


# Set terminal size
Columns=150
Rows=40

# Window settings
BoldAsFont=yes
Transparency=none


# Set terminal position
Position=0,25
"@

# Create or overwrite the .minttyrc file with the specified settings
Set-Content -Path $minttyrcPath -Value $minttyrcContent -Force
# Set the correct permissions for the .minttyrc file
$icaclsCommand = "icacls `"$minttyrcPath`" /grant `"${env:USERNAME}:F`""
Invoke-Expression $icaclsCommand

 
 
