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
version=1.6
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
# 1.4: Extended backup function with flashable backups
# 1.5: Added support for ROM Install files (now possible to mod without a device), cleaned LOTS of code :)
# 1.6: Dynamic updater-script generation with personalized author & completion message (First AutoMod BETA Release)
#
#
# ------------------------------------------
#  To-Do (in no particular order)
# ------------------------------------------
#  Add "safe" mod package support (device-specific packages)
#  Add overwrite handling for mod/rom installs
#  Add multi-device backups
#  Add ability to merge mods together into new package
#  Add jar mod support
#  Add developer mode/options
#  Add apk/jar diff function
#  Add cygwin support (in testing)
#  Add sub-mod function (for batch processing multiple versions of a single mod)

platform='unknown'
unamestr=$(uname)
if [[ ${unamestr:0:6} == "CYGWIN" ]]; then
	unamestr="Linux"
fi
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
	gettext () {
		wget -qO- $1
	}
	if [[ $1 == '' ]]; then
		scripted="false"
		echo -e $YELLOW"---------------------------------------------------------------------------------------------"
		echo "/// Welcome to AutoMod Version: $version by MAD Industries ///"
		echo "---------------------------------------------------------------------------------------------"; $kclr;
		echo "Operating System Detected: Linux     |"
		echo "------------------------------------/"
		echo -e $RED""
	else
		scripted="true"
	fi
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
	gettext () {
		curl -s $1
	}
	if [[ $1 == '' ]]; then
		scripted="false"
		echo -e $YELLOW"---------------------------------------------------------------------------------------------"
		echo "/// Welcome to AutoMod version: $version by MAD Industries ///"
		echo "---------------------------------------------------------------------------------------------"; $kclr;
		echo "Operating System Detected: Mac OSX   |"
		echo "------------------------------------/"
		echo -e $RED""
	else
		scripted="true"
	fi
else
	echo "Operating System Not Recognized. Please report bug along with your OS Version."
fi

error () {
	case "$1" in
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
    update check
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

update () {
	if [[ $1 == "check" ]]; then
		echo -e "Checking for script updates.."
		script=$(gettext https://raw.github.com/MADindustries/automod/master/version/script)
		if [[ $version == $script ]]; then
			echo -e "You are running the most current version ($version) of AutoMod."
		elif [[ $version < $script ]]; then
			echo -e "An update for AutoMod is available. (version $script) Would you like to download it now?"
			printf "Type 'y' to update now or 'n' to continue without updating:"
			read INPUT
			case $INPUT in
				[yY]) update "script" ;;
				[nN]) ;;
				*) echo -e "Not a valid entry."; update check ;;
			esac
		elif [[ $version > $script ]]; then
			echo -e "Why are you using a newer version ($version) than MAD Industries? :P"
		fi
	    echo -e "Checking for tool updates.."
	    tool=$(gettext https://raw.github.com/MADindustries/automod/master/version/tools)
	    if [[ $toolversion == $tool ]]; then
	        echo -e "You have the latest tools ($toolversion) already installed."
	    elif [[ $toolversion < $tool ]]; then
	        echo -e "There are new or updated tools available for AutoMod. (version $tool) Would you like to download them now?"
	        printf "Type 'y' to update now or 'n' to continue without updating:"
	    read INPUT
	    case $INPUT in
	        [yY]) update "tools" ;;
	        [nN]) ;;
	        *) echo -e "Not a valid entry."; update check ;;
	    esac
	    elif [[ $toolversion > $tool ]]; then
	        echo -e "Why are you using newer tools ($toolversion) than MAD Industries? :P"
	    fi
	elif [[ $1 == "script" ]]; then
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
	fi
	main_menu
}

main_menu () {
	echo -e ""
	echo -e $WHITE"This script will apply a mod to any device currently connected over adb."
	echo -e "Please select a option below. (note: "$RED"Your device may reboot"$WHITE" upon completion)"; $kclr;
	echo -e ""
	echo -e ""
	echo -e " 1) "$WHITE"Apply a mod directly to a device (will reboot, not supported by VZW GS3)"; $kclr;
	echo -e " 2) "$WHITE"Create a flashable update.zip from a mod (device specific)"; $kclr;
	echo -e " 3) "$WHITE"Use a ROM Install zip + mod to create a flashable zip for another ROM/device"; $kclr;
	echo -e " 4) "$WHITE"Install a new mod package into AutoMod"; $kclr;
	echo -e " 5) "$WHITE"Install a new ROM file into AutoMod"; $kclr;
	echo -e " 6) "$WHITE"Restore from a previous backup"; $kclr;
	echo -e " 7) "$WHITE"Perform stock backup (use this if you have flashed a new ROM since last use)"; $kclr;
	echo -e " 8) "$WHITE"Check for updates"; $kclr;
	echo -e " 9) "$WHITE"Quit"; $kclr;
	echo -e " 10) "$RED"BETA TESTING ONLY: Force update from latest github commit"; $kclr;
	echo -e " 11) "$WHITE"Developer Menu"; $kclr;
	echo -e ""
	echo -e $YELLOW"--------------------------------------------------------------------------------------------"; $kclr;
	echo -e ""
	printf "Please choose an option:";
	read INPUT
	case $INPUT in
		1) list_mods flashdevice ;;
		2) list_mods zipdevice ;;
		3) list_roms ;;
		4) install_mod ;;
		5) install_rom ;;
		6) restore_check ;;
		7) backup stckdevice ;;
		8) update check; main_menu ;;
		9) exit 0 ;;
		10) update script ;;
		11) dev_menu ;;
		packagetools) package tools ;;
		packagemods) package mods ;;
		packagemod*) package mod ${INPUT#"packagemod "} ;;
		forceupdate*) update ${INPUT#"forceupdate "} ;;
		execfunc*) ${INPUT#"execfunc "} ;;
		[qQ]) exit 0 ;;
		*) echo -e "Not a valid entry."; pressanykey; main_menu ;;
	esac
}

dev_menu () {
	echo -e $YELLOW""
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e "/// Developer Menu ///"
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e ""; $kclr;
	echo -e ""
	echo -e " 1) "$WHITE"Package a mod into a redistributable .mod file"; $kclr;
	echo -e " 2) "$WHITE"Package all mods into a single file for backup"; $kclr;
	echo -e " 3) "$WHITE"Return to main menu"; $kclr;
	echo -e ""
	echo -e $YELLOW"--------------------------------------------------------------------------------------------"; $kclr;
	echo -e ""
	printf "Please choose an option:";
	read INPUT
	case $INPUT in
		1) list_mods packagemod ;;
		2) package mods ;;
		3) main_menu ;;
		[qQ]) exit 0 ;;
		*) echo -e "Not a valid entry."; pressanykey; dev_menu ;;
	esac
}

package () {
	kill_DStore
	if [[ $1 == "tools" ]]; then
		./Tools/$platform/7za a -tzip Tools.zip Tools
	elif [[ $1 == "mods" ]]; then
		printf "Please type a name you would like to use for the backup and press enter:"; $kclr;
		read INPUT
		./Tools/$platform/7za a -tzip $INPUT.mod ./Mods/*
		echo "Backup '$INPUT' has been created."
	elif [[ $1 == "mod" ]]; then
		./Tools/$platform/7za a -tzip $2.mod ./Mods/$2
		echo "Modfile '$2' has been created."
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
			if [[ ! -d ../Mods ]]; then
				mkdir ../Mods
			fi
			../Tools/$platform/7za x -y -o../Mods $pack
			if [[ -d ../__MACOSX ]]; then
				rm -rf ../__MACOSX
				kill_DStore
			fi
			#mv ./$name ../Mods/$name
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

install_rom () {
	mkdir ./Install
	echo -e "A folder has been created in the current directory called 'Install'."
	echo -e "Please place any ROM install zips inside that folder for installation and press any key to continue."
	pressanykey
	for pack in ./Install/*
	do
		if [[ -f $pack ]]; then
			name=${pack#"./Install/"}
			echo $pack $name
			name=${name%".zip"}
			echo -e "Installing ROM '$name'."
			if [[ ! -d ./ROMs ]]; then
				mkdir ./ROMs
			fi
			mkdir -p ./ROMs/$name
			./Tools/$platform/7za x -y -o./ROMs/$name $pack
			if [[ -d ./ROMs/$name/__MACOSX ]]; then
				rm -rf ./ROMs/$name/__MACOSX
				kill_DStore
			fi
			rm $pack
			echo -e "Install complete."
		else
			echo -e "'$name' is not a compatible ROM file."
		fi
	done
	rm -rf ./Install
	echo -e "Returning to main menu.."; main_menu;
}

list_mods () {
	echo -e $YELLOW""
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e "/// Available Mods ///"
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e "// Modifying: $2"
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
		*) [[ $1 == "packagemod" ]] && package mod ${modlist[$INPUT]} || merge $1 ${modlist[$INPUT]} $2 ;;
	esac
}

list_roms () {
	echo -e $YELLOW""
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e "/// Available ROMs ///"
	echo -e "--------------------------------------------------------------------------------------------"
	echo -e ""; $kclr;
	count=1
	for folder in ./ROMs/*
	do
		rom=${folder#"./ROMs/"}
		romlist[$count]=$rom
		echo -e "	$count) $rom"
		(( count++ ))
	done
	echo -e ""
	printf "Please choose a ROM or type 'q' to return to main menu:";
	read INPUT
	case $INPUT in
		[qQ]) main_menu ;;
		*) list_mods ziprom ${romlist[$INPUT]} ;;
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

backup () {
	if [[ $1 == "check" ]]; then
		echo -e $WHITE"You are about to modify your device. [$2]."
		echo -e "This will overwrite any apks referenced within the '$2' folder."
		echo -e ""
		echo -e $RED"Would you like to create a full backup of all referenced apps before modifying?"
		printf "(note: This will overwrite any previous backups) [Y/N]:"; $kclr;
		read INPUT
		case $INPUT in
			[yY])backup $2 ;;
			[nN])pull_ui ;;
				*) echo -e "Not a valid entry."; pressanykey; backup check $2;;
		esac
	else
		pull_ui
		create_zip backup $1
		echo -e "This backup may be flashed with any current custom recovery to return to your device to its previous state."
		if [ $? != 0 ]; then
			error "backup"
		fi
	fi
}

pull_ui () {
	echo -e "Waiting for device.."
	adb wait-for-device
	echo -e "Pulling files from device.."
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

pull_rom () {
	echo -e "Pulling files from ROM: $1.."
	#Note: we always pull framework because apktool must install it to decompile SystemUI.apk
	mkdir -p ./Pulled/system/framework
	cp -p ./ROMs/$1/system/framework/framework-res.apk ./Pulled/system/framework/framework-res.apk
	for app in ${sysapps[@]}
	do
		if [[ -f ./ROMs/$1/system/app/"$app".apk ]]; then
			if [[ ! -d ./Pulled/system/app ]]; then
				mkdir -p ./Pulled/system/app
			fi
			cp -p ./ROMs/$1/system/app/"$app".apk ./Pulled/system/app/"$app".apk
		else
			echo -e "System app $app not found inside ROM file. Skipping.."
		fi
	done
	if [[ -d ./ROMs/$1/data ]]; then
		for app in ${userapps[@]}
		do
			if [[ -f ./ROMs/$1/data/app/"$app".apk ]]; then
				if [[ ! -d ./Pulled/data/app ]]; then
					mkdir -p ./Pulled/data/app
				fi
				cp -p ./ROMs/$1/data/app/"$app".apk ./Pulled/data/app/"$app".apk
			else
				echo -e "User app $app not found inside ROM file. Skipping.."
			fi
		done
	else
		echo -e "ROM does not contain any user apps. Skipping.."
	fi
	if [ $? != 0 ]; then
		error "pull_rom"
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

create_script () {
	echo 'ui_print("---------------------------------");' > $4/updater-script
	echo 'ui_print("Mod: '"$2"'");' >> $4/updater-script
	echo 'ui_print("ROM: '"$3"'");' >> $4/updater-script
	if [[ $1 == "backup" ]]; then
		echo 'ui_print("Author: AutoMod Automatic Backup");' >> $4/updater-script
	elif [[ $1 == "mod" ]]; then
		printf "Please type an author name you would like shown while flashing:"; $kclr;
		read INPUT
		echo 'ui_print("Author: '"$INPUT"'");' >> $4/updater-script
	fi
	echo 'ui_print("Generated by AutoMod. BETA!!");' >> $4/updater-script
	echo 'ui_print("---------------------------------");' >> $4/updater-script
	echo '' >> $4/updater-script
	if [[ $5 == system ]]; then
		echo 'ui_print("  Mounting /system");' >> $4/updater-script
		echo 'run_program("/sbin/busybox", "mount", "/system");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Extracting to /system");' >> $4/updater-script
		echo 'package_extract_dir("system", "/system");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Unmounting..");' >> $4/updater-script
		echo 'unmount("/system");' >> $4/updater-script
	elif [[ $5 == data ]]; then
		echo 'ui_print("  Mounting /data");' >> $4/updater-script
		echo 'run_program("/sbin/busybox", "mount", "/data");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Extracting to /data");' >> $4/updater-script
		echo 'package_extract_dir("data", "/data");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Unmounting..");' >> $4/updater-script
		echo 'unmount("/data");' >> $4/updater-script
	elif [[ $5 == all ]]; then
		echo 'ui_print("  Mounting /system");' >> $4/updater-script
		echo 'run_program("/sbin/busybox", "mount", "/system");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Mounting /data");' >> $4/updater-script
		echo 'run_program("/sbin/busybox", "mount", "/data");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Extracting to /system");' >> $4/updater-script
		echo 'package_extract_dir("system", "/system");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Extracting to /data");' >> $4/updater-script
		echo 'package_extract_dir("data", "/data");' >> $4/updater-script
		echo '' >> $4/updater-script
		echo 'ui_print("  Unmounting..");' >> $4/updater-script
		echo 'unmount("/system");' >> $4/updater-script
		echo 'unmount("/data");' >> $4/updater-script
	fi
	echo '' >> $4/updater-script
	echo 'ui_print("----------------------------");' >> $4/updater-script
	if [[ $1 = "backup" ]]; then
		echo 'ui_print("Complete. You have been reverted to the previous state");' >> $4/updater-script
	elif [[ $1 = "mod" ]]; then
		printf "Would you like to write a custom message at the end of the flash script? [Y/N]:"; $kclr;
		read INPUT
		case $INPUT in
			[yY])printf "Compose your message and press enter:"; $kclr; read INPUT; echo 'ui_print("'$INPUT'");' >> $4/updater-script ;;
			[nN]) echo 'ui_print("Complete.");' >> $4/updater-script ;;
				*) echo -e "Not a valid entry. Skipping.."; echo 'ui_print("Complete.");' >> $4/updater-script ;;
		esac
	fi
}

create_zip () {
	if [[ $1 == "backup" ]]; then
		if [[ ! -d ./Backup ]]; then
			mkdir ./Backup
			mkdir ./Backup/Flashable
		elif [[ ! -d ./Backup/Flashable ]]; then
			mkdir ./Backup/Flashable
		fi
		directory='Pulled'
		instance=$(date +%Y%m%d-%H%M)
		zipname="Backup/Flashable/backup-$2-$instance"
		message='You can find your backup in the "/Backup/Flashable" folder'
		romtype='Pre-Modified ROM'
	elif [[ $1 == "mod" ]]; then
		if [[ ! -d ./Completed/$3 ]]; then
			mkdir -p ./Completed/$3
		fi
		directory='Recompiled'
		zipname="Completed/$3/$2"
		message='You can find your flashable zip ('$2') in the "/Completed/'$3'" folder'
		romtype=$3
	fi
	echo -e "Adding script..."
	mkdir ./$directory/META-INF
	cp -r ./Tools/META-INF/* ./$directory/META-INF/
	create_script $1 $2 "$romtype" "./$directory/META-INF/com/google/android" "all"
	kill_DStore
	cd ./Tools/$platform
	echo -e "Zipping it all up..."
	./7za a -tzip unsigned.zip ../../$directory/*
	echo -e "Signing & Sealing..."
	java -jar signapk.jar testkey.x509.pem testkey.pk8 unsigned.zip ../../$zipname.zip
	rm -rf ./unsigned.zip
	cd ../../
	if [[ -d ./Pulled/META-INF ]]; then
		rm -rf ./Pulled/META-INF
	fi
	echo -e "I'm Yours!"
	echo -e "$message"
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
	parse $2
	if [[ $1 != "ziprom" ]]; then
		backup check $2
	elif [[ $1 == "ziprom" ]]; then
 		pull_rom $3
	fi
	decompile
	replace $2
	recompile
	if [[ $1 == "flashdevice" ]]; then
		push
	elif [[ $1 == "zipdevice" ]]; then
		create_zip mod $2 "UnknownDevice"
	elif [[ $1 == "ziprom" ]]; then
		create_zip mod $2 $3
	fi
	rm -rf ./Recompiled
	main_menu
}

start_func

if [ $? != 0 ]; then
	echo -e "Unknown error occured."
	echo -e "Please copy output of script to a file and report it to MAD Industries."
	exit 1
fi