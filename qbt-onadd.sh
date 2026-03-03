#!/bin/bash
############################
# Author: Creptic :: 03/03/26 v1.00
# Source: https://github.com/creptic/qbt-onadd
# Purpose: Change settings to a single torrent in qBittorrent with qbtctl
#         - Run in terminal or as a external add path for qBittorrent.  
#         - No effect to other torrents running, or global settings in qBittorrent.
#         - Change setting depending on tracker(s) from a user string.
#	  - Add more trackers and/or categorys to a config file. Each with seperate settings.
#         - Defaults to public if no tracker found in string. (unless defined tracker found in config)
#         - If no tracker found, change tag in qBittorrent to 'Unknown' (can be customized)
#         - All unused or null variables will not change a setting.
#         - Set settings for user defined categories and trackers.
#         - Note: Seedtime does not show in qBittorent , use -t or -i to see current seedtime in terminal.
#         - Default config path is /home/user/.qbt-onadd/settings.conf
# Requires: https://github.com/creptic/qbtctl
#         - qBittorrent server info needs to be set in qbtctl (-i or --setup)
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
#Config is stored in /home/user/.qbt-onadd/settings.conf by default.
#Use -w /path/settings.conf to write one if needed.
######
#If not set use default settings.conf above, or use -c (see -h)
config="" #If set and not found. script will exit (unless -c). (default="") 
color="1" #Enable or disable color text in terminal (only applies to terminal)
######

#Functions:
function finished {
  #Exit 0
  dg.print "-=[***[Finished]***]=-"
  #Uncomment to see all values and settings set when finished [Debug]
 # show_defined_settings
 # show_settings
  exit 0
}

function colorize () {
  local orig_text="${*}"
  local left="[" ;  local color="[\e[32m"
  local right="]" ; local end_color="\e[0m]"
  local new_text="" ; local no_color="${orig_text:0:3}"
  if [ "$no_color" == "-=[" ]; then no_color="1" ; fi 
  if [ "$no_color" != "1" ]; then 
     new_text="${orig_text/"$left"/"$color"}" 
     new_text="${new_text/"$right"/"$end_color"}"
     left="(Invalid)" ; color="(\e[31m"Invalid"\e[0m)"
     new_text="${new_text/"$left"/"$color"}"    
     echo -e "$new_text" "\e[0m"
  else 
     echo "$orig_text" 
  fi
}

function dg.print () { 
  if [ "$log_level" == "1" ];then 
     if [ "$color" == "1" ];then 
        colorize "${*}" 
      else
        echo "${*}"
     fi 
  fi 
  if [ "$log_level" == "2" ];then echo "${*}" >> "$log_file" ;fi
}

function show_single_info_qbtctl {
  #Display info from qbtctl: See (-t) in help
  $qbtctl -h "$hash" -s
  exit 0
}

function show_torrent_list_qbtctl {
  #Display torrent list in qbtctl
  $qbtctl -a
  exit 0
} 

### Change setting(s) in qbtctl functions
function change_tag {
    local t_tag="$1"
    local old_tag
    old_tag="$($qbtctl -h "$hash" -gt)"

    # Combine old and new tags
    local combined="$t_tag"
    if [[ -n "$old_tag" && "$t_tag" != "$old_tag" ]]; then
        combined="$old_tag, $t_tag"
    fi

    # Deduplicate tags while preserving order
    local deduped=""
    local seen=""
    local tag=""
    local rest="$combined"

    while [[ -n "$rest" ]]; do
        # Extract first tag (up to first comma)
        if [[ "$rest" == *,* ]]; then
            tag="${rest%%,*}"
            rest="${rest#*,}"
        else
            tag="$rest"
            rest=""
        fi

        # Trim spaces
        tag="${tag#"${tag%%[![:space:]]*}"}"
        tag="${tag%"${tag##*[![:space:]]}"}"
        local tag_lower="${tag,,}"

        # Deduplicate
        if [[ "$seen" != *",$tag_lower,"* ]]; then
            if [[ -n "$deduped" ]]; then
                deduped="$deduped, $tag"
            else
                deduped="$tag"
            fi
            seen="$seen,$tag_lower,"
        fi
    done

    if [[ -n "$deduped" && "$dry_run" != "1" ]]; then
        dg.print "  -Setting tag(s): [$deduped]"
        $qbtctl -h "$hash" -st "$deduped"
    else
        if [[ "$dry_run" == "1" && -n "$deduped" ]]; then
            dg.print "  -Tag(s) not set: [$deduped]"
        fi
    fi
}
function change_max_upload () {
  #Change Maximum Upload speed (KB/s)
  local t_maxup="$1"; local is_invalid="" 
  local is_num=$(echo "$t_maxup" | tr -d "[:digit:]") 
  if [ "$is_num" != "" ]; then is_invalid="(Invalid)" ; fi 
     if [[ "$t_maxup" != "" && "$dry_run" != "1" ]]; then
        if [ "$is_num" == "" ]; then 

            local t_text="(0=Unlimited)"
            if [ "$t_maxup" == "0" ]; then t_text="(Unlimited)" ;fi
            dg.print "  -Setting max upload speed:[""$t_maxup""] KB/s"  "$t_text"
           `$qbtctl -h "$hash" -sul "$t_maxup"`
        else
           dg.print "  -Max upload speed Invalid not set:[""$t_maxup""] KB/s"  "$is_invalid"
        fi
     else
     if [[ "$dry_run" == "1" && "$t_maxup" != "" ]]; then 
        dg.print "  -Max download speed not set:[""$t_maxup""] KB/s"  "$is_invalid" 
     fi
  fi 
}

function change_max_download () {
  #Change Maximum Download speed (KB/s)
  local t_maxdl="$1"; local is_invalid="" 
  local is_num=$(echo "$t_maxdl" | tr -d "[:digit:]") 
  if [ "$is_num" != "" ]; then is_invalid="(Invalid)" ; fi 
     if [[ "$t_maxdl" != "" && "$dry_run" != "1" ]]; then
        if [ "$is_num" == "" ]; then 
            local t_text="(0=Unlimited)"
            if [ "$t_maxdl" == "0" ]; then t_text="(Unlimited)" ;fi 
            dg.print "  -Setting max download speed:[""$t_maxdl""] KB/s"  "$t_text" 
           `$qbtctl -h "$hash" -sdl "$t_maxdl"`
        else
           dg.print "  -Max download speed Invalid not set:[""$t_maxdl""] KB/s"  "$is_invalid"
        fi
     else
     if [[ "$dry_run" == "1" && "$t_maxdl" != "" ]]; then 
        dg.print "  -Max download speed not set:[""$t_maxdl""] KB/s"  "$is_invalid" 
     fi
  fi 
}

function change_seedtime () {
  #Change Seedtime (ex:01:02:03)
  local t_seedtime="$1" ; local days=${t_seedtime::2} 
  local hrs=${t_seedtime:3:2} ; local mins=${t_seedtime:6:2}
  local is_invalid=""
  #Get length (should be 8)
  local t_len="${#t_seedtime}"
  #Remove colon and all numbers (should be "")
  local t_digits=$(echo "$t_seedtime" | tr -d ":" | tr -d "[:digit:]") 
  #Count number of colons (should be 2")
  local t_ccount=$(echo "$t_seedtime" | tr -cd ':' | wc -c)     
  if [ "$t_seedtime" != "" ]; then 
     if [ "$t_len" != "8" ]; then is_invalid="(Invalid)" ;fi
     if [ "$t_ccount" != "2" ]; then is_invalid="(Invalid)" ;fi
     if [ "$t_digits" != "" ]; then is_invalid="(Invalid)" ;fi
  fi     
  if [[ "$t_seedtime" != "" && "$dry_run" != "1" ]]; then
     if [ "$is_invalid" == "" ]; then 
        local t_text="("$days" "Days:" "$hrs" "Hours:" "$mins" "Minutes")"
        if [ "$t_seedtime" == "00:00:00" ];then t_text="(Unlimited)" ;fi
        dg.print "  -Setting seedtime:[""$t_seedtime""]" "$t_text"
        `$qbtctl -h "$hash" -sst "$t_seedtime"`
     else 
        dg.print "  -Seedtime Invalid not set:[""$t_seedtime""] (ex:01:02:03)" "$is_invalid"   
     fi
   else
     if [[ "$dry_run" == "1" && "$t_seedtime" != "" ]]; then 
        dg.print "  -Seedtime not set:[""$t_seedtime""] (ex:01:02:03)" "$is_invalid" 
     fi
  fi
}

function change_ratio_limit () {
  #Change Ratio Limit
  local t_ratio_limit="$1"
  local is_num=$(echo "$t_ratio_limit" | tr -d "[:digit:]")

     if [[ "$t_ratio_limit" != "" && "$dry_run" != "1" ]]; then
        if [ "$is_num" == "" ] || [ "$is_num" == "." ]; then
           `$qbtctl -h "$hash" -srl "$t_ratio_limit"`
           dg.print "  -Setting ratio limit:[""$t_ratio_limit""]"
        else
           dg.print "  -Ratio Limit Invalid not set:[""$t_ratio_limit""]"
        fi
     else
     if [[ "$dry_run" == "1" && "$t_ratio_limit" != "" ]]; then 
        dg.print "  -Ratio limit not set:[""$t_ratio_limit""]"
     fi
  fi
}

function change_category () {   
 #Change category
  local t_new_category="$1"
  if [[ "$t_new_category" != "" && "$dry_run" != "1" ]]; then
           dg.print "  -Changing category:[""$t_new_category""]"
          `$qbtctl -h "$hash" -sc "$t_new_category"`
   else
     if [[ "$dry_run" == "1" && "$t_new_category" != "" ]]; then
         dg.print "  -Category not set:[""$t_new_category""]"
     fi
   fi
}

function change_auto_torrent_managment () {
  #Change ATM (enable or disable) (0=OFF:1=ON)
  local t_atm="$1" ;  local is_invalid=""
  if [[ "$t_atm" != "0" && "$t_atm" != "1" ]]; then is_invalid="(Invalid)" ;fi
  if [[ "$t_atm" != "" && "$dry_run" != "1" ]]; then
      if [ "$is_invalid" == "" ]; then 
         dg.print "  -Setting Automatic Torrent Managment:[""$t_atm""] (0=OFF:1=ON)"
         `$qbtctl -h "$hash" -sat "$t_atm"`
      else
         dg.print "  -Automatic Torrent Managment setting is Invalid. Not set :[""$t_atm""] (0=OFF:1=ON)" "$is_invalid"
      fi 
   else
     if [[ "$dry_run" == "1" && "$t_atm" != "" ]]; then 
         dg.print "  -Automatic Torrent Managment not set:[""$t_atm""] (0=OFF:1=ON)" "$is_invalid" 
     fi
  fi 
}

function change_superseed () {
  #Change Superseeding (enable or disable) (0=OFF:1=ON)
  local t_superseed="$1" ; local is_invalid=""
  if [[ "$t_superseed" != "0" && "$t_superseed" != "1" ]]; then is_invalid="(Invalid)" ;fi
  if [[ "$t_superseed" != "" && "$dry_run" != "1" ]]; then
      if [ "$is_invalid" == "" ]; then 
         dg.print "  -Setting superseed:[""$t_superseed""] (0=OFF:1=ON)"
         `$qbtctl -h "$hash" -sss "$t_superseed"`
  else
         dg.print "  -Superseed setting is Invalid. Not set:[""$t_superseed""] (0=OFF:1=ON)" "$is_invalid"
      fi 
   else
     if [[ "$dry_run" == "1" && "$t_superseed" != "" ]]; then 
         dg.print "  -Superseeding not set:[""$t_superseed""] (0=OFF:1=ON)" "$is_invalid" 
     fi
  fi 
}

function change_seqdl () {
  #Change Sequential downloading (enable or disable)
  local t_seqdl="$1" ; local is_invalid=""
  if [[ "$t_seqdl" != "0" && "$t_seqdl" != "1" ]]; then is_invalid="(Invalid)" ;fi
  if [[ "$t_seqdl" != "" && "$dry_run" != "1" ]]; then
      if [ "$is_invalid" == "" ]; then
         dg.print "  -Setting sequential download:[""$t_seqdl""] (0=OFF:1=ON)"
         `$qbtctl -h "$hash" -ssd "$t_seqdl"`
   else
         dg.print "  -Sequential download setting is Invalid. Not set:[""$t_seqdl""] (0=OFF:1=ON)" "$is_invalid"
      fi 
   else
     if [[ "$dry_run" == "1" && "$t_seqdl" != "" ]]; then 
         dg.print "  -Sequential download not set:[""$t_seqdl""] (0=OFF:1=ON)" "$is_invalid" 
     fi 
  fi 
}

function apply_settings {
  #Apply all global values set below. Null values are not set.
  if [ "$dry_run" == "1" ]; then 
     dg.print "  -Using dry run:[Changes will not be applied]"
  fi
  dg.print "  -Applying settings to qBittorrent ..."
  change_tag "$tag" 
  change_max_upload "$maxup"
  change_max_download "$maxdl"
  change_seedtime "$seedtime"
  change_ratio_limit "$ratio_limit"
  change_category "$new_category"
  change_auto_torrent_managment "$atm"
  change_superseed "$superseed"
  change_seqdl "$seqdl"
}

## Tracker functions
function get_tracker_from_list () {
  #Set global found_tracker. if found, null ("") if not found. 
  #looks for same tracker in two csv strings
  list_defined="$1" ; list_qbt="$2"
  found_tracker="" ; local x="" ; local i=""
  if [[ "$list_defined" != "" && "$list_qbt" != "" ]]; then      
     for x in $(echo "$list_qbt" | tr ',' '\n') ;do
        for i in $(echo "$list_defined" | tr ',' '\n') ;do
           if [ "$i" == "$x" ]; then found_tracker="$i" ;fi 
        done
        if [ "$found_tracker" != "" ]; then break ; fi 
     done
  fi 
}

function get_trackers_qbtctl {
  dg.print "  -Getting tracker info from:[""$qbtctl""]"
  #Get tracker(s) and store in list (comma seperated)
  trackers_qbt=`$qbtctl -h "$hash" -gtl`
  local num_track=`(echo "$trackers_qbt" | grep -o "," | wc -l)`
  if [[ "$trackers_qbt" == "" || "$trackers_qbt" == ","  ]]; then 
     trackers_qbt="Unknown" 
  else
     #remove all trackers return without a : in value. remove first and last "," if needed
     local list="" ; local i=""
     local t_tracker=""
     for i in $(echo $trackers_qbt | tr ',' '\n') ;do
         t_tracker=$(echo "$i" | grep ":" )
          if [ "$t_tracker" != ""  ];then list=""$list" "$t_tracker"" ;fi
     done
     trackers_qbt=$(echo "$list" | tr -s " " ",")
     #Remove last "," if one is found for a clean list
     #local last_chr="${trackers_qbt:(-1)}" 
     if [ "${trackers_qbt:(-1)}" == "," ]; then trackers_qbt="${trackers_qbt::-1}" ; fi
     #Do the same for first char
     if [ ${trackers_qbt:0:1} == "," ] ; then trackers_qbt="${trackers_qbt:1}" ; fi  
    dg.print "  -Torrent trackers (""$num_track""):[""$trackers_qbt""]"
  fi
}

function process_defined_trackers { 
  #Global defined_found used (1=Yes:0:NO)
  local i="" ; defined_found=""
  dg.print "  -Checking for defined trackers ..."
  local track_list=$(section_to_list "Tracker:")
  #Get tracker(s) from conf (must be [Tracker:name] section in conf.
  #Get tracker_name from config and compare found private tracker to (t_url)
  #Check tracker(s) found. if found get the values from section and set
  for i in $(echo $track_list | tr ',' '\n') 
  do
    t_url=$(get_value_conf "Tracker:""$i" "tracker_name")    
    get_tracker_from_list "$t_url" "$trackers_qbt" 
    if [ "$found_tracker" != "" ]; then 
       dg.print "  -Defined Tracker found:[""$t_url""]"
       get_values_section_conf "Tracker:""$i"  
    defined_found="$t_url" 
    fi
  done
}



# Error checking functions


function check_for_qbtctl () {
  #Check qbtctl path
  local is_silent="$1"
  if [ "$is_silent" != "silent" ]; then 
     if [ "$log_level" -ge "1" ]; then
        dg.print "  -Checking for qbtctl:[""$qbtctl""]"
     fi     
  else
     if [ ! -f "$qbtctl" ]; then
        dg.print "Error with qbtctl path:[""$qbtctl""] .. exiting [set path in "$config"]"
        exit 1
     fi
  fi
}


function check_for_wait_time {
  #Sleep defined time if setting is set (wait_time) 
  #Check if wait_time is not 0 or "" 
  #if useing dry run optionally skip (skip_wait_dryrun)
  if [[ "$wait_time" != "" &&  "$wait_time" != "0" ]] ;then 
     if [ "$dry_run" == "1" ]; then
        if [ "$skip_wait_dryrun" == "1" ]; then
           dg.print "  -Waiting:[""$wait_time"" seconds] [skip_wait_on_dryrun=1] ... skipping"
        else
           dg.print "  -Waiting:[""$wait_time""] seconds ..."    
           sleep "$wait_time" 
        fi
     else
         dg.print "  -Waiting:[""$wait_time""] seconds] ..."
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
        echo " - Error:Access Denied to logfile set in config"
        echo " - File:[""$log_file""]" 
        echo " - To disable logging to file, dont use -f or change log_level in script"  
        echo " - Switching logging to terminal. [log_level=1]" 
        echo " - Check the files permissions, and settings in "$config" (log_file)"
        echo "***********************************"
     else
        if [ "$log_clear" == "1" ];then `(echo -n "" > "$log_file")` ; fi
     fi    
  fi
}

#Processing Functions
function get_name_qbtctl {
  #Global torrent_name change if found. null ("") if not found. 
  torrent_name=""
  torrent_name=`$qbtctl -h $hash -gn`
  dg.print "  -Getting torrent name:[""$torrent_name""]"
}

function process_categories {
  local cat_list=$(section_to_list "Category:")
  #Get Categories from conf (must be [Category:name] section in conf.
  #Check categories found. if found get the values from section and set
  for i in $(echo $cat_list | tr ',' '\n') 
  do
    if [ "$category" == "$i" ];then
       dg.print "  -Category found:[""$i""]"
       get_values_section_conf "Category:""$i"  
       category_found="1" #Category found flag to apply settings below if found. 
       break ;
    fi
  done
}

function process_unknown_tracker {
  #When called. sets all values in [Unknown] section and exits
  dg.print "  -Empty tracker information from qbtctl :[Unknown]"
 
  #Check if no tracker found because bad hash was passed
  #check if the torrent name is empty or has a error message.
  if [ "$torrent_name" == "" ]; then 
     local t_name=`$qbtctl torrent content -F csv "$hash" | cut -d "," -f2 | tail -1`
     local chk_name=$(echo "$t_name" | cut -c1-24)
     if [ "$chk_name" == "No torrent matching hash" ]; then 
        dg.print "  -No torrent matching hash:[""$hash""] ... exiting"
      else
        get_values_section_conf "Unknown"
        apply_settings
     fi
     finished
  else
    local chk_name=$(echo "$torrent_name" | cut -c1-24)
    if [ "$chk_name" == "No torrent matching hash" ]; then 
        dg.print "  -No torrent matching hash:[""$hash""] ... exiting"
      else
        get_values_section_conf "Unknown"
        apply_settings
     fi
    finished
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
    	 log_level=1 ; show_help ;;
      -t)
         log_level=1 ; check_for_qbtctl "silent"
         show_torrent_list_qbtctl ;;
      -n)
         ## [override] No logging (log_level=0)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level=0
            if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi ;;
      -v)
         ## [override] log to terminal (verbose) (log_level=1)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level=1
           if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi ;;
      -f)
         ## [override] change log level to log to file (log_level=2)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level=2
            if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi ;;
      -d)
       ##Dry run
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1"  ; dry_run="1"
            if [ "$third_arg" != "" ];then category="$third_arg" ;fi
         fi ;;
      -i)
         if [ "$second_arg" == "" ]; then err_no_hash
         else
            hash="$second_arg" ; run_hash_check="1" ; log_level="1"
            check_for_qbtctl "silent"
            show_single_info_qbtctl
         fi  ;;
      **)
         if [ "$log_level" == "1" ];then 
            echo " Invalid arguement .. exiting"
            show_help
         else
            dg.print "Invalid arguent:[""$chk_switch""]" 
            exit 1
         fi ;;
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
  echo " OPTION and CATEGORY are optional. qbtctl required."
  echo " Options:"
  echo "  -c [/path/config] [OPTION] .. HASH .. [CATEGORY]" 
  echo "  -i [hash]  # Get full Information on a torrent and exit"
  echo "  -d [hash]  # Dry run. Run without changing settings"
  echo "  -n [hash]  # Do Not log (log_level=0) [override] (No info to terminal)"
  echo "  -v [hash]  # Log to terminal (Verbose) (log_level=1) [override]"
  echo "  -f [hash]  # Log to File (log_level=2) [override]"
  echo "  -w [path/filename] # Write a default config file to specified path/name" 
  echo "  -t # Show torrent list (Useful to get a torrent's hash)"
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
        if [ "$second_arg" == "" ]; then 
           echo "No path to config file entered ... exiting" ;exit 1 
        fi
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
  local base_config="/home/""$theuser"""
  local config_dir="$base_config""/.qbt-onadd/"
  local config_file="$base_config""/.qbt-onadd/settings.conf"
  local log="$config_dir""log.txt"
  
  check_for_config_cmdline
  if [ "$config" != "" ]; then 
     if [ ! -r "$config" ] ; then 
         echo " Error: Config file is not readable:[""$config""] ... exiting"                 
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
           echo " Writing default config to:[""$config""] ml:""$made_log"
           write_default_conf "$config"
           echo " ------ "
        else
           if [[ -r "$base_config" && -w "$base_config" ]]; then 
              config="$config_file"
              echo " Creating default directory to:[""$config_dir""]"
              `mkdir "$config_dir"` 
              created_log="$config_dir""log.txt"
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

function get_value_conf () {
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
  qbtctl=$(get_value_conf "$section" "qbtctl")
  trackers_conf=$(get_value_conf "$section" "trackers")
  check_for_trackers=$(get_value_conf "$section" "check_for_trackers")
  defined_trackers_only=$(get_value_conf "$section" "defined_trackers_only")
  wait_time=$(get_value_conf "$section" "wait_time")
  log_level=$(get_value_conf "$section" "log_level")
  log_file=$(get_value_conf "$section" "log_file")
  log_clear=$(get_value_conf "$section" "log_clear")
  skip_wait_dryrun=$(get_value_conf "$section" "skip_wait_dryrun")
  skip_name=$(get_value_conf "$section" "skip_name")
  check_trackers_if_category_found=$(get_value_conf "$section" "check_trackers_if_category_found")  
}

function get_values_section_conf () {
  #Get and set all values depending on section passed
  local section="$1"
  dg.print "  -Getting values from:[""$section""]"
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

function write_default_conf () {
   #Write config to passed path
   local config_path="$1" 
   echo "######################################" > "$config_path"
   echo "# Blank or unused values = No change #" >> "$config_path"
   echo "# Upload and Download Speeds in KB/s #" >> "$config_path"
   echo "# Seedtime format Days:Hours:Minutes #" >> "$config_path"
   echo "# "00:00:00" = No limit | 0=OFF:1=ON #" >> "$config_path"
   echo "######################################" >> "$config_path"
   echo "[Settings]" >> "$config_path"
   echo "qbtctl="""\"/usr/bin/qbtctl\""" >> "$config_path"
   echo "trackers="""\"http://foo.org\""" >> "$config_path"
   echo "check_for_trackers="""\"1\""" >> "$config_path"
   echo "defined_trackers_only="""\"0\""" >> "$config_path"
   echo "wait_time="""\"0\""" >> "$config_path"
   echo "log_level="""\"1\""" >> "$config_path"
   if [ "$created_log" == "" ]; then 
      echo "log_file="""\"/path/to/writable/logfile/\""" >> "$config_path"
   else
      echo "log_file="""\""$created_log"\""" >> "$config_path"
   fi
   echo "log_clear="""\"0\""" >> "$config_path"
   echo "skip_wait_dryrun="""\"1\""" >> "$config_path"
   echo "skip_name="""\"0\""" >> "$config_path"
   echo "check_trackers_if_category_found="""\"0\""" >> "$config_path"
   echo "[Unknown]" >> "$config_path"
   echo "tag="""\"Unknown\""" >> "$config_path"
   echo "[Public]" >> "$config_path"
   echo "tag="""\"Public\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "seedtime="""\"\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
   echo "[Private]" >> "$config_path"
   echo "tag="""\"Private\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "seedtime="""\"\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
   echo "[Category:test]" >> "$config_path"
   echo "tag="""\"test\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "seedtime="""\"00:00:14\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
   echo "[Tracker:Unique_name]" >> "$config_path"
   echo "tracker_name="""\"http://bar.org\""" >> "$config_path"
   echo "tag="""\"Defined\""" >> "$config_path"
   echo "maxup="""\"\""" >> "$config_path"
   echo "maxdl="""\"\""" >> "$config_path"
   echo "seedtime="""\"03:00:00\""" >> "$config_path"
   echo "ratio_limit="""\"\""" >> "$config_path"
   echo "new_category="""\"\""" >> "$config_path"
   echo "atm="""\"\""" >> "$config_path"
   echo "superseed="""\"\""" >> "$config_path"
   echo "seqdl="""\"\""" >> "$config_path"
}

function show_settings {
  #Shows all settings. [debug]
  echo "**[Settings]*********************************************"
  echo "qbtctl path:[""$qbtctl""]"
  echo "tracker List:[""$trackers_conf""]"
  echo "check trackers:[""$check_for_trackers""]"
  echo "defined trackers only:[""$defined_trackers_only""]"
  echo "wait time:[""$wait_time""]"
  echo "log level:[""$log_level""]"
  echo "log file:[""$log_file""]"
  echo "log clear:[""$log_clear""]"
  echo "skip wait dryrun:[""$skip_wait_dryrun""]"
  echo "skip name:[""$skip_name""]"
  echo "check trackers if category found:[""$check_trackers_if_category_found""]"
  echo "torrent_name:[""$torrent_name""]"
  echo "*********************************************************"
}

function show_defined_settings {
  #Shows current values when called [debug] 
  echo "**[Variables]********************************************"
  echo "tag:[""$tag""]"
  echo "maxup:[""$maxup""]"
  echo "maxdl:[""$maxdl""]"
  echo "seedtime:[""$seedtime""]"
  echo "ratio_limit:[""$ratio_limit""]"
  echo "new_category:[""$new_category""]"
  echo "atm:[""$atm""]"
  echo "superseed:[""$superseed""]"
  echo "seqdl:[""$seqdl""]"
  echo "*********************************************************"
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

#Intial startup
check_for_config #Check for config
get_settings_conf #Get settings from config
check_cmdline #Check commandline

if [ "$log_level" == "2" ]; then 
   test_the_logfile #Check if logfile exists and is readable
fi 

init_logging # Start logging if set. 
check_for_qbtctl #Check if qbt-cli exists
#If wait_time is set wait the defined time in seconds [optional skip on dry run]
check_for_wait_time

dg.print "  -Arguments:[""$argu""]" 
dg.print "  -Hash:[""${hash}""]"
dg.print "  -Category:[""${category}""]"

 #If skip_name is set then dont show name. if log_level is 0 no need to show name
if [ "$skip_name" != "1" ]; then 
   if [ "$log_level" != "0" ]; then get_name_qbtctl ;fi
   else 
   dg.print "  -Skipped getting name:[skip_name=1]"
fi

#########
# Begin #
#########
##[Categories]
dg.print "  -Checking for matching category ..."
process_categories
##[End of Categories] 
#---
## If category was found and not checking trackers, apply settings and exit. 
if [ "$category_found" == "1" ]; then 
   if [ "$check_trackers_if_category_found" != "1" ]; then
      apply_settings
      finished
   else
      if [ "$check_trackers_if_category_found" == "1" ]; then 
         dg.print "  -Category found and checking for trackers:[check_trackers_if_category_found=1]"
         #Apply settings here, or they change when checking tracker (getting section data)
         apply_settings
         check_for_trackers="1" 
      fi 
   fi
fi

if [ "$check_for_trackers" == "1" ]; then
   get_trackers_qbtctl #Function to get tracker info from qbtctl
else 
   dg.print "  -Skipped checking for trackers:[check_for_trackers=0]"
   finished
fi
## [Unknown Tracker]
if [ "$trackers_qbt" == "Unknown" ];then process_unknown_tracker ;fi 
##[End of Unknown Tracker]

#[Defined Trackers]
process_defined_trackers
if [ "$defined_found" != "" ]; then 
   apply_settings
   finished
fi
##[End of Defined Trackers]
##[Public / Private]
if [ "$defined_trackers_only" == "1" ]; then 
   dg.print "  -Skipped checking for private trackers:[defined_trackers_only=1]"
   finished
fi
dg.print "  -Checking for private trackers:[""$trackers_conf""]"
get_tracker_from_list "$trackers_conf" "$trackers_qbt"
# If no defined tracker(s) above found. Use Private/Public settings below.
# If tracker found in tracker list set to [Private] if not found use [Public]
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
