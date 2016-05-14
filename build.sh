#!/bin/bash

echo "Export ARCH"
export ARCH=arm
echo "Done"

## Replace "./Toolchain/UBERTC-arm-linux-androideabi-5.3" with your toolcahin directory to switch to a different toolchain.
echo "Export Compiler"  
export CROSS_COMPILE=./Toolchain/UBERTC-arm-linux-androideabi-5.3/bin/arm-linux-androideabi-
echo "Done"

echo "Enter Device Codename"
read device
echo "Clean Rusty boot directory? y/N"
read clean
echo "Clean Output? y/N"
read cleanout
echo "new .config? y/N"
read dc
echo "Configure Rusty? y/N"
read config
echo "Build Rusty kernel? y/N"
read build
echo "make dtb? y/N"
read dtb
echo "Package flashable zip? y/N"
read zip

if [ "$clean" = "y" ]
then
	echo "cleaning"
	make clean
fi
if [ $cleanout = "y" ]
then
	rm -rf ./Output/${device}/rusty/boot.img
fi

if [ "$dc" = "y" ]
then
	echo "Replacing .config"
	make ${device}_global_com_defconfig
fi

if [ "$config" = "y" ]
then
	echo "starting menuconfig"
	make menuconfig
fi	

if [ "$build" = "y" ]
then
	if [ -e "./arch/arm/boot/dt.img" ]; then
	rm ./arch/arm/boot/dt.img
	fi

	if [ -e "./arch/arm/boot/msm8226-v1-${device}.dtb" ]; then
	rm ./arch/arm/boot/msm8226-v1-${device}.dtb
	rm ./arch/arm/boot/msm8226-v2-${device}.dtb
	fi
		
		echo "Building RustyKernel"
		make -j3
fi

if [ "$dtb" = "y" ]
then
	make dtbs
	./dtbToolCM -2 -s 2048 -p ./scripts/dtc/ -o ./arch/arm/boot/dt.img ./arch/arm/boot/
fi

if [ "$zip" = "y" ]
then
	echo "Copying files to respective folder"

		cd ./buildtools
		./cleanup.sh
		./unpackimg.sh boot.img
		cp ./boot.img-ramdiskcomp ./split_img/boot.img-ramdiskcomp
		cp ../arch/arm/boot/zImage ./split_img/boot.img-zImage
		cp ../arch/arm/boot/dt.img ./split_img/boot.img-dtb
		echo "Repacking Kernel"
		./repackimg.sh
		echo "Signing Kernel"
		./bump.py image-new.img
		echo "Moving Kernel to output folder"
		mv ./image-new_bumped.img ../Output/${device}/rusty/boot.img

	echo "finding and placing modules"

		rm -f ./Output/${device}/rusty/system/lib/modules/*
		find -name "*.ko" -exec cp -f '{}'  ./Output//${device}rusty/system/lib/modules/ \;

	echo "Copying image to root of unzipped directory renaming it boot."
	cd ../
	cd ./Output/${device}/rusty

	echo "Creating flashable zip."

	zip -r RustyKernel_${device}-$(date +%F).zip . -x ".*"

    echo "Moving zipped file to output folder."

    mv RustyKernel_${device}-$(date +%F).zip  ../
fi
