#!/bin/bash
P_URL="https://github.com/ferion11/f11_wine_builder/releases/download/v5.11/wine-staging-5.11.tar.gz"
P_NAME="wine"
P_MVERSION="staging-linux-x86"
P_FILENAME="$(echo ${P_URL} | cut -d/ -f9)"
P_CSOURCE="f11"
TEMP="$(echo $P_FILENAME | cut -d- -f3)"
P_VERSION="${TEMP%???????}"
WINE_WORKDIR="wineversion"
PKG_WORKDIR="pkg_work"

echo "P_URL: ${P_URL}"
echo "P_NAME: ${P_NAME}"
echo "P_MVERSION: ${P_MVERSION}"
echo "P_FILENAME: ${P_FILENAME}"
echo "P_CSOURCE: ${P_CSOURCE}"
echo "P_VERSION: ${P_VERSION}"

# wine-i386_x86_64-archlinux.AppImage
# wine-staging-linux-x86-v4.21-PlayOnLinux-x86_64.AppImage
# ${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage
echo "RESULT: ${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage"

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
mv appimagetool.AppImage "${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage"
touch "${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage.zsync"
exit 0

#=========================
die() { echo >&2 "$*"; exit 1; };
#=========================

#Add "base-devel multilib-devel" for compile in the list:
pacman -S --noconfirm wget git tar grep sed zstd xz bzip2 || die "ERROR: Some packages not found! to run the script!!!"
#===========================================================================================

#-----------------------------------

# Get Wine
wget -nv -c $P_URL
tar xf $P_FILENAME -C "$WINE_WORKDIR"/

#===========================================================================================

cd "$WINE_WORKDIR" || die "ERROR: Directory don't exist: $WINE_WORKDIR"

# Add a dependency library, such as freetype font library
dependencys=$(pactree -s -u wine |grep lib32 | xargs)

mkdir cache
#mv *.pkg.tar* ./cache/ || die "ERROR: None package builded from AUR"
mv *.pkg.tar* ./cache/ || echo "INFO: None package builded from AUR"

pacman -Scc --noconfirm
pacman -Syw --noconfirm --cachedir cache lib32-alsa-lib lib32-alsa-plugins lib32-faudio lib32-fontconfig lib32-freetype2 lib32-gcc-libs lib32-gettext lib32-giflib lib32-glu lib32-gnutls lib32-gst-plugins-base lib32-lcms2 lib32-libjpeg-turbo lib32-libjpeg6-turbo lib32-libldap lib32-libpcap lib32-libpng lib32-libpng12 lib32-libsm lib32-libxcomposite lib32-libxcursor lib32-libxdamage lib32-libxi lib32-libxml2 lib32-libxmu lib32-libxrandr lib32-libxslt lib32-libxxf86vm lib32-mesa lib32-mesa-libgl lib32-mpg123 lib32-ncurses lib32-openal lib32-sdl2 lib32-v4l-utils lib32-libdrm lib32-libva lib32-krb5 lib32-flac lib32-gst-plugins-good lib32-libcups lib32-libwebp lib32-libvpx lib32-libvpx1.3 lib32-portaudio lib32-sdl lib32-sdl2_image lib32-sdl2_mixer lib32-sdl2_ttf lib32-sdl_image lib32-sdl_mixer lib32-sdl_ttf lib32-smpeg lib32-speex lib32-speexdsp lib32-twolame lib32-ladspa lib32-libao lib32-libvdpau lib32-libpulse lib32-libcanberra-pulse lib32-libcanberra-gstreamer lib32-glew lib32-mesa-demos lib32-jansson lib32-libxinerama lib32-atk lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-radeon lib32-vkd3d lib32-aom lib32-gsm lib32-lame lib32-libass lib32-libbluray lib32-dav1d lib32-libomxil-bellagio lib32-x264 lib32-x265 lib32-xvidcore lib32-opencore-amr lib32-openjpeg2 lib32-ncurses5-compat-libs $dependencys || die "ERROR: Some packages not found!!!"

# Remove non lib32 pkgs before extracting
#echo "All files in ./cache: $(ls ./cache)"
find ./cache -type f ! -name "lib32*" -exec rm {} \; -exec echo "Removing: {}" \;
#find ./cache -type f -name "*x86_64*" -exec rm {} \; -exec echo "Removing: {}" \; #don't work because the name of lib32 multilib packages have the x86_64 too
echo "DEBUG: clean some packages"
rm -rf ./cache/lib32-clang*
rm -rf ./cache/lib32-nvidia-cg-toolkit*
rm -rf ./cache/lib32-ocl-icd*
rm -rf ./cache/lib32-opencl-mesa*
echo "All files in ./cache: $(ls ./cache)"


# extracting *tar.xz...
find ./cache -name '*tar.xz' -exec tar --warning=no-unknown-keyword -xJf {} \;

# extracting *tar.zst...
find ./cache -name '*tar.zst' -exec tar --warning=no-unknown-keyword --zstd -xf {} \;

# extracting *tar...
find ./cache -name '*tar' -exec tar --warning=no-unknown-keyword -xf {} \;

#----------------------------------------------

## WINE_WORKDIR cleanup
#rm -rf cache; rm -rf include; rm usr/lib32/{*.a,*.o}; rm -rf usr/lib32/pkgconfig; rm -rf share/man; rm -rf usr/include; rm -rf usr/share/{applications,doc,emacs,gtk-doc,java,licenses,man,info,pkgconfig}; rm usr/lib32/locale
#rm -rf boot; rm -rf dev; rm -rf home; rm -rf mnt; rm -rf opt; rm -rf proc; rm -rf root; rm sbin; rm -rf srv; rm -rf sys; rm -rf tmp; rm -rf var
#rm -rf usr/src; rm -rf usr/share; rm usr/sbin; rm -rf usr/local; rm usr/lib/{*.a,*.o}
#===========================================================================================

## fix broken link libglx_indirect and others
#rm usr/lib32/libGLX_indirect.so.0
#ln -s libGLX_mesa.so.0 libGLX_indirect.so.0
#mv -n libGLX_indirect.so.0 usr/lib32
#--------

#rm usr/lib32/libkeyutils.so
#ln -s libkeyutils.so.1 libkeyutils.so
#mv -n libkeyutils.so usr/lib32
##--------

## workaround some of "wine --check-libs" wrong versions
#ln -s libpcap.so libpcap.so.0.8
#mv -n libpcap.so.0.8 usr/lib32

#ln -s libva.so libva.so.1
#ln -s libva-drm.so libva-drm.so.1
#ln -s libva-x11.so libva-x11.so.1
#mv -n libva.so.1 usr/lib32
#mv -n libva-drm.so.1 usr/lib32
#mv -n libva-x11.so.1 usr/lib32

#===========================================================================================

# Disable PulseAudio
rm etc/asound.conf; rm -rf etc/modprobe.d/alsa.conf; rm -rf etc/pulse

# Disable winemenubuilder
sed -i 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' share/wine/wine.inf

# Disable FileOpenAssociations
sed -i 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' share/wine/wine.inf
#===========================================================================================

# appimage
cd ..

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
chmod +x appimagetool.AppImage

exit 0
#?????????????????????????????????????????????

cp resource/* ${WINE_WORKDIR}

chmod +x ${WINE_WORKDIR}/AppRun
#-----------------------------

##test for others AppImage variations (have to change .travis.yml too):
#cp -rp $WINE_WORKDIR test2
#mkdir test2/mark_test2
#-----------------------------

./appimagetool.AppImage --appimage-extract

#export ARCH=x86_64; squashfs-root/AppRun -v $WINE_WORKDIR -u 'gh-releases-zsync|ferion11|Wine_Appimage|continuous|wine-i386*arch*.AppImage.zsync' wine-i386_${ARCH}-archlinux.AppImage
export ARCH=x86_64; squashfs-root/AppRun -v $WINE_WORKDIR -u 'gh-releases-zsync|ferion11|Wine_Appimage|continuous|${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-*arch*.AppImage.zsync' ${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-${ARCH}.AppImage


rm -rf appimagetool.AppImage

