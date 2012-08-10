#!/bin/bash
#
# AutoMod
#
# MAD Industries, Team EOS
#
# -------------------------
# Credits
# -------------------------
# Brut.all for apktool which is used in automod and is a constant necessity for any theme dev
# Daneshm90 for writing apk manager which was an inspiration for this tool
# JF for smali/baksmali
#
# A special thanks to my beta testers Nusince and "Super Human Tester: Xhinde". (AutoTheme)
# Thanks to invisiblek for updated linux binaries. (AutoMod)
#
version=1.3
themeversion=0.4
toolversion=0.2
#
# ------------------------------------------
# Changelog
# ------------------------------------------
# 0.1: Initial Release (OSX)
# 0.2: Added Linux support, color coding, reorganized root folder, bugfixes (Thanks Nusince!)
# 0.3: Bug fixes on OSX, overrode 'echo' command with platform agnostic 'say'
# 0.4: Basic error handling added (requires further improvement/elegance)
# 0.5: Added automatic update check from server
# 0.6: Cleaned up code, Added extended update functionality, Reverted 'echo' override
# 0.7: Cleaned up code, Began modifications to create more advanced theme engine (upgraded theme version to 0.2)
# 0.8: Extended theme engine to theme any app (upgraded theme version to 0.3), Renamed to "Auto-Theme"
# 0.9: Added firt-run code so script is redistributable without content 
# 1.0: Private Beta, Theme engine now accepts .thm packages made for this script
# 1.1: Extended linux support, Bugfixes (Thanks Xhinde!)
# 1.2: Rebranded to automod with the intent of supporting more than just themes in the future
# 1.3: Added support for creating update.zip files from mods
#
#
# ------------------------------------------
# To-Do
# ------------------------------------------
#  Add "safe" mod package support (device-specific packages)
#  Add multi-device backups
#  Add ability to merge mods together into new package
#  Extend update.zip generation (dynamic scripts)
#  Add ability to package backup as a return-to-stock update.zip
#  Add jar mod support
#  Add support for ROM zip files (modding without a device)

platform='unknown'
unamestr=$(uname)
kclr='tput sgr0'
echo ""
if [ "$unamestr" == "Linux" ]; then
	platform="linux"
	PATH=./Tools/linux:$PATH
	RED='\e[1;31m'
	ORANGE='\e[0;33m'
	YELLOW='\e[1;33m'
	GREEN='\e[1;32m'
	BLUE='\e[1;36m'
	PURPLE='\e[1;35m'
	WHITE='\e[0;37m'
	BWHITE='\e[1;37m'
	download () { 
		wget -O $1 $2
	}
	echo -e $YELLOW"---------------------------------------------------------------------------------------------"
	echo "/// Welcome to AutoMod Version: $version by MAD Industries ///"
	echo "---------------------------------------------------------------------------------------------"; $kclr;
	echo "Operating System Detected: Linux     |"
elif [ "$unamestr" == "Darwin" ]; then
	platform="osx"
	PATH=./Tools/osx:$PATH
	RED='\033[1;31m'
	ORANGE='\033[0;33m'
	YELLOW='\033[1;33m'
	GREEN='\033[1;32m'
	BLUE='\033[1;36m'
	PURPLE='\033[1;35m'
	WHITE='\033[0;37m'
	BWHITE='\033[1;37m'
	download () {
		curl -o $1 $2
	}
	echo -e $YELLOW"---------------------------------------------------------------------------------------------"
	echo "/// Welcome to AutoMod version: $version by MAD Industries ///"
	echo "---------------------------------------------------------------------------------------------"; $kclr;
	echo "Operating System Detected: Mac OSX   |"
else
	echo "Operating System Not Recognized. Please report bug along with your OS Version."
fi
echo "------------------------------------/"
echo -e $RED""

error () {
	case "$1" in
		backup_stock) echo -e $RED"Error encountered while performing stock backup."; $kclr; exit 0 ;;
		backup) echo -e $RED"Error encountered while performing backup."; $kclr; exit 0 ;;
		pull_ui) echo -e $RED"Error while pulling files. Make sure your device is connected."; $kclr; pressanykey; main_menu ;;
		decompile) echo -e $RED"Error encountered while decompiling files."; $kclr; exit 0 ;;
		replace) echo -e $RED"Error encountered while replacing files."; $kclr; exit 0 ;;
		recompile) echo -e $RED"Error encountered while recompiling files."; $kclr; exit 0 ;;
		push) echo -e $RED"Error encountered during push operation."; $kclr; exit 0 ;;
		reboot) echo -e $RED"Error encountered while attempting to reboot your device."; $kclr; exit 0 ;;
		restore) echo -e $RED"Error encountered while restoring files to device."; $kclr; exit 0 ;;
		"") echo -e $RED"Unknown error occured."; $kclr; exit 0 ;;
		*) echo -e $RED"Error ""'$1'"" occured during merge."; $kclr; exit 0 ;;
	esac
}

start_func () {
	if [ ! -d ./Tools ]; then
		echo -e $WHITE"It appears this is the first time you are running AutoMod.";  $kclr;
		echo -e "Press enter to download the required tools package or 'q' to quit..";
		read INPUT
		case $INPUT in
			[qQ]) echo -e "Quitting.."; exit 0 ;;
			*) setenv ;;
		esac
	fi
    if [[ -f ./Tools/$platform/curl ]]; then
        update_check
    fi
	if [ -f ./framework-res.apk ]; then
		rm -rf "./framework-res.apk"
	fi
	if [ -f ./SystemUI.apk ]; then
		rm -rf "./SystemUI.apk"
	fi
	if [ ! -d ./Backup ]; then
		echo -e $WHITE"It appears you do not yet have a baseline backup created.";  $kclr;
		backup_stock
	fi
	main_menu
}

kill_DStore () {
	if [[ $platform == "osx" ]]; then
		find . -name '*.DS_Store' -type f -delete
	fi
}

setenv () {
	echo -e "Preparing AutoMod environment.."
    if [ ! -d ./Tools ]; then
        echo -e "Downloading tools.."
        download Tools.zip http://cloud.github.com/downloads/MADindustries/automod/Tools.zip
        echo -e "Extracting tools.."
        unzip -o ./Tools.zip
        rm -rf "./__MACOSX"
        rm ./Tools.zip
    fi
    PATH=./Tools/$platform:$PATH
#	if [ ! -d ./Themes ]; then
#		echo -e "Downloading themes.."
#		download Themes.zip http://cloud.github.com/downloads/MADindustries/automod/Themes.zip
#		echo -e "Extracting themes.."
#		./Tools/$platform/7za x -y ./Themes.zip
#		rm -rf "./__MACOSX"
#		rm ./Themes.zip
#	fi
	kill_DStore
	echo -e "Setup complete. Checking for backups.."
}

wait () {
	read -n 1 -s
	echo -e ""
}

pressanykey () {
	echo -e "Press any key to continue.."
    read -n 1 -s
	echo -e ""
}

update_check () {
	echo -e "Checking for script updates.."
	web=$(curl -s https://raw.github.com/MADindustries/automod/master/version/script)
	if [[ $version == $web ]]; then
		echo -e "You are running the most current version of AutoMod."
	elif [[ $version < $web ]]; then
		echo -e "An update for AutoMod is available. Would you like to download it now?"
		printf "Type 'y' to update now or 'n' to continue without updating:"
		read INPUT
		case $INPUT in
			[yY]) update "script" ;;
			[nN]) ;;
			*) echo -e "Not a valid entry."; update_check ;;
		esac
	elif [[ $version > $web ]]; then
		echo -e "Why are you using a newer version than MAD Industries? :P"
	fi
#	echo -e "Checking for theme updates.."
#	theme=$(curl -s https://raw.github.com/MADindustries/automod/master/version/theme)
#	if [[ $themeversion == $theme ]]; then
#		echo -e "You have the latest themes already installed."
#	elif [[ $themeversion < $theme ]]; then
#		echo -e "There are new or updated themes available for AutoMod. Would you like to download them now?"
#		printf "Type 'y' to update now or 'n' to continue without updating:"
#		read INPUT
#		case $INPUT in
#			[yY]) update "themes" ;;
#			[nN]) ;;
#			*) echo -e "Not a valid entry."; update_check ;;
#		esac
#	elif [[ $themeversion > $theme ]]; then
#		echo -e "Why are you using newer themes than MAD Industries? :P"
#	fi
    echo -e "Checking for tool updates.."
    tool=$(curl -s https://raw.github.com/MADindustries/automod/master/version/tools)
    if [[ $toolversion == $tool ]]; then
        echo -e "You have the latest tools already installed."
    elif [[ $toolversion < $tool ]]; then
        echo -e "There are new or updated tools available for AutoMod. Would you like to download them now?"
        printf "Type 'y' to update now or 'n' to continue without updating:"
    read INPUT
    case $INPUT in
        [yY]) update "tools" ;;
        [nN]) ;;
        *) echo -e "Not a valid entry."; update_check ;;
    esac
    elif [[ $toolversion > $tool ]]; then
        echo -e "Why are you using newer tools than MAD Industries? :P"
    fi
}

update () {
	if [[ $1 == "script" ]]; then
		echo -e "Updating AutoMod.."
		cp ./automod.sh ./automod.bak
		download automod.sh https://raw.github.com/MADindustries/automod/master/automod.sh
		echo -e "Update Complete. Restarting script.."
		bash automod.sh
		exit 0
	elif [[ $1 == "themes" ]]; then
#		echo -e "Downloading themes.."
#		download Themes.zip http://cloud.github.com/downloads/MADindustries/automod/Themes.zip
#		echo -e "Extracting themes.."
#		./Tools/$platform/7za x -y ./Themes.zip
#		rm -rf "./__MACOSX"
#		echo -e "..Done"
		kill_DStore
		main_menu
    elif [[ $1 == "tools" ]]; then
        echo -e "Downloading tools.."
        download Tools.zip http://cloud.github.com/downloads/MADindustries/automod/Tools.zip
		if [[ -f Tools.zip ]]; then
			echo -e "Removing old tools.."
			cp ./Tools/$platform/7za ./7za
			rm -rf ./Tools
		fi
        echo -e "Extracting tools.."
        ./7za x -y ./Tools.zip
        rm -rf "./__MACOSX"
		echo -e "Cleaning up.."
		rm -rf 7za
		rm -rf Tools.zip
        echo -e "..Done"
		kill_DStore
        main_menu
	fi
}

backup_stock () {
	echo -e $WHITE"I will now attempt to create a preliminary backup of your basic UI."
	printf "Please make sure your device is connected and press any key to continue.."; $kclr;
	wait
	if [[ -f ./Backup/framework-res.apk ]]; then
		rm ./Backup/framework-res.apk
	fi
	if [[ -f ./Backup/SystemUI.apk ]]; then
		rm ./Backup/SystemUI.apk
	fi
	adb pull /system/framework/framework-res.apk ./Backup/framework-res.bak
	adb pull /system/app/SystemUI.apk ./Backup/SystemUI.bak
	main_menu
	if [ $? != 0 ]; then
		error "backup_stock"
	fi
}

main_menu () {
	echo -e ""
	echo -e $WHITE"This script will apply a mod to any device currently connected over adb."
	echo -e "Please select a option below. (note: "$RED"Your device may reboot"$WHITE" upon completion)"; $kclr;
	echo -e ""
	echo -e ""
	echo -e " 1) "$WHITE"Apply a mod directly to a device (will reboot, may not be supported by your device)"; $kclr;
	echo -e " 2) "$WHITE"Create a flashable update.zip from a mod (device specific)"; $kclr;
	echo -e " 3) "$WHITE"Install a new mod package into AutoMod"; $kclr;
	echo -e " 4) "$WHITE"Restore from a previous backup"; $kclr;
	echo -e " 5) "$WHITE"Perform stock backup (use this if you have flashed a new ROM since last use)"; $kclr;
	echo -e " 6) "$WHITE"Check for updates"; $kclr;
	echo -e " 7) "$WHITE"Quit"; $kclr;
	echo -e ""
	echo -e $YELLOW"--------------------------------------------------------------------------------------------"; $kclr;
	echo -e ""
	printf "Please choose an option:";
	read INPUT
	case $INPUT in
		1) list_mods flash ;;
		2) list_mods zip ;;
		3) install_mod ;;
		4) restore_check ;;
		5) backup_stock ;;
		6) update_check; main_menu ;;
		7) exit 0 ;;
		packagetools) package tools ;;
		packagemods) package mods ;;
		packagemod*) package mod ${INPUT#"packagemod "} ;;
		forceupdate*) update ${INPUT#"forceupdate "} ;;
		[qQ]) exit 0 ;;
		*) echo -e "Not a valid entry."; pressanykey; main_menu ;;
	esac
}

package () {
	kill_DStore
	if [[ $1 == "tools" ]]; then
		./Tools/$platform/7za a -tzip Tools.zip Tools
	elif [[ $1 == "mods" ]]; then
		./Tools/$platform/7za a -tzip Mods.zip Mods
	elif [[ $1 == "mod" ]]; then
		./Tools/$platform/7za a -tzip $2.mod ./Mods/$2
	fi
	main_menu
}

install_mod () {
	mkdir ./Install
	cd ./Install
	echo -e "A folder has been created in the current directory called 'Install'."
	echo -e "Please place any .mod packages inside that folder for installation and press any key to continue."
	pressanykey
	for pack in ./*
	do
		if [[ -f $pack ]]; then
			name=${pack#"./"}
			name=${name%".mod"}
			echo -e "Installing mod '$name'."
			../Tools/$platform/7za x -y $pack
			if [[ -d ./__MACOSX ]]; then
				rm -rf ./__MACOSX
				kill_DStore
			fi
			mv ./$name ../Mods/$name
			rm $pack
			echo -e "Install complete."
		else
			name=${pack#"./"}
			echo -e "'$name' is not a compatible mod package."
		fi
	done
	cd ../
	rm -rf ./Install
	echo -e "Returning to main menu.."; main_menu;
}

list_mods () {
	echo -e $YELLOW""
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e "/// Available Mods ///"
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e ""; $kclr;
	count=1
	for folder in ./Mods/*
	do
		mod=${folder#"./Mods/"}
		modlist[$count]=$mod
		echo -e "	$count) $mod"
		(( count++ ))
	done
	echo -e ""
	printf "Please choose a mod or type 'q' to return to main menu:";
	read INPUT
	case $INPUT in
		[qQ]) main_menu ;;
		*) merge ${modlist[$INPUT]} $1;;
	esac
}

parse () {
	for folder in ./Mods/$1/*
	do
		if [[ ${folder#"./Mods/$1/"} == "system" ]]; then
			for sub in $folder/*
			do
			type=${sub#"$folder/"}
				if [[ $type == "framework" ]]; then
					if [[ -d "$sub/framework-res" ]]; then
						framework=true
					fi
				elif [[ $type == "app" ]]; then
					count=0
					for app in $sub/*
					do
						appname=${app#"$sub/"}
						sysapps[$count]=$appname
						(( count++ ))
					done
				fi
			done
		elif [[ ${folder#"./Mods/$1/"} == "data" ]]; then
			count=0
			for sub in $folder/app/*
			do
				appname=${sub#"$folder/app/"}
				userapps[$count]=$appname
				(( count++ ))
			done
		fi
	done
}

backup_check () {
	echo -e $WHITE"You are about to modify your device. [$1]."
	echo -e "This will overwrite any apks referenced within the '$1' folder."
	echo -e ""
	echo -e $RED"Would you like to create a full backup of all referenced apps before modifying?"
	printf "(note: This will overwrite any previous backups) [Y/N]:"; $kclr;
	read INPUT
	case $INPUT in
		[yY])backup ;;
		[nN])pull_ui ;;
			*) echo -e "Not a valid entry."; pressanykey; backup_check ;;
	esac
}

backup () {
	pull_ui
	./Tools/$platform/7za a -mx=9 ./Backup/Backup Pulled
	if [ $? != 0 ]; then
		error "backup"
	fi
}

pull_ui () {
	echo -e "Waiting for device.."
	adb wait-for-device
	echo -e "Pulling files.."
	#Note: we always pull framework because apktool must install it to decompile SystemUI.apk
	adb pull /system/framework/framework-res.apk ./Pulled/system/framework/framework-res.apk
	for app in ${sysapps[@]}
	do
		adb pull /system/app/"$app".apk ./Pulled/system/app/"$app".apk
	done
	for app in ${userapps[@]}
	do
		adb pull /data/app/"$app".apk ./Pulled/data/app/"$app".apk
	done
	if [ $? != 0 ]; then
		error "pull_ui"
	fi
	echo -e "..Done."
}

decompile () {
	cd ./Tools/$platform
	PATH=./:$PATH
	echo -e "Installing framework into apktool.."
	java -jar apktool.jar if ../../Pulled/system/framework/framework-res.apk
	if [[ $framework == true ]]; then
		echo -e "Decompiling framework.."
		java -jar  apktool.jar d "../../Pulled/system/framework/framework-res.apk" "../../Decompiled/system/framework/framework-res"
	fi
	for app in ${sysapps[@]}
	do
		echo -e "Decompiling $app.."
		java -jar  apktool.jar d "../../Pulled/system/app/$app.apk" "../../Decompiled/system/app/$app"
	done
	for app in ${userapps[@]}
	do
		echo -e "Decompiling $app.."
		java -jar  apktool.jar d "../../Pulled/data/app/$app.apk" "../../Decompiled/data/app/$app"
	done
	cd ../../
	kill_DStore
	if [ $? != 0 ]; then
		error "decompile"
	fi
}

replace () {
	echo -e "Begin modification routine.."
	if [[ $framework == true ]]; then
		echo -e "Modding framework.."
		cp -r ./Mods/$1/system/framework/framework-res/* ./Decompiled/system/framework/framework-res/
	fi
	for app in ${sysapps[@]}
	do
		echo -e "Modding $app.."
		cp -r ./Mods/$1/system/app/$app/* ./Decompiled/system/app/$app/
	done
	for app in ${userapps[@]}
	do
		echo -e "Modding $app.."
		cp -r ./Mods/$1/data/app/$app/* ./Decompiled/data/app/$app/
	done
	kill_DStore
	echo -e "..Done"
	if [ $? != 0 ]; then
		error "replace"
	fi
}

recompile () {
	kill_DStore
	cd ./Tools/$platform
	if [[ $framework == true ]]; then
		echo -e "Recompiling framework.. (may take a while)"
		java -jar apktool.jar b ../../Decompiled/system/framework/framework-res ../../Recompiled/system/framework/framework-res.apk
		7za x -o./temp/framework-res ../../Pulled/system/framework/framework-res.apk META-INF -r -y
		7za x -o./temp/framework-res ../../Pulled/system/framework/framework-res.apk AndroidManifest.xml -y
		7za a -tzip ../../Recompiled/system/framework/framework-res.apk ./temp/framework-res/* -mx9 -r -y
		rm -rf ./temp/framework-res
	fi
	for app in ${sysapps[@]}
	do
		echo -e "Recompiling $app.."
		java -jar apktool.jar b ../../Decompiled/system/app/$app ../../Recompiled/system/app/$app.apk
		7za x -o./temp/$app ../../Pulled/system/app/$app.apk META-INF -r -y
		7za x -o./temp/$app ../../Pulled/system/app/$app.apk AndroidManifest.xml -y
		7za a -tzip ../../Recompiled/system/app/$app.apk ./temp/$app/* -mx9 -r -y
		rm -rf ./temp/$app
	done
	for app in ${userapps[@]}
	do
		echo -e "Recompiling $app.."
		java -jar apktool.jar b ../../Decompiled/data/app/$app ../../Recompiled/data/app/unsigned-$app.apk
		java -jar signapk.jar -w testkey.x509.pem testkey.pk8 ../../Recompiled/data/app/unsigned-$app.apk ../../Recompiled/data/app/$app.apk
		rm ../../Recompiled/data/app/unsigned-$app.apk
	done
	rm -rf ./temp
	cd ../../
	if [ $? != 0 ]; then
		error "recompile"
	fi
	rm -rf ./Decompiled
	rm -rf ./Pulled
}

push () {
	echo -e "Waiting for device"
	adb wait-for-device
	adb remount
	if [[ $framework == true ]]; then
		echo -e "Pushing framework.."
		adb push ./Recompiled/system/framework/framework-res.apk /system/framework/framework-res.apk
	fi
	for app in ${sysapps[@]}
	do
		echo -e "Pushing $app.."
		adb push ./Recompiled/system/app/$app.apk /system/app/$app.apk
	done
	for app in ${userapps[@]}
	do
		echo -e "Installing $app.."
		adb install -r ./Recompiled/data/app/$app.apk
	done
	if [ $? != 0 ]; then
		error "push"
	else
		echo -e "Rebooting device.."
		adb reboot
	fi
}

create_zip () {
	echo -e "Adding script..."
	mkdir ./Recompiled/META-INF
	cp -r ./Tools/META-INF/* ./Recompiled/META-INF/
	kill_DStore
	cd ./Tools/$platform
	echo -e "Zipping it all up..."
	7za a -tzip unsigned.zip ../../Recompiled/*
	echo -e "Signing & Sealing..."
	java -jar signapk.jar testkey.x509.pem testkey.pk8 unsigned.zip ../../test.zip
	rm -rf ./unsigned.zip
	cd ../../
	echo -e "I'm Yours!"
}

restore_check () {
	if [ -d ./Backup ]; then
		if [ -f ./Backup/Backup.7z ]; then
			echo -e $WHITE"Choose a backup to restore from:"
			echo -e "	1) Basic Backup (from first run, likely stock, only includes framework & SystemUI)"
			echo -e "	2) Full Backup (from most recent use, includes all files modified by this tool)"
			echo -e "	3) Cancel restore"; $kclr;
			printf ":"
			read INPUT
			case $INPUT in
				1) restore bak ;;
				2) restore full ;;
				3) main_menu ;;
				*) main_menu ;;
			esac
		elif [ -f ./Backup/framework-res.bak ]; then
			echo -e $WHITE"Restoring from basic backup. Are you sure you want to do this?"
			echo -e "Press any key to continue or 'q' to cancel.."; $kclr;
			read INPUT
			case $INPUT in
				[qQ]) main_menu ;;
				*) restore bak ;;
			esac
		else
			echo -e $WHITE"No backup data found. Press any key to continue.." $kclr;
			wait
		fi
	fi
}

restore () {
	echo -e "Waiting for device"
	adb wait-for-device
	echo -e $RED"Restoring.."; $kclr;
	adb remount
	if [[ $1 == bak ]]; then
		adb push ./Backup/framework-res.bak /system/framework/framework-res.apk
		adb push ./Backup/SystemUI.bak /system/app/SystemUI.apk
	elif [[ $1 == full ]]; then
		cd ./Backup
		kill_DStore
		if [[ -d ./Pulled ]]; then
			rm -rf ./Pulled
		fi
		../Tools/$platform/7za x -y ./Backup.7z
		for folder in ./Pulled/*
		do
			type=${folder#"./Pulled/"}
			if [[ $type == "system" ]]; then
				for sub in $folder/*
				do
				type=${sub#"$folder/"}
					if [[ $type == "framework" ]]; then
						if [[ -f "$sub/framework-res.apk" ]]; then
							echo -e $WHITE"Restoring framework. If you have flashed a new rom or new version since this backup was made, choose 'N'o."
							echo -e "Press 'Y' to restore framework or 'N' to skip.."; $kclr;
							read INPUT
							case $INPUT in
								[nN]) ;;
								[yY]) ../Tools/$platform/adb push $sub/framework-res.apk /system/framework/framework-res.apk ;;
								*) echo -e "Not a valid entry. Returning to restore menu.."; restore_check ;;
							esac
						fi
					elif [[ $type == "app" ]]; then
						for app in $sub/*
						do
							appname=${app#"$sub/"}
							if [[ $appname == "SystemUI.apk" ]]; then
								echo -e $WHITE"Restoring SystemUI. If you have flashed a new rom or new version since this backup was made, choose 'N'o."
								echo -e "Press 'Y' to restore SystemUI or 'N' to skip.."; $kclr;
								read INPUT
								case $INPUT in
									[nN]) ;;
									[yY]) ../Tools/$platform/adb push $app /system/app/$appname ;;
									*) echo -e "Not a valid entry. Returning to restore menu.."; restore_check ;;
								esac
							else
								../Tools/$platform/adb push $app /system/app/$appname
							fi
						done
					fi
				done
			elif [[ $type == "data" ]]; then
				for app in $folder/app/*
				do
					appname=${sub#"$folder/app/"}
					../Tools/$platform/adb install -r $app
				done
			fi
		done
		rm -rf ./Pulled
		cd ../
	fi
	echo -e $RED"Rebooting device.."; $kclr;
	adb reboot
	echo -e $WHITE"Restore Complete."; $kclr;
	if [ $? != 0 ]; then
		error "restore"
	fi
}

merge () {
	parse $1
	backup_check $1
	decompile
	replace $1
	recompile
	if [[ $2 == "flash" ]]; then
		push
	elif [[ $2 == "zip" ]]; then
		create_zip $1
	fi
	rm -rf ./Recompiled
	exit 0
}

start_func

if [ $? != 0 ]; then
	echo -e "Unknown error occured."
	echo -e "Please copy output of script to a file and report to MAD Industries."
	exit 1
fi