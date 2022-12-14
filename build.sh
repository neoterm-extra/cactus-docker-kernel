#!/bin/bash
sudo apt update && sudo apt install ccache
# Export
export ARCH="arm"
export SUBARCH="arm"
export PATH="/usr/lib/ccache:$PATH"
export KBUILD_BUILD_USER="mcstark"
export KBUILD_BUILD_HOST="Github"
export branch="10-alps"
export device="cactus"
export LOCALVERSION="-mcstark"
export kernel_repo="https://github.com/neoterm-extra/android_kernel_xiaomi_mt6765.git"
export tc_repo="https://github.com/neoterm-extra/linaro_arm-linux-gnueabihf-7.5.git"
export tc_name="arm-linux-gnueabihf"
export tc_v="7.5"
export zip_name="kernel-""$device""-"$(env TZ='Asia/Jakarta' date +%Y%m%d)""
export KERNEL_DIR=$(pwd)
export KERN_IMG="$KERNEL_DIR"/kernel/out/arch/"$ARCH"/boot/zImage-dtb
export ZIP_DIR="$KERNEL_DIR"/AnyKernel
export CONFIG_DIR="$KERNEL_DIR"/kernel/arch/"$ARCH"/configs
export CORES=$(grep -c ^processor /proc/cpuinfo)
export THREAD="-j$CORES"
CROSS_COMPILE+="ccache "
CROSS_COMPILE+="$KERNEL_DIR"/"$tc_name"-"$tc_v"/bin/"$tc_name-"
export CROSS_COMPILE

function sync(){
	SYNC_START=$(date +"%s")
	cd "$KERNEL_DIR" && git clone -b "$branch" "$kernel_repo" --depth 1 kernel
	cd "$KERNEL_DIR" && git clone "$tc_repo" "$tc_name"-"$tc_v"
	chmod -R a+x "$KERNEL_DIR"/"$tc_name"-"$tc_v"
	SYNC_END=$(date +"%s")
	SYNC_DIFF=$((SYNC_END - SYNC_START))
	}
function build(){
	BUILD_START=$(date +"%s")
	cd "$KERNEL_DIR"/kernel
	export last_tag=$(git log -1 --oneline)
	make  O=out "$device"_defconfig "$THREAD" > "$KERNEL_DIR"/kernel.log
	make "$THREAD" O=out >> "$KERNEL_DIR"/kernel.log
	BUILD_END=$(date +"%s")
	BUILD_DIFF=$((BUILD_END - BUILD_START))
	export BUILD_DIFF
}
function success(){
	Dev : ""$KBUILD_BUILD_USER""
	Product : Kernel
	Device : #""$device""
	Branch : ""$branch""
	Host : ""$KBUILD_BUILD_HOST""
	Commit : ""$last_tag""
	Compiler : ""$(${CROSS_COMPILE}gcc --version | head -n 1)""
	Date : ""$(env TZ=Asia/Jakarta date)"""
	
	exit 0
}
function failed(){
	exit 1
}
function check_build(){
	if [ -e "$KERN_IMG" ]; then
		cp "$KERN_IMG" "$ZIP_DIR"
		cd "$ZIP_DIR"
		mv zImage-dtb zImage
		zip -r "$zip_name".zip ./*
		success
	else
		failed
	fi
}
function main(){
	sync
	build
	check_build
}
main
