#! /bin/bash

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

echo $_HOME_
cd $_HOME_


build_for='
ubuntu:20.04
'

for system_to_build_for in $build_for ; do

    system_to_build_for_orig="$system_to_build_for"
    system_to_build_for=$(echo "$system_to_build_for_orig" 2>/dev/null|tr ':' '_' 2>/dev/null)

    cd $_HOME_/
    mkdir -p $_HOME_/"$system_to_build_for"/

    mkdir -p $_HOME_/"$system_to_build_for"/artefacts
    mkdir -p $_HOME_/"$system_to_build_for"/script
    mkdir -p $_HOME_/"$system_to_build_for"/workspace

    ls -al $_HOME_/"$system_to_build_for"/

    rsync -a ../ --exclude=.localrun $_HOME_/"$system_to_build_for"/workspace/build
    chmod a+rwx -R $_HOME_/"$system_to_build_for"/workspace/build

    echo '#! /bin/bash

###################################
###################################

export DAV1D_VERSION="a029d6892c5c39f4cda629d4a3b676ef2e8288f6"
export AAR_VERSION="1.0.2"
export AAR_VER_CODE=10002

###################################
###################################

export DEBIAN_FRONTEND=noninteractive

os_release=$(cat /etc/os-release 2>/dev/null|grep "PRETTY_NAME=" 2>/dev/null|cut -d"=" -f2)
echo "# using /etc/os-release"
system__=$(cat /etc/os-release 2>/dev/null|grep "^NAME=" 2>/dev/null|cut -d"=" -f2|tr -d "\""|sed -e "s#\s##g")
version__=$(cat /etc/os-release 2>/dev/null|grep "^VERSION_ID=" 2>/dev/null|cut -d"=" -f2|tr -d "\""|sed -e "s#\s##g")

echo "# compiling on: $system__ $version__"

pkgs_Ubuntu_20_04="
    :u:
    ca-certificates
    cmake
    git
    unzip
    zip
    automake
    autotools-dev
    build-essential
    check
    checkinstall
    libtool
    pkg-config
    rsync
    meson
    ninja
    nasm
    wget
"

pkgs_name="pkgs_"$(echo "$system__"|tr "." "_"|tr "/" "_")"_"$(echo $version__|tr "." "_"|tr "/" "_")
echo "PKG:-->""$pkgs_name""<--"

for i in ${!pkgs_name} ; do
    if [[ ${i:0:3} == ":u:" ]]; then
        echo "apt-get update"
        apt-get update > /dev/null 2>&1
    elif [[ ${i:0:3} == ":c:" ]]; then
        cmd=$(echo "${i:3}"|sed -e "s#\\\s# #g")
        echo "$cmd"
        $cmd > /dev/null 2>&1
    else
        echo "apt-get install -y --force-yes ""$i"
        apt-get install -qq -y --force-yes $i > /dev/null 2>&1
    fi
done


#------------------------


mkdir /workspace/ndk/
cd /workspace/ndk/
rm -f ndk.zip
wget https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip -O ndk.zip
unzip ndk.zip

export ANDROID_NDK_HOME=/workspace/ndk/android-ndk-r21e/
export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME

#export PATH=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/:\
#  $ANDROID_NDK_HOME/toolchains/x86_64-4.9/prebuilt/linux-x86_64/bin/:$PATH
#meson build --buildtype release --cross-file=package/crossfiles/x86_64-android.meson --default-library=static

export PATH=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/:$PATH

# --------------------------------------------------------------------------------------------

rm -Rf /workspace/build/dav1d/
cd /workspace/build/
git clone https://code.videolan.org/videolan/dav1d
cd dav1d/
git checkout "$DAV1D_VERSION"

cd /workspace/build/dav1d/

meson build --buildtype release --cross-file=package/crossfiles/aarch64-android.meson --default-library=static

cd build
ninja

ls -al /workspace/build/dav1d/build/src/libdav1d.a
file /workspace/build/dav1d/build/src/libdav1d.a
mkdir -p /workspace/jni/arm64-v8a/
cp -av /workspace/build/dav1d/build/src/libdav1d.a /workspace/jni/arm64-v8a/libdav1d.a

# --------------------------------------------------------------------------------------------

rm -Rf /workspace/build/dav1d/
cd /workspace/build/
git clone https://code.videolan.org/videolan/dav1d
cd dav1d/
git checkout "$DAV1D_VERSION"

cd /workspace/build/dav1d/

meson build --buildtype release --cross-file=package/crossfiles/arm-android.meson --default-library=static

cd build
ninja

ls -al /workspace/build/dav1d/build/src/libdav1d.a
file /workspace/build/dav1d/build/src/libdav1d.a
mkdir -p /workspace/jni/armeabi-v7a/
cp -av /workspace/build/dav1d/build/src/libdav1d.a /workspace/jni/armeabi-v7a/libdav1d.a

# --------------------------------------------------------------------------------------------

cd /workspace/build/

# cp -av /workspace/build/2/jni/x86/libdav1d.a
# cp -av /workspace/build/2/jni/x86_64/libdav1d.a
cp -av /workspace/jni/arm64-v8a/libdav1d.a /workspace/build/2/jni/arm64-v8a/libdav1d.a
cp -av /workspace/jni/armeabi-v7a/libdav1d.a /workspace/build/2/jni/armeabi-v7a/libdav1d.a

ls -al /workspace/build/2/jni/arm64-v8a/libdav1d.a
ls -al /workspace/build/2/jni/armeabi-v7a/libdav1d.a
chmod 0644 /workspace/build/2/jni/arm64-v8a/libdav1d.a
chmod 0644 /workspace/build/2/jni/armeabi-v7a/libdav1d.a
ls -al /workspace/build/2/jni/arm64-v8a/libdav1d.a
ls -al /workspace/build/2/jni/armeabi-v7a/libdav1d.a

# --------------------------------------------------------------------------------------------

cd /workspace/build/
cd 2/

cat AndroidManifest.xml
sed -i -e "s#10001#${AAR_VER_CODE}#" AndroidManifest.xml
sed -i -e "s#1.0.1#${AAR_VERSION}#" AndroidManifest.xml
cat AndroidManifest.xml

zip -r libavif-jni-lib-"$AAR_VERSION".aar *
cp -av libavif-jni-lib-"$AAR_VERSION".aar \
   ../1/root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1/libavif-jni-lib-"$AAR_VERSION".aar

rm -fv ../1/root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1/libavif-jni-lib-1.0.1.aar

# --------------------------------------------------------------------------------------------

cd /workspace/build/
cd 1/

cat ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/maven-metadata-local.xml
sed -i -e "s#1.0.1#${AAR_VERSION}#" ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/maven-metadata-local.xml
d_=$(date "+%Y%m%d")
sed -i -e "s#20220730#${d_}#" ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/maven-metadata-local.xml
cat ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/maven-metadata-local.xml

cat ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1/libavif-jni-lib-1.0.1.pom
sed -i -e "s#1.0.1#${AAR_VERSION}#" ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1/libavif-jni-lib-1.0.1.pom
cat ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1/libavif-jni-lib-1.0.1.pom

mv -v ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1/libavif-jni-lib-1.0.1.pom \
      ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1/libavif-jni-lib-"$AAR_VERSION".pom

mv -v ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/1.0.1 \
      ./root/.m2/repository/com/zoffcc/applications/libavifjni/libavif-jni-lib/"$AAR_VERSION"

# --------------------------------------------------------------------------------------------

cd /workspace/build/
cd 1/
zip -r local_maven_pkgs_libavif_"$AAR_VERSION".zip root

# --------------------------------------------------------------------------------------------

cp -v /workspace/build/1/local_maven_pkgs_libavif_"$AAR_VERSION".zip /artefacts/
chmod a+rw /artefacts/*

' > $_HOME_/"$system_to_build_for"/script/run.sh

    docker run -ti --rm \
      -v $_HOME_/"$system_to_build_for"/artefacts:/artefacts \
      -v $_HOME_/"$system_to_build_for"/script:/script \
      -v $_HOME_/"$system_to_build_for"/workspace:/workspace \
      --net=host \
     "$system_to_build_for_orig" \
     /bin/sh -c "apk add bash >/dev/null 2>/dev/null; /bin/bash /script/run.sh"
     if [ $? -ne 0 ]; then
        echo "** ERROR **:$system_to_build_for_orig"
        exit 1
     else
        echo "--SUCCESS--:$system_to_build_for_orig"
     fi

done


