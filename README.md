# qbt-onadd 
 - Sets custom settings to a single torrent in qBittorent, when added or run manually.
 - Does not effect other settings or torrents in qBittorrent. No cron required.
 - Change tag name, speed and ratio limits, seeding time limit, and category (must exist).
 - Customize values depending on category(s) and/or user defined tracker(s). 
 - Customize settings depending on private, public or unknown (no tracker info found) tracker(s).
 - Options and settings are edited directly in a config file. Uses qBittorrent setting for empty values.  
 - Command line options including dry run and log level overrides.
 - Add custom categorys and trackers based tracker list or specified tracker url. 
 - Each category or tracker can have its own settings. All customization can be done in config.  
 - Logging can be set to none, console (terminal), or file (must be writable). Useful for testing.
 - Minimal version available with example code (removed cmdline,logging,error checking and config).  
 - Run from terminal, or add to qBittorrent External Add path.
***
## Requirements:
- https://github.com/fedarovich/qbittorrent-cli  also available in [AUR](https://aur.archlinux.org/packages/qbittorrent-cli)
- qBittorent server info can be set manully in qbittorrent-cli or via script. (See [Installation](#installation))    
- qbittorrent-cli also runs in powershell. This script has not been tested in powershell yet. 
***
## Basic Usage:
- Teminal: (category is optional)
```
 $ ./path/qbt-onadd.sh/ torrent_hash category 
```
Note: torrent_hash must be 40 characters in length, or change skip_hash_check="1" setting in config.
- qBittorrent
  add ```/path/qbt-onadd.sh "%T" "%L"``` to External Add path in qBittorent to run when a torrent is added.
***
## Table of Contents
1. [General Info](#general-info)
2. [Installation](#installation)
3. [How it Works](#how-it-works)
4. [Usage](#usage)
5. [Wiki](#wiki)
***
## General Info
&nbsp; &nbsp;Helper script for qbittorrent-cli, run manually or use for changing settings on a added torrent in qBittorrent.

&nbsp; &nbsp;&nbsp; &nbsp; This script is for users who want to control a torrent. If you are into automating your torrents, this
script may be of use. General uses are setting limits to torrents you add based on category or tracker. You
may want to add a tag, or change category name to a torrent to use when torrent is completed. Adding or editting
your trackers,categorys and settings are easily done in one config. If you need to authenticate with qBittorrent
you can set manually or by using a commandline arguement (see Usage below) <br /> <br />
&nbsp; &nbsp;&nbsp; &nbsp; Besides tagging and using categorys to sort your torrents, you may also want to set options individually. All
that can be done by editing or adding section(s) in the config file. Settings include speeds, seedtimes and ratio
limit. Other options like ATM and sequential downloading can be enabled or disabled. 

***
## Installation 
Download qbt-onadd.sh or use git clone. 
```
$ cd ../path/to/qbt-onadd.sh
$ chmod +x qbt-onadd.sh
```
Note: If you are using the minimal version in extras folder, use ```` qbt-onadd-minimal.sh ```` 
***
## How it works
- When a torrent is added, and the 'External Add' path is set with /path/to/qbt-onadd.sh "%T" "%L" <br />
- Or qbt-onadd is run in terminal with <args> <torrent_hash> <category> (category and args are optional) <br /> 
***
#### Category: 
&nbsp; &nbsp;&nbsp; &nbsp; Script looks for a matching category in your configuration file [Category:NAME]. If the category you used, when you added torrent matches "NAME" then it will set setting(s) from that section in config. The script will then exit (unless check_both="1" in config). Commented out or null ("") values makes no change to the value. Checking by category requires "%L" <br /> <br/>
Note: Add more sections to add more category checks, and set values. The order of values in section dont matter. <br />
***
#### Trackers:
In order to check trackers check_for_private_trackers="1" must be set in config settings. <br />
- Needs least one tracker url in the list (only up to port). Comma seperated.  <br /> 
- Example: ```private_tracker="https<nolink>://tracker.com,http://<nolink>noport.net"``` <br />
- If you are adding a Defined; ```tracker_name="http://<nolink>noport.net"``` also needs to be in the [Defined:NAME] section.

 There are four types of trackers:
 1. Defined: A tracker that was found in config [Tracker:NAME]. This requires tracker_name="url" to be set
 2. Private: Tracker that was found in private_tracker list ([Settings] in config)
 3. Public: Tracker that was not found in list, and tracker(s) from qbittorent-cli was not empty.
 4. Unknown: No tracker was returned from qbittorrent-cli (Changes tag to "Unknown" and exits)

***
### Settings (settings.conf):
| Name | Value (empty=no change) | Description  |
| :---:   | :---: | :---: |
| qbt_cli | "string" 	| Path to qbittorrent-cli (ex:"/usr/bin/qbt"). Required |
| trackers | "string" | List of comma separated trackers. (ex: "https<nolink>://tracker.com,https<nolink>://tracker2.com").No : or port |
| check_for_trackers | "1" (other=no)| Enable to check for trackers, either defined ones or by tracker list |
| defined_trackers_only | "1" (other=no) | Check defined trackers only, when checking trackers (Category is still checked) |
| wait_time | "number" | Time to wait (sleep) in seconds |
| log_level | "1" or "2" (other=none) | "1" : Output to terminal (console) <br /> "2" : Output to file (see log_file) |
| log_file | "string" | Path to log file (ex."/home/user/.config/qbt-onadd/log.txt) (see log_level) |
| log_clear | "1" (other=no) | Show only one entry in log. Clears the log every time run |
| skip_wait_dryrun | "1" (other=no) | Skips the wait_time if set, when doing a dry-run |
| skip_hash_check | "1" (other=no) | Skips the hash check. Hash check searches running torrents for a match |
| skip_name | "1" (other=no) | Skips getting the name of the torrent |
| connection_check | "1" (other=no) | Enable to do a connection check |
| check_trackers_if_category_found | "1" (other=no) | If category is found it will apply settings, and check both defined and tracker list |

### Variables:
| Name | Value (empty=no change) | Description (effects the torrent only) |
| :---:   | :---: | :---: |
| tag | "string"    | Adds tag (blank spaces or , create multiple tags) |
| maxup | "number"   | Maximum upload speed in KB/s (0=Unlimited) |
| maxdl | "number"   | Maximum download speed in KB/s (0=Unlimited)|
| seedtime | "00:00:00"   | Seedtime [DD:HH:MM] (00:00:00=Unlimited) |
| ratio_limit | "number"   | The torrents ratio limit |
| new_category | "string"   | Change category name (creates if it dont exist) |
| atm | "0" or "1"   | Enable (1) or Disable(0) Automatic Torrent Management |
| superseed | "0" or "1" | Enable(1) or Disable(0) superseeding |
| seqdl | "0" or "1"   | Enable or Disable Sequential downloading |
***
 
 
Give instructions on how to collaborate with your project.
> Maybe you want to write a quote in this part. 
> Should it encompass several lines?
> This is how you do it.
## Wiki
***
For more information visit the WIki page
Side information: To use the application in a special environment use ```lorem ipsum``` to start


 
 
```mermaid
graph LR
A[Check for category] --> F{Found Category?}  
E[Check for Defined Tracker] 
D{Apply Settings}
F --> D
F --> G{Check Trackers?} --> E --> H{Found Defined?} --> D
H --> J{If defined only =0} --> K(Check tracker list) -->L{Found in list} --Private -->D 
D --> Exit 
J --> Exit
G --> Exit
L --Public --> D



