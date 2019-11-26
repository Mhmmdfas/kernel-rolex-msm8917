#!bin/bash
# Copyright (C) 2019 Keifaisal (@keizzn)
# Copyright (C) 2019 Muhammad Fadlyas! (@Mhmmdfas)
# Circle CI/CD script For Xiaomi Redmi 4A

#
# Telegram FUNCTION begin
#
git clone https://github.com/fabianonline/telegram.sh telegram

TELEGRAM_ID=${chat_id}
TELEGRAM_TOKEN=${token}
TELEGRAM=telegram/telegram

export TELEGRAM_TOKEN

# Push kernel installer to channel
function push() {
	ZIP=$(echo Steel*.zip)
	curl -F document=@$ZIP  "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendDocument" \
			-F chat_id="${TELEGRAM_ID}" \
			-F "disable_web_page_preview=true" \
			-F "parse_mode=html" \
			-F caption="[ <code>${UTS}</code> ]"
}

# Send the info up
function tg_channelcast() {
	"${TELEGRAM}" -c ${TELEGRAM_ID} -H \
		"$(
			for POST in "${@}"; do
				echo "${POST}"
			done
		)"
}

function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
		-d "parse_mode=markdown" \
		-d text="${1}" \
		-d chat_id="${TELEGRAM_ID}" \
		-d "disable_web_page_preview=true"
}

# Fin Error
function finerr() {
	curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
		-d "parse_mode=markdown" \
		-d text="Build throw an error(s)." \
		-d chat_id="${TELEGRAM_ID}" \
		-d "disable_web_page_preview=true"
	exit 1
}

# Send sticker
function tg_sendstick() {
	curl -s -F chat_id=${TELEGRAM_ID} -F sticker="CAADBQAD3AADfULDLpHzWZltpdJ5FgQ" https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendSticker
}

# Fin prober
function fin() {
	tg_sendinfo "$(echo "Build took $((${DIFF} / 60)) minute(s) and $((${DIFF} % 60)) seconds.")"
}

# Clean stuff
function clean() {
	rm -rf out anykernel3/Steel* anykernel3/zImage
}

#
# Telegram FUNCTION end
#

# Main environtment
MACHINE="Circle CI/CD"
DEVICES="Xiaomi Redmi 4A"
KERNEL_DIR="$(pwd)"
KERN_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
ZIP_DIR="$KERNEL_DIR/anykernel3"
NUM=$(echo $CIRCLE_BUILD_NUM | cut -c 1-2)
CONFIG="rolex_defconfig"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
THREAD="-j60"
LOAD="-l50"
ARM="arm64"
GCC="$(pwd)/gcc/bin/aarch64-linux-android-"
GCC32="$(pwd)/gcc32/bin/arm-linux-androideabi-"

# Export
export ARCH=${ARM}
export KBUILD_BUILD_USER=Mhmmdfas
export KBUILD_BUILD_HOST=SteelHeartCI-${NUM}
export USE_CCACHE=1
export CACHE_DIR=~/.ccache

# Clone toolchain
git clone --quiet -j32 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r49 --depth=1 gcc
git clone --quiet -j32 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r49 --depth=1 gcc32
# Clone AnyKernel3
git clone --quiet -j32 https://github.com/fadlyas07/AnyKernel3 --depth=1 anykernel3

# Build start
tanggal=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
DATE=`date`
BUILD_START=$(date +"%s")

tg_sendstick

tg_channelcast "<b>SteelHeart CI new build is up</b>!!" \
		"Started on <code>${MACHINE}</code>" \
		"For devices <code>${DEVICES}</code>" \
		"From branch <code>${BRANCH}</code>" \
                "Latest Commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>" \
                "Using Compiler: <code>$(${GCC}gcc --version | head -n 1)</code>" \
                "Using Compiler: <code>$(${GCC32}gcc --version | head -n 1)</code>" \
		"Started on <code>$(TZ=Asia/Jakarta date)</code>"

make -s -C $(pwd) ${THREAD} ${LOAD} O=out ${CONFIG}
make -s -C $(pwd) CROSS_COMPILE=${GCC} \
                  CROSS_COMPILE_ARM32=${GCC32} \
                  O=out ${THREAD} ${LOAD} 2>&1| tee build.log
UTS=$(cat out/include/generated/compile.h | grep UTS_VERSION | cut -d '"' -f2)

if ! [ -a ${KERN_IMG} ]; then
	finerr
	exit 1
fi

cp ${KERN_IMG} ${ZIP_DIR}/zImage
cd ${ZIP_DIR}
zip -r9 Steelheart-rolex-"${tanggal}".zip *
BUILD_END=$(date +"%s")
DIFF=$((${BUILD_END} - ${BUILD_START}))
push
cd ../..
fin
clean
# Build end
