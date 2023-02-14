#!/bin/bash
############################
# Author: Creptic :: 02/11/23 v0.95
# Source: https://github.com/creptic/qbt-onadd
# Purpose: Change settings to a single torrent in qBittorrent with qbittorrent-cli.
#         - Run in terminal or as a external add path for qBittorrent.  
#         - No effect to other torrents running, or global settings in qBittorrent.
#         - Change setting depending on private tracker(s) from a user string.
#         - Defaults to public if no tracker found in string.
#         - If no tracker found, only change tag in qBittorrent to 'Unknown'
#         - All unused or null variables will not change a setting.
#         - Set settings for user defined categories and trackers.
#         - Note: Seedtime does not show in qBittorent , use -t or -i to see current seedtime in terminal.
# Requires: https://github.com/fedarovich/qbittorrent-cli
#         - qBittorrent server info needs to be set in qbittorrent-cli (see -h and -t).
#         - Add the path of this script with "%I" or "%I" "%L" arguement in  
#         - Run external program on torrent ADDED in your qBittorrent settings.
#         - Example: /home/foo/added.sh "%I,%L" 
# Usage:  ./script.sh <options> <torrent hash> <optional qBittorrent category)>
#         - See README or -h for help.
###################
###-=[Globals]=-###
###################
argu=$* # Needed to get arguments Do not remove
#########
## Log Settings
log_level="1" # Terminal=("1") File=("2")[log_file] None="0" [see -h to override] 
log_file="" # [Must be writable]. If trying to log to file, and not found swithes to log_level=1 (terminal) 
log_clear="1" # Clear log everytime script is started (requires log_level=2) [Logging to file only]
## Paths
qbt="/usr/bin/qbt" # Path to qbittorrent-cli (no args)
## Options
wait_time="0" # Wait time in seconds before running checks. May help with 'Unknown Tracker' problems when adding 
skip_wait_dryrun="1" # if you have wait_time set, and running with -d (dry-run); skip the wait time ["1"=Skip]
skip_hash_check="0" # Skip check for 40 character length hash. Use "1" to skip check. [default 0]
skip_name="0" # Skip Attempt to get torrent name [default 0]
run_connection_check="1" # Runs a check for connection to qBittorrent and qbittorrent-cli
check_both="0" # If category is found, check for private and defined trackers too [Warning vars may be re-used]
# Private tracker(s) to check (shortened name without port) ex:http://tracker.org (comma seperate) 
check_for_private_trackers="1" # Check Defined and Private/Public trackers. ("0"=Category checks only]  
private_trackers="http://foo.org,udp://tracker.opentrackr.org" # Seperate with commas for multiple trackers
##########

#Display qbittorrent-cli settings and commands to auth with qbittorent : See (-t) in help
#And test connection with qbittorrent-cli and qBittorrent server
function show_settings_qbittorrent_cli {
  echo "-=[""$qbt""]=-"
  echo "- May need to restart qBittorrent server if any info changed, and having issue connecting"
  $qbt settings
  echo "-----"
  echo "- Use a command below to manually set qBittorrent server info in qbittorrent-cli "
  echo "- These can also be run with this script (-l <user>,-u <url>,or -p) [see help -h]"        
  echo "- URL:/path/to/qbittorrent-cli settings set url <url> (ex:http://localhost:8080)"
  echo "- User name:/path/to/qbittorrent-cli settings set username <username>"
  echo "- Password:/path/to/qbittorrent-cli settings set password [read and follow prompt]"
  echo "-----"
  echo -n " Checking Status: "
  local t_con=`$qbt global info -F property:name="connection status"`
  echo -n "[""$t_con""]"
  echo ""
  exit 0
}

#Change qBittorrent 'Password' in qbittorrent-cli, and show current settings: See (-p, and -t) in help
function set_password_qbittorremt_cli {
  echo "###########################################"
  echo "# Passwords are stored in qbittorrent_cli #" 
  echo "# - No password will be saved to script - #"
  echo "###########################################"
  $qbt settings set password
  $qbt settings
  exit 0
}
#Change qBittorrent 'URL' in qbittorrent-cli, and show current settings: See (-u, and -t) in help
function set_url_qbittorremt_cli() {
  local url="$1" 
  echo "#########################################"
  echo "# URL will be stored in qbittorrent_cli #" 
  echo "# --- Example:http://localhost:8080 --- #"
  echo "#########################################"
  if [ "$url" == "" ]; then 
     echo "No URL entered .... exiting"
     exit 1
  else
     $qbt settings set url "$url"
     $qbt settings
  fi
  exit 0
}
#Change qBittorrent 'User name' in qbittorrent-cli, and show current settings: See (-l, and -t) in help
function set_login_name_qbittorremt_cli() { 
  local login="$1" 
  echo "###########################################"
  echo "# Login will be stored in qbittorrent_cli #" 
  echo "###########################################"
  if [ "$login" == "" ]; then 
     echo "No Login name entered .... exiting"
     exit 1
  else
     echo "Changing User name to:[""$login""]"
     $qbt settings set username "$login"
     $qbt settings
  fi
  exit 0
}

#Display info from qbittorrent-cli: See (-t) in help
function show_all_info_qbittorrent_cli {
  echo "Current Info for:["$hash"]"
  $qbt torrent properties "$hash"
  $qbt torrent share "$hash"
  $qbt torrent options "$hash"
  local t_name=`$qbt torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
  echo "Name:[""$t_name""]"
  exit 0
}

#Display seedtime info from qbittorrent-cli: See (-s) in help
function show_seedtime_info_qbittorrent_cli {
  #Get torrent name from qbittorrent-cli 
  local s_time=`$qbt torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
  echo "Name:[""$s_time""]"
  $qbt torrent share "$hash"
  exit 0
}  

### Change setting(s) in qbittorrent-cli functions
function change_max_upload () {
  local t_maxup="$1"
  if [ "$t_maxup" != "" ]; then
     local to_bytes="$(( ${t_maxup%% *} * 1024))"
     if [ "$dry_run" != "1" ]; then
       `$qbt torrent limit upload -s "$to_bytes" "$hash"`
     fi
     dg.print "  -Setting max upload speed:[""$t_maxup"" KB]" "(""$to_bytes"" Bytes/s) 0=Unlimited"
   else
     dg.print "  -Max upload speed not set:[""$t_maxup""]"
  fi
}

function change_max_download () {
  local t_maxdl="$1"
  if [ "$t_maxdl" != "" ]; then
     local to_bytes="$(( ${t_maxdl%% *} * 1024))"
     if [ "$dry_run" != "1" ]; then
       `$qbt torrent limit download -s "$to_bytes" "$hash"`
     fi
     dg.print "  -Setting max download speed:[""$t_maxdl"" KB]" "(""$to_bytes"" Bytes/s) 0=Unlimited"
   else
     dg.print "  -Max download speed not set:[""$t_maxdl""]"
  fi
}

function change_tag () {
  local t_tag="$1"
  if [ "$t_tag" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt torrent tags add "$hash" "$t_tag"` 
     fi
     dg.print "  -Setting tag:[""$t_tag""]"
   else
     dg.print "  -Tag not set:[""$t_tag""]"
  fi
}

function change_seedtime () {
 local t_seedtime="$1"
  if [ "$t_seedtime" != "" ]; then
     local days=${t_seedtime::2} 
     local hrs=${t_seedtime:3:2}
     local mins=${t_seedtime:6:2}
     if [ "$dry_run" != "1" ]; then
        `$qbt torrent share -t "$t_seedtime" "$hash"`   
     fi
     dg.print "  -Setting seedtime limit:[""$t_seedtime""]" "(""$days"" Days: ""$hrs"" "Hours: """$mins"" Minutes)" 
   else
     dg.print "  -Seedtime limit not set:[""$t_seedtime""]"  
  fi
}

function change_ratio_limit () {
  local t_ratio_limit="$1"
  if [ "$t_ratio_limit" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt torrent share -r "$t_ratio_limit" "$hash"`
     fi  
     dg.print "  -Setting ratio limit:[""$t_ratio_limit""]"
   else
     dg.print "  -Ratio limit not set:[""$t_ratio_limit""]"  
  fi
}

function change_auto_torrent_managment () {
  local t_atm="$1"
  if [ "$t_atm" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt torrent options -a "$t_atm" "$hash"`
     fi
     dg.print "  -Setting Automatic Torrent Managment:[""$t_atm""] (0=OFF:1=ON)"
  fi
}

function change_superseed () {
 local t_superseed="$1"
  if [ "$t_superseed" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt torrent options -z "$t_superseed" "$hash"`
     fi
     dg.print "  -Setting superseed :[""$t_superseed""] (0=OFF:1=ON)"
  fi
}

function change_seqdl () {
  local t_seqdl="$1"
  if [ "$t_seqdl" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt torrent options -z "$t_seqdl" "$hash"`
     fi
     dg.print "  -Setting sequential download :[""$t_seqdl""] (0=OFF:1=ON)"
  fi
}

function change_category () {   
  local t_new_category="$1"
  if [ "$t_new_category" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt torrent category --set "$t_new_category" "$hash"`
     fi
     dg.print "  -Changing category:[""$t_new_category""] (Category must already exist in qBittorrent)"
  fi
}

function apply_settings {
  if [ "$dry_run" == "1" ]; then 
     dg.print "  -Using dry run: [Changes will not be applied]"
  fi
  dg.print "  -Applying settings to qBittorrent ..."
  change_tag "$tag"
  change_max_upload "$maxup" 
  change_max_download "$maxdl"
  change_seedtime "$seedtime"
  change_ratio_limit "$ratio_limit"
  change_auto_torrent_managment "$atm"
  change_superseed "$superseed"
  change_seqdl "$seqdl"
  if [ "$new_category" != "$category" ]; then change_category "$new_category" ; fi 
}

## Tracker functions

function check_for_private_tracker {
  #Set global found_tracker. if found, null ("") if not found. 
  found_tracker="" ; local x ; local i
  dg.print "  -Checking your list:[""$private_trackers""]"
  if [[ -n "$private_trackers" && -n "$tracker" ]];then      
     for x in $(echo $tracker | tr ',' '\n') ;do
       for i in $(echo $private_trackers | tr ',' '\n') ;do
          if [ "$i" == "$x" ]; then found_tracker="$i" ;fi 
      done
       if [ -n "$found_tracker" ]; then 
          dg.print "  -Found tracker:[""$found_tracker""]"     
          break ;
       fi 
     done
  fi 
}

function get_trackers_qbittorrent_cli {
  dg.print "  -Getting tracker info from:[""$qbt""]"
  #Get tracker(s) and store in list (comma seperated)
  tracker=`qbt torrent tracker list -F csv "$hash" | grep ":" | cut -d ":" -f1,2 | tr -s "\n" ","`
  local num_track=`(echo "$tracker" | grep -o "," | wc -l)`
  if [ "$tracker" == "" ];then 
     tracker="Unknown" 
  else
    #remove last "," if one is found for a clean list
    local last_chr="${tracker:(-1)}" 
    if [ "$last_chr" == "," ]; then tracker="${tracker::-1}" ; fi
    dg.print "  -Torrent trackers (""$num_track""):[""$tracker""]"
  fi
}

# Error checking functions
function hash_check {
  if [ "$skip_hash_check" != "1" ]; then
     #just checking the length not hexdigits.
     local h_len=${#hash}
     dg.print "  -Checking for 40 character hash length:[""$h_len""]" 
     if [ "$h_len" != "40" ]; then
        dg.print "  -Hash check failed .. exiting"
        if [ "$log_level" != "1" ];then 
           echo "Hash length needs to be 40:[""$h_len""] .. exiting"
        fi  
      exit 1  
     fi
  else
     dg.print "  -Skipped checking hash length:[""$skip_hash_check""]"
  fi
}

function check_for_qbittorrent-cli {
  local is_silent="$1"
  if [ "$is_silent" != "silent" ]; then 
     if [ "$log_level" -ge "1" ]; then
        dg.print "  -Checking for qbittorrent-cli:[""$qbt""]"
     fi     
  else
     if [ ! -f "$qbt" ]; then
        dg.print "Error with qbittorrent-cli path:[""$qbt""] .. exiting [set path in script]"
        exit 1
     fi
  fi
}

function check_connection {
  local t_con=`$qbt global info -F property:name="connection status"`
  if [ "$t_con" != "" ]; then 
        dg.print "  -Checking connection:[""$t_con""]" 
  else
     dg.print " -Checking connection:[Failed] ... exiting"
     exit 1 
  fi
}

function check_for_wait_time {
  if [[ "$wait_time" != "" &&  "$wait_time" != "0" ]] ;then 
     if [ "$dry_run" == "1" ]; then
        if [ "$skip_wait_dryrun" == "1" ]; then
           dg.print "  -Waiting: Skip on dry run is enabled: [""$skip_wait_dryrun""] ... skipping"
        else
           dg.print "  -Waiting:[""$wait_time"" seconds] [""$skip_wait_dryrun""] ..."    
           sleep "$wait_time" 
        fi
     else
         dg.print "  -Waiting:[""$wait_time"" seconds] ..."
         sleep "$wait_time" 
     fi
  fi
}

function err_no_hash {
  dg.print "  -No hash info passed ... exiting"
  if [ "$log_level" != "1" ];then echo "No hash info passed ... exiting";fi
  exit 1
}

function test_the_logfile {
  if [ "$log_level" == "2" ]; then  
     if [[ ! -r "$log_file" && ! -w "$log_file" ]] ; then 
        log_level="1"
        echo "***********************************"
        echo " - Error: !!Access Denied!! to logfile (log_file)"
        echo " - File:[""$log_file""]" 
        echo " - To disable logging to file, dont use -f or change log_level in script"  
        echo " - Switching logging to terminal[set log_level] to disable logging to file" 
        echo " - Check the files permissions, and setting in script (log_file)"
        echo "***********************************"
     else
        if [ "$log_clear" == "1" ];then `(echo -n "" > "$log_file")` ; fi
     fi    
  fi
}

#Processing Functions
function dg.print {
  if [ "$log_level" == "1" ];then echo "${*}" ;fi
  if [ "$log_level" == "2" ];then echo "${*}" >> "$log_file" ;fi
}

function finished {
  dg.print "-=[***[Finished]***]=-"
  exit 0
}

function get_name_qbittorrent_cli {
  #Global torrent_name change if found. null ("") if not found. 
  torrent_name=""
  torrent_name=`$qbt torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
  dg.print "  -Getting torrent name:[""$torrent_name""]"
}

function init_logging {
  if [ "$log_level" != "0" ];then
     if [ "$log_level" == "2" ]; then 
        time_stamp=`date +%Y-%m-%d_%H-%M-%S`
        dg.print "-=[***[Started]***]=-"
        dg.print "  -Time:[""$time_stamp""]"
        if [ "$show_name_in_log" == "1" ]; then get_name ;fi
     else
        if [ "$log_level" == "1" ];then
           dg.print "-=[***[Started]***]=-"
        fi
     fi
  fi
}

#Command line function: 
# - Get hash and/or category name from cmdline.
# - Set log-level accordingly
function check_cmdline {
  local a=($argu) ; local first_arg="${a[@]:0:1}"
  local second_arg="${a[@]:1:1}" ; local third_arg="${a[@]:2:1}"
  local fswitch=${argu:0:1}
  if [ "$fswitch" == "-" ]; then 
     chk_switch=${argu:0:2}
     case "$chk_switch" in
      -h)
    	 log_level=1 ; show_help
    	 ;;
      -t)
         log_level=1 ; check_for_qbittorrent-cli "silent" 
         show_settings_qbittorrent_cli
         ;; 
      -n)
         ## [override] No logging (log_level=0)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level=0
            if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi 
         ;;
      -v)
         ## [override] log to terminal (verbose) (log_level=1)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level=1
           if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi 
         ;;
      -f)
         ## [override] change log level to log to file (log_level=2)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level=2
            if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi 
         ;;
      -d)
       ##Dry run
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1"  ; dry_run="1"
            if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi 
         ;;
      -i)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level="1"
            check_for_qbittorrent-cli "silent" 
            show_all_info_qbittorrent_cli
         fi 
         ;;
      -s)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level="1"
            check_for_qbittorrent-cli "silent" 
            show_seedtime_info_qbittorrent_cli
         fi 
         ;;
      -p)
         log_level="1" ; check_for_qbittorrent-cli "silent" 
         set_password_qbittorremt_cli         
         ;;
      -u)
         log_level="1" ; check_for_qbittorrent-cli "silent" 
         set_url_qbittorremt_cli "${second_arg}"       
         ;;
      -l)
         log_level="1" ; check_for_qbittorrent-cli "silent" 
         set_login_name_qbittorremt_cli "${second_arg}"       
         ;;
      **)
         if [ "$log_level" == "1" ];then 
            echo " Invalid arguement .. exiting"
            show_help
         else
            dg.print "Invalid arguent:[""$chk_switch""]" 
            exit 1
         fi 
         ;; 
     esac
  else
      if [ "$first_arg" == "" ]; then err_no_hash 
      else 
      hash="$first_arg" ; run_hash_check="1" 
      fi 
      if [ "$second_arg" != "" ];then category="$second_arg" ;fi
  fi
}

function show_help {
  echo " -----------------------------------------------"
  echo " Usage: "$0" [OPTION] ... HASH ... [CATEGORY]"
  echo " Change settings on a torrent in qbittorrent depending on tracker or category"
  echo ""
  echo " OPTION and CATEGORY are optional. qbittorrent-cli required."
  echo " Options:"
  echo "  -i [hash]  # Get full Information on a torrent and exit"
  echo "  -s [hash]  # Show Seedtime and ratio info of a torrent and exit"
  echo "  -d [hash]  # Dry run. Run without changing settings"
  echo "  -n [hash]  # Do Not log (log_level=0) [override]"
  echo "  -v [hash]  # Log to terminal (Verbose) (log_level=1) [override]"
  echo "  -f [hash]  # Log to File (log_level=2) [override]"
  echo "  -t # Test Connection. Show commands to manually set qBittorrent info."
  echo "  -p # Sets Password in qbittorrent-cli settings (Read prompt)"
  echo "  -u [url:port] # Sets qBittorent URL in qbittorrent-cli settings"
  echo "  -l [login] # Sets qBittorrent Login name in qbittorent-cli settings" 
  echo "  -h # Display this Help and exit"
  echo " -----------------------------------------------"
  exit 1
}

#Intial startup
##########
check_cmdline # Check cmdline options
if [ "$log_level" == "2" ]; then 
   test_the_logfile 
fi 
init_logging # Start logging if set. 
check_for_qbittorrent-cli #Check if qbt-cli exists
if [ "$run_hash_check" == "1" ]; then 
   #check hash tag len (skip_hash_check="1" to override) 
   hash_check 
fi 
dg.print "  -Arguments:[""$argu""]" 
dg.print "  -Hash:[""${hash}""]"
dg.print "  -Category:[""${category}""]"
# if run_connection_check="1" then check connection
if [ "$run_connection_check" == "1" ]; then 
   check_connection 
else 
   dg.print "  -Skipped connection check:[run_connection_check=0]" 
fi
# If wait_time is set wait the defined time in seconds [skips on dry run]
check_for_wait_time
#If skip_name is set then dont show name. if log_level is 0 no need to show name
if [ "$skip_name" != "1" ]; then 
   if [ "$log_level" != "0" ]; then get_name_qbittorrent_cli ;fi
   else 
   dg.print "  -Skipped getting name:[""$skip_name""]"
fi
#########
# Begin #
#########
## Available variables: (Empty or unused variables will not change values on apply_settings)
## Add or delete any varibales as needed. Order of variables used don't matter.
## -----
## tag = Name you want to add to tag (can add multiple with spaces eg:tag="tag1 tag2")
## maxup = Maximum Upload speed (KB) (0=Unlimited)
## maxdl = Maximum Download speed (KB) (0=Unlimited)
## seedtime = Seeding time limit. (eg "[04:05:06]" = 4 days,5 hours and 6 seconds) 
## ratio_limit = Ratio Limit (0=Unlimited)
## atm = Enable/Disable Automatic Torrent Managment. ("0"=Disabled:"1"=Enabled)
## superseed = Disables/Enables superseeding. ("0"=Disabled:"1"=Enabled) 
## seqdl = Enable/Disable Sequential download ("0"=Disabled:"1"=Enabled) 
## new_category = Changes category (category must exist in qBittorrent). 
## -----
#########
##[Categories]

## Example: If category = "test" then use these settings 
if [ "$category" == "test" ];then
   dg.print "  -Defined Category found:[""$category""]"
   tag="test"
   #maxup="" 
   #maxdl="" 
   #new_category="test"
   #seedtime="00:00:05"
   #ratio_limit="" 
   category_found="1" #Category found flag to apply settings below if found. 
fi
#Tip:Copy if statement above, and edit for more category checks. (with "fi")
##[End of Categories] 
#---
## If category was found and not checking trackers, apply settings and exit. 
if [ "$category_found" == "1" ]; then 
   if [ "$check_both" != "1" ]; then
      apply_settings
      finished
   else
      if [ "$check_both" == "1" ]; then 
         tag="" # If tag was set, then unset to append new ones if needed 
         if [ "$new_category" != "$category" ]; then 
           #if new_category was set. change category to new category
             category="$new_category"
         fi  
         check_for_private_trackers="1" 
      fi 
   fi
fi
if [ "$check_for_private_trackers" == "1" ]; then
   get_trackers_qbittorrent_cli #function to get tracker info from qbittorrent-cli
else 
   finished
fi
#---
#########
## Checking by Trackers (first http(s):// tracker found (no :port/../announce/))
## Customize values in these if statements, if checking by tracker
## ----------
## Private: Tracker found in both qbt-cli and list (private_trackers)
## Public: Tracker found in qbt-cli, but not found in list (private_trackers)
## Unknown: Tracker not found in qbt-cli. [exits]
## Defined: Use settings for user defined tracker url "eg:http://foo.org" tracker. [exits]
## ----------
#########
##[Unknown Tracker] (tracker not found in qbt-cli)
# If qbittorrent-cli returns a empty tracker, change tag to Unknown and exit. 

if [ "$tracker" == "Unknown" ];then
   dg.print "  -Empty tracker info returned from qBitorrent-cli:[Unknown]"
   tag="Unknown" 
   #add more settings here if needed
   apply_settings
   finished
fi

# ** Note: Try changing wait_time, if you have issue getting tracker, and not running manually
##[End of Unknown Tracker]
#---
# Checking for tracker in private_trackers list (top)
check_for_private_tracker
#---
##[Defined Trackers] (add individual tracker checks here)
if [ "$tracker" == "http://foo.org" ]; then
   dg.print "  -Defined Private tracker found:[""$tracker""]"
   tag="foo"
   #maxup=""
   #maxdl=""
   #new_category="test" 
   #seedtime="03:20:10" 
   #ratio_limit=""
   #superseed=""
   #atm=""
   #seqdl=""
   apply_settings
   finished
fi

#Tip:Copy if statement above, and edit to define more trackers. (with "fi")
##[End of Defined Trackers]
#####
##[Public / Private]
# if no defined tracker(s) above found. Use Private/Public settings below.
#####
# Tracker found in your list but not a Defined tracker. [Private] 
if [ "$found_tracker" != "" ]; then
   dg.print "  -Private tracker found:[""$found_tracker""][Private]" 
   tag="Private" # Set Tag in qBittorrent
   #maxup=""
   #maxdl=""
   #seedtime="04:00:00"
   #ratio_limit=""
fi

#No tracker found in list or Defined trackers.[Public]
if [ "$found_tracker" == "" ]; then
   dg.print "  -Private tracker not found using:[Public]"
   tag="Public"
   #maxup=""
   #maxdl=""
   #seedtime=""
   #ratio_limit=""
fi
apply_settings
finished
##[End]
