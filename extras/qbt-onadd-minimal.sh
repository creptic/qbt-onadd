#!/bin/bash
############################
# Author: Creptic :: 02/21/23 v0.95
# Source: https://github.com/creptic/qbt-onadd (extras onadd-minimal.sh)
# Purpose: Change settings to a single torrent in qBittorrent with qbittorrent-cli.
# Requires: https://github.com/fedarovich/qbittorrent-cli
#         - qBittorrent server info needs to be set in qbittorrent-cli
# Usage: ./script.sh <options> <torrent hash> <optional qBittorrent category)> 
#         - Run in terminal or as a external add path for qBittorrent.  
#         - Add the path of this script with "%I" or "%I" "%L" arguement in  
#         - Run external program on torrent ADDED in your qBittorrent settings.
#         - Example: /path/thisscriptname "%I,%L"
###################
###-=[Globals]=-###
###################
hash="$1"
category="$2"
#########
## qbittorrent-cli path 
qbt_cli="/usr/bin/qbt" # Path to qbittorrent-cli (no args)
## Options
wait_time="0" # Wait time in seconds before running checks. May help with 'Unknown Tracker' problems when adding 
# tracker(s) to check (shortened name without port) ex:http://tracker.org (comma seperate) 
check_for_trackers="1" # Check Defined and Private/Public trackers. ("0"=Category checks only]  
trackers="http://foo.org" # Seperate with commas for multiple trackers
##########

function show_settings_qbittorrent_cli {
   #Show current qbittorrent-cli settings
   $qbt_cli settings
}

function show_seedtime_info_qbittorrent_cli {
   #Display seedtime info from qbittorrent-cli
   $qbt_cli torrent share "$hash"
}  

function change_max_upload () {
  #Maximum Upload speed (KB) (0=Unlimited)
  local t_maxup="$1"
  if [ "$t_maxup" != "" ]; then
     local to_bytes="$(( ${t_maxup%% *} * 1024))"
     `$qbt_cli torrent limit upload -s "$to_bytes" "$hash"`
  fi
}

function change_max_download () {
  #Maximum Upload speed (KB) (0=Unlimited)
  local t_maxdl="$1"
  if [ "$t_maxdl" != "" ]; then
     local to_bytes="$(( ${t_maxdl%% *} * 1024))"
    `$qbt_cli torrent limit download -s "$to_bytes" "$hash"`
  fi
}

function change_tag () {
  local t_tag="$1"
  if [ "$t_tag" != "" ]; then
     `$qbt_cli torrent tags add "$hash" "$t_tag"` 
  fi
}

function change_seedtime () {
 #Seeding time limit (ex "[04:05:06]" = 4 days,5 hours and 6 seconds) 
 local t_seedtime="$1"
  if [ "$t_seedtime" != "" ]; then
     local days=${t_seedtime::2} 
     local hrs=${t_seedtime:3:2}
     local mins=${t_seedtime:6:2}
     `$qbt_cli torrent share -t "$t_seedtime" "$hash"` 
  fi
}

function change_ratio_limit () {
  local t_ratio_limit="$1"
  if [ "$t_ratio_limit" != "" ]; then
     `$qbt_cli torrent share -r "$t_ratio_limit" "$hash"`
  fi
}

function change_auto_torrent_managment () {
  local t_atm="$1" # (0=OFF:1=ON)"
  if [ "$t_atm" != "" ]; then
     `$qbt_cli torrent options -a "$t_atm" "$hash"`
  fi
}

function change_superseed () {
 local t_superseed="$1" # (0=OFF:1=ON)"
  if [ "$t_superseed" != "" ]; then
     `$qbt_cli torrent options -z "$t_superseed" "$hash"`
  fi
}

function change_seqdl () {
  local t_seqdl="$1" # (0=OFF:1=ON)"
  if [ "$t_seqdl" != "" ]; then
     `$qbt_cli torrent options -z "$t_seqdl" "$hash"`
  fi
}

function change_category () {   
  local t_new_category="$1"
  if [ "$t_new_category" != "" ]; then
     `$qbt_cli torrent category --set "$t_new_category" "$hash"`
  fi
}

function apply_settings {
  # Null values are checked in function called
  change_tag "$tag"
  change_max_upload "$maxup" ; change_max_download "$maxdl"
  change_seedtime "$seedtime" ; change_ratio_limit "$ratio_limit"
  change_auto_torrent_managment "$atm" ; change_superseed "$superseed"
  change_seqdl "$seqdl"
  if [ "$new_category" != "$category" ]; then change_category "$new_category" ; fi 
}

## Tracker functions
function check_for_tracker {
  #Set global found_tracker. if found, null ("") if not found. 
  found_tracker="" ; local x ; local i
  if [[ -n "$trackers" && -n "$trackers_qbt" ]];then      
     for x in $(echo $trackers_qbt | tr ',' '\n') ;do
       for i in $(echo $trackers | tr ',' '\n') ;do
          if [ "$i" == "$x" ]; then found_tracker="$i" ;fi 
       done
       if [ "$found_tracker" != "" ]; then break ; fi 
     done
  fi 
}

function get_trackers_qbittorrent_cli {
  #Get tracker(s) and store in list (comma seperated)
  #Global var tracker is list ; "Unknown" if not found   
  trackers_qbt=`$qbt_cli torrent tracker list -F csv "$hash" | grep ":" | cut -d ":" -f1,2 | tr -s "\n" ","`
  if [ "$trackers_qbt" == "" ];then trackers_qbt="Unknown" 
  else
    #remove last "," if one is found for a clean list
    local last_chr="${trackers_qbt:(-1)}" 
    if [ "$last_chr" == "," ]; then trackers_qbt="${trackers_qbt::-1}" ; fi
  fi
}

function check_connection {
  echo -n "Checking Status: "
  local t_con=`$qbt_cli global info -F property:name="connection status"`
  echo -n "[""$t_con""]" ; echo "" 
}

function check_for_wait_time {
  if [[ "$wait_time" != "" &&  "$wait_time" != "0" ]] ;then 
     sleep "$wait_time" 
  fi
}

function get_name_qbittorrent_cli {
  #Global torrent_name change if found. null ("") if not found. 
  torrent_name=""
  torrent_name=`$qbt_cli torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
}
######
## [Begin]
# Available variables: (empty or unused will not change on apply_settings)
# Add or delete any variables as needed. Order used doesnt not matter.
# -[Variables]-
# tag = Appends name(s) you want to add to tag (multiple with spaces ex:tag="tag1 tag2")
# maxup = Maximum Upload speed (KB) (0=Unlimited)
# maxdl = Maximum Download speed (KB) (0=Unlimited)
# seedtime = Seeding time limit. (ex "[04:05:06]" = 4 days,5 hours and 6 seconds) 
# ratio_limit = Ratio Limit (0=Unlimited)
# atm = Enable/Disable Automatic Torrent Managment. ("0"=Disabled:"1"=Enabled)
# superseed = Disables/Enables superseeding. ("0"=Disabled:"1"=Enabled) 
# seqdl = Enable/Disable Sequential download ("0"=Disabled:"1"=Enabled) 
# new_category = Changes category (category must exist in qBittorrent). 
# ------
# Use apply settings to set when done 
# or call function with value to set right away (ex.change_ratio_limit "1")
# -----

##[Categories]
if [ "$category" == "test" ];then
   #Defined Category found
   tag="test"
   #maxup="" 
   #maxdl="" 
   #new_category="test"
   #seedtime="00:00:05" 
   #ratio_limit="" 
   category_found="1" #Category found flag to apply settings below if found. 
fi

if [ "$category_found" == "1" ]; then 
      apply_settings
      exit
fi
##[End of Categories]

if [ "$check_for_trackers" == "1" ]; then
   #function to get tracker info from qbittorrent-cli
   get_trackers_qbittorrent_cli 
else 
   exit
fi

if [ "$trackers_qbt" == "Unknown" ];then
   # If qbittorrent-cli returns a empty tracker, change tag to Unknown and exit.
   tag="Unknown"
   apply_settings 
   exit
fi

#Check for tracker in trackers list (top)
check_for_tracker

##[Defined Trackers] (add individual tracker checks here)
if [ "$found_tracker" == "http://foo.org" ]; then
   tag="foo"; #maxup="" ; #maxdl=""
   #new_category="test" 
   #seedtime="03:20:10" ; #ratio_limit=""
   #superseed="" ; #atm="" ; #seqdl=""
   apply_settings
   exit
fi
##[End of Defined Trackers]
##[Public / Private]
# if no defined tracker(s) above found. Use Private/Public settings below.
# Tracker found in your list but not a Defined tracker. [Private] 
if [ "$found_tracker" != "" ]; then
   tag="Private" # Set Tag in qBittorrent
   #maxup="" 
   #maxdl="" 
   #seedtime="04:00:00" 
   #ratio_limit=""
else
   tag="Public"
   #maxup=""
   #maxdl=""
   #seedtime=""
   #ratio_limit=""
fi
apply_settings
exit 0
##[End]
