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
 
Give instructions on how to collaborate with your project.
> Maybe you want to write a quote in this part. 
> Should it encompass several lines?
> This is how you do it.
## Wiki
***
For more information visit the WIki page
Side information: To use the application in a special environment use ```lorem ipsum``` to start
