#!/bin/bash
# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

# MIUI = High Dimens
# OSS = Low Dimens

API_BOT="8136206822:AAFM4gOpsJZZjNFg6G5c0F-yDkwrt1ZKDGo"
CHATID="-2660236835"
export CHATID API_BOT TYPE_KERNEL

# Kernel build config
TYPE="MIUI"
DEVICE_TYPE="sweet"
#KERNEL_NAME="X-Derm"
DEFCONFIG="vendor/sweet_user_defconfig"
AnyKernel="https://github.com/RooGhz720/Anykernel3"
AnyKernelbranch="master"
HOSST="Vҽ.."
USEER="root"
ID="1"
MESIN="Git Workflows"


# setup telegram env
export WAKTU=$(date +"%T")
export TGL=$(date +"%d-%m-%Y")
export BOT_MSG_URL="https://api.telegram.org/bot$API_BOT/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$API_BOT/sendDocument"

tg_post_msg() {
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
        -d "parse_mode=markdown" \
        -d text="$1"
}

tg_post_build() {
        #Show the Checksum alongwith caption
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=markdown" 
}

tg_error() {
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$3Failed to build , check <code>error.log</code>"
}

#if ! [ -d "$HOME/cosmic" ]; then
if ! [ -d "HOME/zyc-clang" ]; then
echo "ZyC-clang not found! Cloning..."
#if ! git clone -q https://gitlab.com/GhostMaster69-dev/cosmic-clang.git --depth=1 -b master ~/cosmic; then
if ! git clone -q https://gitlab.com/clangsantoni/zyc_clang.git --depth=1 -b 21 ~/zyc-clang; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

#export PATH="$HOME/cosmic/bin:$PATH"
export PATH="$HOME/zyc-clang/bin:$PATH"
export KBUILD_COMPILER_STRING="$($HOME/zyc-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
#export KBUILD_COMPILER_STRING="$($HOME/cosmic/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

# Speed up build process
MAKE="./makeparallel"

# Setup build process
build_kernel() {
Start=$(date +"%s")

	make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              CC=clang \
			                        CLANG_TRIPLE=aarch64-linux-gnu- \
                              CROSS_COMPILE=aarch64-linux-gnu- \
			                        CROSS_COMPILE=aarch64-linux-android- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi-  2>&1 | tee error.log

End=$(date +"%s")
Diff=$(($End - $Start))
}

# Let's start
echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"
export KBUILD_BUILD_VERSION="$ID"

mkdir -p out

make clean && make O=out mrproper
make "$DEFCONFIG" O=out

echo -e "$yellow << compiling the kernel >> \n $white"

# stiker post


build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)
KOMIT=$(git log --pretty=format:'"%h : %s"' -2)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz-dtb
export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img


        if [ -f "$IMG" ]; then
                echo -e "$green << selesai dalam $(($Diff / 60)) menit and $(($Diff % 60)) detik >> \n $white"
        else
                echo -e "$red << Gagal dalam membangun kernel!!! , cek kembali kode anda >>$white"
                #tg_post_msg "GAGAL!!! uploading log"
                #tg_error "error.log" "$CHATID"
                rm -rf out
                rm -rf testing.log
                rm -rf error.log
                exit 1
        fi
        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone --depth=1 "$AnyKernel" --single-branch -b "$AnyKernelbranch" zip
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" zip/
                cp -r "$dtbo" zip/
                cp -r "$dtb" zip/
                cd zip
                export ZIP="$KERNEL_NAME"-"$TYPE"-"$TGL"
                zip -r9 "$ZIP" * -x .git README.md LICENSE *placeholder
                curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
                java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
                tg_post_build "$ZIP"-signed.zip "$CHATID"
                cd ..
                rm -rf error.log
                rm -rf out
                rm -rf zip
                rm -rf testing.log
                exit
	fi
