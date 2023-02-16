#!/bin/bash
############################
# Author: Creptic :: 02/16/23 v0.95
# Source: https://github.com/creptic/qbt-onadd
# Purpose: Change settings to a single torrent in qBittorrent with qbittorrent-cli.
#         - Run in terminal or as a external add path for qBittorrent.  
#         - No effect to other torrents running, or global settings in qBittorrent.
#         - Change setting depending on private tracker(s) from a user string.
#	  - Add more trackers and/or categorys to a config file. Each with seperate settings.
#         - Defaults to public if no tracker found in string.
#         - If no tracker found, change tag in qBittorrent to 'Unknown' (can be customized)
#         - All unused or null variables will not change a setting.
#         - Set settings for user defined categories and trackers.
#         - Note: Seedtime does not show in qBittorent , use -t or -i to see current seedtime in terminal.
#         - Default config path is /home/user/.confg/qbt-onadd/settings.conf
# Requires: https://github.com/fedarovich/qbittorrent-cli
#         - qBittorrent server info needs to be set in qbittorrent-cli (see -h and -t).
#         - Add the path of this script with "%I" or "%I" "%L" arguement in  
#         - Run external program on torrent ADDED in your qBittorrent settings settings.
#         - Example: /home/foo/qbt-added.sh "%I,%L" 
# Usage:  ./qbt-onadd.sh <options> <torrent hash> <optional qBittorrent category)>
#         - See README or -h for help.
###################
###-=[Globals]=-###
###################
argu=$* # Needed to get arguments Do not remove
######
#Config is stored in /home/user/.config/qbt-onadd/settings.conf by default.
#Use -w /path/configname to write one if needed.
######
#If not set use default settings.conf above, or use -c (see -h)
config="" #If set and not found. script will exit (unless -c). (default="") 
######

#Functions:
function show_settings_qbittorrent_cli {
  #Display qbittorrent-cli settings and commands to auth with qbittorent : See (-t) in help
  #And test connection with qbittorrent-cli and qBittorrent server
  local t_con=""
  echo "-=[""$qbt_cli""]=-"
  echo "- May need to restart qBittorrent server if any info changed, and having issue connecting"
  $qbt_cli settings
  echo "-----"
  echo "- Use a command below to manually set qBittorrent server info in qbittorrent-cli "
  echo "- These can also be run with this script (-l <user>,-u <url>,or -p) [see help -h]"        
  echo "- URL:/path/to/qbittorrent-cli settings set url <url> (ex:http://localhost:8080)"
  echo "- User name:/path/to/qbittorrent-cli settings set username <username>"
  echo "- Password:/path/to/qbittorrent-cli settings set password [read and follow prompt]"
  echo "-----"
  echo -n " Checking Status: "
  local t_con=`$qbt_cli global info -F property:name="connection status"`
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
  $qbt_cli settings set password
  $qbt_cli settings
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
     $qbt_cli settings set url "$url"
     $qbt_cli settings
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
     $qbt_cli settings set username "$login"
     $qbt_cli settings
  fi
  exit 0
}

#Display info from qbittorrent-cli: See (-t) in help
function show_all_info_qbittorrent_cli {
  echo "Current Info for:["$hash"]"
  $qbt_cli torrent properties "$hash"
  $qbt_cli torrent share "$hash"
  $qbt_cli torrent options "$hash"
  local t_name=`$qbt_cli torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
  echo "Name:[""$t_name""]"
  exit 0
}

#Display seedtime info from qbittorrent-cli: See (-s) in help
function show_seedtime_info_qbittorrent_cli {
  #Get torrent name from qbittorrent-cli 
  local s_time=`$qbt_cli torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
  echo "Name:[""$s_time""]"
  $qbt_cli torrent share "$hash"
  exit 0
}  

### Change setting(s) in qbittorrent-cli functions
function change_max_upload () {
  local t_maxup="$1" ; local to_bytes=""
  if [ "$t_maxup" != "" ]; then
     local to_bytes="$(( ${t_maxup%% *} * 1024))"
     if [ "$dry_run" != "1" ]; then
       `$qbt_cli torrent limit upload -s "$to_bytes" "$hash"`
     fi
     dg.print "  -Setting max upload speed:[""$t_maxup"" KB]" "(""$to_bytes"" Bytes/s) 0=Unlimited"
   else
     dg.print "  -Max upload speed not set:[""$t_maxup""]"
  fi
}

function change_max_download () {
  local t_maxdl="$1" ; local to_bytes=""
  if [ "$t_maxdl" != "" ]; then
     local to_bytes="$(( ${t_maxdl%% *} * 1024))"
     if [ "$dry_run" != "1" ]; then
       `$qbt_cli torrent limit download -s "$to_bytes" "$hash"`
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
        `$qbt_cli torrent tags add "$hash" "$t_tag"` 
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
        `$qbt_cli torrent share -t "$t_seedtime" "$hash"`   
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
        `$qbt_cli torrent share -r "$t_ratio_limit" "$hash"`
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
        `$qbt_cli torrent options -a "$t_atm" "$hash"`
     fi
     dg.print "  -Setting Automatic Torrent Managment:[""$t_atm""] (0=OFF:1=ON)"
  fi
}

function change_superseed () {
 local t_superseed="$1"
  if [ "$t_superseed" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt_cli torrent options -z "$t_superseed" "$hash"`
     fi
     dg.print "  -Setting superseed :[""$t_superseed""] (0=OFF:1=ON)"
  fi
}

function change_seqdl () {
  local t_seqdl="$1"
  if [ "$t_seqdl" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt_cli torrent options -z "$t_seqdl" "$hash"`
     fi
     dg.print "  -Setting sequential download :[""$t_seqdl""] (0=OFF:1=ON)"
  fi
}

function change_category () {   
  local t_new_category="$1"
  if [ "$t_new_category" != "" ]; then
     if [ "$dry_run" != "1" ]; then
        `$qbt_cli torrent category --set "$t_new_category" "$hash"`
     fi
     dg.print "  -Changing category:[""$t_new_category""] (Category must already exist in qBittorrent)"
  fi
}

function apply_settings {
  #Apply all global values set below. Null values are not set.
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
  found_tracker="" ; local x="" ; local i=""
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
  dg.print "  -Getting tracker info from:[""$qbt_cli""]"
  #Get tracker(s) and store in list (comma seperated)
  tracker=`$qbt_cli torrent tracker list -F csv "$hash" | grep ":" | cut -d ":" -f1,2 | tr -s "\n" ","`
  local num_track=`(echo "$tracker" | grep -o "," | wc -l)`
  if [ "$tracker" == "" ];then 
     tracker="Unknown" 
  else
    #Remove last "," if one is found for a clean list
    local last_chr="${tracker:(-1)}" 
    if [ "$last_chr" == "," ]; then tracker="${tracker::-1}" ; fi
    dg.print "  -Torrent trackers (""$num_track""):[""$tracker""]"
  fi
}

# Error checking functions
function hash_check {
  #Checks if length of hash is 40 (trapping possible problems)
  #Skip this check if skip_hash_check is "1"
  if [ "$skip_hash_check" != "1" ]; then
     #Just checking the length not hexdigits.
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
  #Check qbittorrent-cli path
  local is_silent="$1"
  if [ "$is_silent" != "silent" ]; then 
     if [ "$log_level" -ge "1" ]; then
        dg.print "  -Checking for qbittorrent-cli:[""$qbt_cli""]"
     fi     
  else
     if [ ! -f "$qbt_cli" ]; then
        dg.print "Error with qbittorrent-cli path:[""$qbt_cli""] .. exiting [set path in "$config"]"
        exit 1
     fi
  fi
}

function check_connection {
  #Checks and displays connection status with qbittorrent-cli and qBittorrent
  local t_con=`$qbt_cli global info -F property:name="connection status"`
  if [ "$t_con" != "" ]; then 
        dg.print "  -Checking connection:[""$t_con""]" 
  else
     dg.print " -Checking connection:[Failed] ... exiting"
     exit 1 
  fi
}

function check_for_wait_time {
  #Sleep defined time if setting is set (wait_time) 
  #Check if wait_time is not 0 or "" 
  #if useing dry run optionally skip (skip_wait_dryrun)
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
  #Test if log file exists and +rw
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
  #Exit 0
  dg.print "-=[***[Finished]***]=-"
  #Uncomment to see all values and settings set [Debug]
  #show_defined_settings
  #show_settings
  
  exit 0
}

function get_name_qbittorrent_cli {
  #Global torrent_name change if found. null ("") if not found. 
  local torrent_name=""
  torrent_name=`$qbt_cli torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
  dg.print "  -Getting torrent name:[""$torrent_name""]"
}

function init_logging {
  if [ "$log_level" != "0" ];then
     if [ "$log_level" == "2" ]; then 
        local time_stamp=`date +%Y-%m-%d_%H-%M-%S`
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
# - no getopts used
function check_cmdline { 
 # -w and -c are processed in check_for_config_cmdline function first
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
  echo "  -c [/path/config] [OPTION] .. HASH .. [CATEGORY]" 
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
  echo "  -w [path/filename] # Write a default config file to specified path/name" 
  echo "  -h # Display this Help and exit"
  echo " -----------------------------------------------"
  exit 1
}

#### Config functions

function check_for_config_cmdline {
  #Check if -c or -w was used
  local a=($argu) 
  local first_arg="${a[@]:0:1}"
  local second_arg="${a[@]:1:1}" 
  local third_arg="${a[@]:2:1}"
  local fswitch=${argu:0:1}
  local chk_switch=${argu:0:2}

   if [ "$fswitch" == "-" ]; then  
     if [ "$chk_switch" == "-w" ]; then 
         if [ "$second_arg" == "" ]; then echo "No file specified ... exiting";exit 1;fi 
            echo -n " Writting config file to:[""$second_arg""]"
         if [ "$second_arg" == "." ]; then 
            echo -n " [FAILED]" ; echo "" ; exit 1          
          else 
             write_default_conf  "$second_arg"
          fi
          if [ -r "$second_arg" ] ; then 
             echo -n " [OK]" ; echo "" ; exit 0 
          else 
             echo -n " [FAILED]" ; echo "" ; exit 1
          fi 
     fi     
     if [ "$chk_switch" == "-c" ]; then 
        local fourth_arg="${a[@]:3:1}" 
        local fifth_arg="${a[@]:4:1}"
        #set config file to second arguement
        config="$second_arg"
        #move arguements down 2 places.
        argu=""$third_arg" "$fourth_arg" "$fifth_arg""
     fi
  fi
}



function check_for_config {
  #Global config
  #Get config. If it don't exist check permissions and try to create dir/config
  local theuser=`(whoami)`
  #Using ~/.config/qbt-onadd/settings.conf
  local base_config="/home/""$theuser""/.config"
  local config_dir="$base_config""/qbt-onadd/"
  local config_file="$base_config""/qbt-onadd/settings.conf"
  local log="$config_dir""log.txt"
  
  check_for_config_cmdline
  if [ "$config" != "" ]; then 
     if [ ! -r "$config" ] ; then 
         echo " Error: Config file is not readable:[""$config""] .. exiting"                 
         exit 1
     fi 
  else 
     if [ -e "$config_file" ]; then 
        #Config found
        config="$config_file"
     else
        echo " ------ "
        echo " Config file does not exist, trying default directory:[""$config_file""]" 
        echo " Checking if directory exists and writable:[""$config_dir""]"         
        if [[ -d "$config_dir" && -w "$config_dir" ]];then 
           config="$config_file"
           #Global made_log used to set log path to this dir before writting.  
           made_log="$config_dir""log.txt"
           echo " Writing default config to:[""$config""] ml:""$made_log"
           write_default_conf "$config"
           echo " ------ "
        else
           if [[ -r "$base_config" && -w "$base_config" ]]; then 
              config="$config_file"
              echo " Creating default directory to:[""$config_dir""]"
              `mkdir "$config_dir"` 
              made_log="$config_dir""log.txt"
              echo " Writing default config to:[""$config""]"
              write_default_conf "$config"
              echo " Writing a blank log file to:[""$log""]"
              echo -n "" > "$log" 
              echo " ------ "
            else
              echo " Cannot create config in "$config_dir" permissions?"
              echo " ------ "
              exit 1
            fi
         fi
      fi
  fi
}


function get_value_conf {
  #Get value from config based on section and paramater
  #Returns value 
  local section="$1" ; local param="$2"
  local found=false ; local line=""
  while read line
  do
    [[ $found == false && "$line" != "[$section]" ]] &&  continue
    [[ $found == true && "${line:0:1}" = '[' ]] && break
    found=true
    [[ "${line%=*}" == "$param" ]] && { echo "${line#*=}" | tr -d '"' ; break; }
  done < "$config"
}

function get_settings_conf {
  #Get and set all settings from config
  local section="Settings"
  qbt_cli=$(get_value_conf "$section" "qbt_cli")
  private_trackers=$(get_value_conf "$section" "private_trackers")
  check_for_private_trackers=$(get_value_conf "$section" "check_for_private_trackers")
  log_level=$(get_value_conf "$section" "log_level")
  log_file=$(get_value_conf "$section" "log_file")
  log_clear=$(get_value_conf "$section" "log_clear")
  skip_wait_dryrun=$(get_value_conf "$section" "skip_wait_dryrun")
  skip_hash_check=$(get_value_conf "$section" "skip_hash_check")
  skip_name=$(get_value_conf "$section" "skip_name")
  run_connection_check=$(get_value_conf "$section" "run_connection_check")
  check_both=$(get_value_conf "$section" "check_both")
  wait_time=$(get_value_conf "$section" "wait_time")
}

function get_values_section_conf () {
  #Get and set all values depending on section passed
  local section="$1"
  echo "  -Getting values from:[""$section""]"
  maxup=$(get_value_conf "$section" "maxup")
  maxdl=$(get_value_conf "$section" "maxdl")   
  tag=$(get_value_conf "$section" "tag")
  new_category=$(get_value_conf "$section" "new_category")
  seedtime=$(get_value_conf "$section" "seedtime")
  ratio_limit=$(get_value_conf "$section" "ratio_limit")
  superseed=$(get_value_conf "$section" "superseed")
  atm=$(get_value_conf "$section" "atm")
  seqdl=$(get_value_conf "$section" "seqdl")
}

function section_to_list () {
  #Parse get section:name(s) and put in csv list
  local section_type="$1"
  local t_line="" ; local i=""
  local line="" local list_csv=""
  while read line 
  do
    t_line=$(echo "$line" | grep "$section_type" | grep "]") 
    if [ "$t_line" != "" ]; then 
       t_line=$(echo "$t_line" | cut -c2- | tr -d ']' | cut -d ":" -f2)
       if [ "$list_csv" == "" ] ; then 
          list_csv="$t_line" 
      else
          list_csv="$list_csv"",""$t_line"
      fi       
    fi
  done < "$config"
  echo "$list_csv" #returns list as csv string 
}

function process_categories {
  local cat_list=$(section_to_list "Category:")
  #Get Categories from conf (must be [Category:name] section in conf.
  #Check categories found. if found get the values from section and set
  for i in $(echo $cat_list | tr ',' '\n') 
  do
    if [ "$category" == "$i" ];then
       dg.print "  -Defined Category found:[""$i""]"
       get_values_section_conf "Category:""$i"  
       category_found="1" #Category found flag to apply settings below if found. 
    fi
  done
}

function process_defined_trackers { 
  #Global defined_found used (1=Yes:0:NO)
  local track_list=$(section_to_list "Tracker:")
  #Get tracker(s) from conf (must be [Tracker:name] section in conf.
  #Get tracker_name from config and compare found private tracker to (t_url)
  #Check tracker(s) found. if found get the values from section and set
  for i in $(echo $track_list | tr ',' '\n') 
  do
    t_url=$(get_value_conf "Tracker:""$i" "tracker_name")    
    if [ "$found_tracker" == "$t_url" ];then
       dg.print "  -Defined Tracker found:[""$t_url""]"
       get_values_section_conf "Tracker:""$i"  
       defined_found="1" 
    fi
  done
}

function process_unknown_tracker {
  #When called. sets all values in [Unknown] section and exits
  dg.print "  -Empty tracker info returned from qBitorrent-cli:[Unknown]"
  get_values_section_conf "Unknown"
  finished
}

function write_default_conf {
   #Write config to passed path
   local config_path="$1" 
   echo "######################################" > "$config_path"
   echo "# Blank or unused values = No change #" >> "$config_path"
   echo "# Upload and Download Speeds in KB/s #" >> "$config_path"
   echo "# Seedtime format Days:Hours:Minutes #" >> "$config_path"
   echo "# ------ "00:00:00" = No limit ------- #" >> "$config_path"
   echo "######################################" >> "$config_path"
   echo "[Settings]" >> "$config_path"
   echo "qbt_cli="""\"/usr/bin/qbt\""" >> "$config_path"
   echo "private_trackers="""\"http://foo.org\""" >> "$config_path"
   echo "check_for_private_trackers="""\"1\""" >> "$config_path"
   echo "log_level="""\"1\""" >> "$config_path"
   if [ "$made_log" == "" ]; then 
      echo "log_file="""\"/path/to/writable/logfile/\""" >> "$config_path"
   else
      echo "log_file="""\""$made_log"\""" >> "$config_path"
   fi
   echo "log_clear="""\"0\""" >> "$config_path"
   echo "skip_wait_dryrun="""\"1\""" >> "$config_path"
   echo "skip_hash_check="""\"0\""" >> "$config_path"
   echo "skip_name="""\"0\""" >> "$config_path"
   echo "run_connection_check="""\"0\""" >> "$config_path"
   echo "check_both="""\"0\""" >> "$config_path"
   echo "wait_time="""\"0\""" >> "$config_path"
   echo "[Unknown]" >> "$config_path"
   echo "tag="""\"Unknown\""" >> "$config_path"
   echo "[Public]" >> "$config_path"
   echo "tag="""\"Public\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "seedtime="""\"\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
   echo "[Private]" >> "$config_path"
   echo "tag="""\"Private\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "seedtime="""\"\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
   echo "[Category:test]" >> "$config_path"
   echo "tag="""\"test\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "seedtime="""\"00:00:01\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
   echo "[Tracker:Unique_name]" >> "$config_path"
   echo "tracker_name="""\"http://foo.org\""" >> "$config_path"
   echo "tag="""\"foo\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "seedtime="""\"03:00:00\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
}

function show_settings {
  #Shows all settings. [debug]
  echo "**[Settings]*********************************************"
  echo "qbt_cli path:[""$qbt_cli""]"
  echo "Private trackers:[""$private_trackers""]"
  echo "Check for priv trackers:[""$check_for_private_trackers""]"
  echo "log level:[""$log_level""]"
  echo "log file:[""$log_file""]"
  echo "log clear:[""$log_clear""]"
  echo "skip wait dryrun:[""$skip_wait_dryrun""]"
  echo "skip hash:[""$skip_hash_check""]"
  echo "skip name:[""$skip_name""]"
  echo "run connection check:[""$run_connection_check""]"
  echo "check both:[""$check_both""]"
  echo "wait time:[""$wait_time""]"
  echo "*********************************************************"
}

function show_defined_settings {
  #Shows current values when called [debug] 
  echo "**[Variables]********************************************"
  echo "maxup:[""$maxup""]"
  echo "maxdl:[""$maxdl""]"
  echo "tag:[""$tag""]"
  echo "new_category:[""$new_category""]"
  echo "seedtime:[""$seedtime""]"
  echo "ratio_limit:[""$ratio_limit""]"
  echo "superseed:[""$superseed""]"
  echo "atm:[""$atm""]"
  echo "seqdl:[""$seqdl""]"
  echo "*********************************************************"
}


#Intial startup
##########
check_for_config
get_settings_conf
check_cmdline
if [ "$log_level" == "2" ]; then 
   test_the_logfile 
fi 
init_logging # Start logging if set. 
check_for_qbittorrent-cli #Check if qbt-cli exists
if [ "$run_hash_check" == "1" ]; then 
   #Check hash tag len (skip_hash_check="1" to override) 
   hash_check 
fi 
dg.print "  -Arguments:[""$argu""]" 
dg.print "  -Hash:[""${hash}""]"
dg.print "  -Category:[""${category}""]"

# If run_connection_check="1" then check connection
if [ "$run_connection_check" == "1" ]; then 
   check_connection 
else 
   dg.print "  -Skipped connection check:[run_connection_check=0]" 
fi
#If wait_time is set wait the defined time in seconds [skips on dry run]
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
##[Categories]
process_categories
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
           #If new_category was set. change category to new category
             category="$new_category"
         fi  
         check_for_private_trackers="1" 
      fi 
   fi
fi
if [ "$check_for_private_trackers" == "1" ]; then
   get_trackers_qbittorrent_cli #Function to get tracker info from qbittorrent-cli
else 
   finished
fi
## [Unknown Tracker]
if [ "$tracker" == "Unknown" ];then process_unknown_tracker ;fi 
##[End of Unknown Tracker]

# Checking for tracker in private_trackers list (top)
check_for_private_tracker
#
#[Defined Trackers]
process_defined_trackers
if [ "$defined_found" == "1" ]; then 
   apply_settings
   finished
fi
##[End of Defined Trackers]
##[Public / Private]
# If no defined tracker(s) above found. Use Private/Public settings below.
if [ "$found_tracker" != "" ]; then
   dg.print "  -Private tracker found:[""$found_tracker""] [Private]" 
   get_values_section_conf "Private"  
else
   dg.print "  -Private tracker not found using:[Public]" 
   get_values_section_conf "Public"
fi
apply_settings
finished
##[End of Public / Private] 
