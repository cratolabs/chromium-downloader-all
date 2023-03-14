#!/bin/bash
#Developed By Crato
base_url="https://versionhistory.googleapis.com/v1/chrome/platforms"
#channel="stable beta dev canary latest"
#di not use double inverted commas for platform as i want all platformTypes in single line
platforms=$(curl -s "$base_url" | grep "platformType" | grep -oP '(?<=:\s")[^"]*(?=")' | sort -Vr )
echo $platforms

win64_snapshot=Win_x64
win64_pkg=chrome-win.zip
win_snapshot=Win
win_pkg=chrome-win.zip
mac_arm64_snapshot="Mac_Arm"
mac_arm64_pkg=chrome-mac.zip
mac_snapshot="Mac"
mac_pkg=chrome-mac.zip
linux_snapshot=Linux_x64
linux_pkg=chrome-linux.zip
lacros_arm64_snapshot=lacros_arm64
lacros_arm64_pkg=lacros.zip
lacros_arm32_snapshot=lacros_arm
lacros_arm32_pkg=lacros.zip
lacros_snapshot=lacros64
lacros_pkg=lacros.zip
ios=""
fuchsia=""
chromeos_snapshot="Linux_ChromiumOS_Full"
chromeos_pkg=chrome-chromeos.zip
#setting android_snapshot to android_arm64 inspite of android as most devices are 64 bit 
android_snapshot=Android_Arm64
android_pkg=chrome-android.zip
#since webview is par of android package so setting it to android
webview_snapshot="Android_Arm64"
webview_pkg=chrome-android.zip




retries_count=0
max_retries=10
while [ $retries_count -le $max_retries ]; do
	clear
	echo =======================Chromium===========================
	echo "$(a=1; for i in $platforms; do echo $a"."$i; ((a++));done)" | awk '{printf "%-20s", $0} NR%3==0 {printf "\n"}'
	echo -e "\n============Select your OS (1,2,3,...$(echo $platforms | wc -w),all)=============="
	read input
	echo -en "\033[1A\033[2K"
	input=${input// }
	if [[ "$input" == "all" ]]; then 
		echo "selecting all platforms"
		echo $platforms
		break
	elif [[ -n "$input" ]] && (( $input > 0 && $input <= $(echo $platforms | wc -w) )); then
		platforms=$(echo $platforms | cut -d' ' -f$input)
		echo $input.$platforms
		break
	else
		echo ===================
		echo "Enter valid input"
		sleep 1
		clear
	fi
	((retries_count++))
done
platforms=$(echo $platforms | tr '[:upper:]' '[:lower:]')
mkdir -p $platforms
clear
for platform in $platforms;do
	#echo ===================$platform==========================
	cd $platform
	channels=$(curl -s "$base_url/$platform/channels" | grep "channelType" | grep -oP '(?<=:\s")[^"]*(?=")' | tr '[:upper:]' '[:lower:]' )
	channels="latest "$channels
	echo ==$platform:  $channels==

	retries_count=0
	max_retries=10
	while [ $retries_count -le $max_retries ]; do
		clear
		echo ===========================Chromium $platform==========================
		echo "$(a=1; for i in $channels; do echo $a"."$i; ((a++));done)" | awk '{printf "%-20s", $0} NR%3==0 {printf "\n"}'
		echo -e "\n===Select channel (1,2,3,..$(echo $channels | wc -w),all) Press Enter for latest version==="
		read input
		echo -en "\033[1A\033[2K"
		input=${input// }
		if [[ "$input" == "all" ]]; then 
			echo "selecting all channels"
			echo "Channels="$channels
			break
		elif [[ -n "$input" ]] && (( $input > 0 && $input <= $(echo $channels | wc -w) )); then
			channels=$(echo $channels | cut -d' ' -f$input)
			echo $input.$channels
			break
		elif [[ "$input" == "" ]]; then
			channels="latest"
			echo "1.latest"
			break
		else
			echo ===================
			echo "Enter valid input"
			sleep 1
			clear
		fi
		((retries_count++))
	done

	mkdir -p $channels
	base_name="$platform""_snapshot"
	base_pkg="$platform""_pkg"
	for channel in $channels;do
		if [[ "$channel" == "latest" ]];then
			version_branch_position=$(curl -s "https://commondatastorage.googleapis.com/chromium-browser-snapshots/${!base_name}/LAST_CHANGE")
		else
			version="$(curl -s "$base_url"/$platform/channels/$channel"/versions/all/releases" | grep '"version*' | sort -Vr | head -n 1 | grep -Po '([0-9]+([.][0-9]+)+)')"
			version_branch_position="$(curl -s https://chromiumdash.appspot.com/fetch_version?version=$version | tr ',' '\n' | grep  "chromium_main_branch_position" | grep -o '[0-9]\+')"
		fi
		echo "$platform $channel" "version=$version" "position=$version_branch_position"

		cd $channel
		if [ -d $version_branch_position ] ; then
		  echo "already have latest version"
		  sleep 3
		else
			package_url="https://commondatastorage.googleapis.com/chromium-browser-snapshots/${!base_name}/$version_branch_position/${!base_pkg}"
			echo "fetching $package_url"
			rm -rf $version_branch_position
			mkdir $version_branch_position
			pushd $version_branch_position
			curl -# $package_url > ${!base_pkg}
			echo "unzipping.."
			unzip ${!base_pkg}
			popd
			rm -f ./latest
			basename=$(basename "${!base_pkg}" .zip)
			ln -s $version_branch_position/$basename/ ./latest

		fi


		cd ..
	done
	cd ..
done