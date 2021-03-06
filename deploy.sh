#!/bin/bash
TMP_GLIBC_COPY="/tmp/.ff11_tmp_copy_appimage_ubuntu_bionic_glibc_i386_v0001"
#P_URL="https://github.com/ferion11/f11_wine_builder/releases/download/v5.11/wine-staging-5.11.tar.gz"
#P_URL="https://github.com/ferion11/f11_wine_builder/releases/download/continuous-last/wine-staging-5.18.tar.gz"
P_URL="https://github.com/ferion11/f11_wine_builder/releases/download/continuous-master/wine-staging-6.5.tar.gz"
P_NAME="wine"
P_MVERSION="staging-linux-x86"
P_FILENAME="$(echo ${P_URL} | cut -d/ -f9)"
P_CSOURCE="f11"
TEMP="$(echo $P_FILENAME | cut -d- -f3)"
P_VERSION="${TEMP%???????}"
WINE_WORKDIR="wineversion"
PKG_WORKDIR='/tmp/.pkgcachedir'

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

# test debug only:
#wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
#mv appimagetool.AppImage "${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage"
#echo "Content" > "${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-x86_64.AppImage.zsync"
#exit 0
# end test debug

#=========================
die() { echo >&2 "$*"; exit 1; };
#=========================

export UBUNTU_DISTRO="bionic"
export UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu/"

# add deps for wine:
sudo dpkg --add-architecture i386 >/dev/null
sudo add-apt-repository -y ppa:cybermax-dexter/sdl2-backport >/dev/null || die "* add-apt-repository fail!"

# updating wine https://wiki.winehq.org/Ubuntu:
wget -q https://dl.winehq.org/wine-builds/winehq.key >/dev/null || die "* wget winehq.key fail!"
sudo apt-key add <./winehq.key || die "* apt-key fail!"
sudo add-apt-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${UBUNTU_DISTRO} main" >/dev/null
sudo apt-get -q -y update >/dev/null
#-----------------------------------

sudo apt install -y aptitude wget file bzip2 patchelf || die "ERROR: Some packages not found! to run the script!!!"
#===========================================================================================
mkdir -p "$WINE_WORKDIR"
mkdir -p "${PKG_WORKDIR}"

# Get Wine
wget -nv -c "${P_URL}"
tar xf $P_FILENAME -C "$WINE_WORKDIR"/

#===========================================================================================

cd "$WINE_WORKDIR" || die "ERROR: Directory don't exist: $WINE_WORKDIR"

sudo aptitude -y -d -o dir::cache::archives="${PKG_WORKDIR}" install winehq-staging wine-staging wine-staging-amd64 wine-staging-i386 winbind cabextract libva2:i386 libva-drm2:i386 libva-x11-2:i386 libvulkan1:i386 || die "* aptitude cache install fail!"
sudo aptitude -y -d -o dir::cache::archives="${PKG_WORKDIR}" reinstall libjpeg-turbo8 || die "* aptitude cache reinstall fail!"

sudo chmod 777 "${PKG_WORKDIR}" -R

find "${PKG_WORKDIR}" -name '*deb' ! -name 'wine*' -exec dpkg -x {} . \;

rm -rf "${PKG_WORKDIR}"

#----------------------------------------------

## WINE_WORKDIR cleanup
#rm -rf cache; rm -rf include; rm usr/lib32/{*.a,*.o}; rm -rf usr/lib32/pkgconfig; rm -rf share/man; rm -rf usr/include; rm -rf usr/share/{applications,doc,emacs,gtk-doc,java,licenses,man,info,pkgconfig}; rm usr/lib32/locale
#rm -rf boot; rm -rf dev; rm -rf home; rm -rf mnt; rm -rf opt; rm -rf proc; rm -rf root; rm sbin; rm -rf srv; rm -rf sys; rm -rf tmp; rm -rf var
#rm -rf usr/src; rm -rf usr/share; rm usr/sbin; rm -rf usr/local; rm usr/lib/{*.a,*.o}
rm -rf sbin; rm -rf var;
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

# find and patching the x86 executables with glibc on bin
# ./bin
for file_i in $(find ./bin -type f -perm -u+x 2>&1); do
	IS_X86_EXEC="$(file ${file_i} 2>&1 | grep ld-linux.so.2)"

	if [ -n "${IS_X86_EXEC}" ]; then
		echo "======="
		echo "patch: ${file_i}"
		patchelf --set-interpreter ${TMP_GLIBC_COPY}/ld-linux.so.2 --set-rpath ${TMP_GLIBC_COPY} ${file_i}
		echo "======="
	fi
done
# and usr/bin:
for file_i in $(find ./usr/bin -type f -perm -u+x 2>&1); do
	IS_X86_EXEC="$(file ${file_i} 2>&1 | grep ld-linux.so.2)"

	if [ -n "${IS_X86_EXEC}" ]; then
		echo "======="
		echo "patch: ${file_i}"
		patchelf --set-interpreter ${TMP_GLIBC_COPY}/ld-linux.so.2 --set-rpath ${TMP_GLIBC_COPY} ${file_i}
		echo "======="
	fi
done

#===========================================================================================

# appimage
cd ..

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
chmod +x appimagetool.AppImage

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

