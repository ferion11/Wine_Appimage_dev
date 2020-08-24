#!/bin/bash

# If it's a Release Candidate, you will have to change P_VERSION to include the "-rc2" kind of string
#P_URL="https://www.playonlinux.com/wine/binaries/phoenicis/staging-linux-x86/PlayOnLinux-wine-5.11-staging-linux-x86.tar.gz"
P_URL="https://github.com/ferion11/f11_wine_builder/releases/download/continuous/wine-staging-5.11.tar.gz"

# wine
P_NAME="wine"

# staging-linux-x86
P_MVERSION="staging-linux-x86"

# PlayOnLinux-wine-4.21-staging-linux-x86.tar.gz
P_FILENAME="$(echo $P_URL | cut -d/ -f9)"

# PlayOnLinux
P_CSOURCE="f11"

# 4.21
TEMP="$(echo $P_FILENAME | cut -d- -f3)"
P_VERSION="${TEMP%???????}"

#========================================
echo "P_URL: $P_URL"
echo "P_NAME: $P_NAME"
echo "P_MVERSION: $P_MVERSION"
echo "P_FILENAME: $P_FILENAME"
echo "P_CSOURCE: $P_CSOURCE"
echo "P_VERSION: $P_VERSION"

# wine-i386_x86_64-archlinux.AppImage
# wine-staging-linux-x86-v4.21-PlayOnLinux-x86_64.AppImage
# ${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage
echo "RESULT: ${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage"
