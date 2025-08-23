# qbt-onadd 
 - Sets custom settings to a single torrent in qBittorent server (webui), when added or run manually.
 - Does not effect global settings, or torrents in qBittorrent. No cron required.
 - Add tag(s), change upload and download speeds, ratio limit, seeding time, and /or category.
 - Customize values depending on category(s) ,defined tracker(s), or a list of trackers. 
 - Dry run and test before making changes. (see -d) 
 - Uses qBittorrent setting for empty values, so only change what you prefer. 
 - Command line options to help you easily authenticate with qBittorrent.  
 - Logging can be set to none(default), console (terminal), or file.(default=/home/user/.qbt-onadd/log.txt).
 - Additional options like ATM, Superseed, and Sequential download can be enabled/disabled.
 - All customization is done in config. No env variables, and no modifications to system.  
 - Optional Verbose output (or to log) do show you whats being done. 
 - Config file defaults to /home/user/.qbt-onadd/settings.conf
 - Config can be set with -c in command-line, or hard-coded in script.
 - You can write a default config with -w (see -h).  
 - Minimal version available with example code (removed cmdline,logging,error checking and config).  
 - Run from terminal, or add to qBittorrent External Add path in your qBittorrent webui or config.
***
## Requirements:
- https://github.com/fedarovich/qbittorrent-cli  also available in [AUR](https://aur.archlinux.org/packages/qbittorrent-cli) (tested with v1.8.24285.1)
- qBittorrent server info can be set manully in qbittorrent-cli or via script. (See [Setup and Testing](#setup-and-testing))    
- qBittorrent server (webui). Tested with qbittorrent-nox (qBittorrent v5.1.0)
***
## Basic Usage:
- Teminal: (category is optional)
```
 $ ./path/qbt-onadd.sh/ torrent_hash category 
```
Note: torrent_hash must be at least 6 characters in length. Change skip_hash_check="1" setting in config to skip.
- qBittorrent
  add ```/path/qbt-onadd.sh "%T" "%L"``` to External Add path in qBittorent to run when a torrent is added.
***
## Table of Contents
1. [General Info](#general-info)
2. [Installation](#installation)
3. [Setup and Testing](#setup-and-testing)
4. [Auto changing when torrent is added](#auto-changing-when-torrent-is-added)
5. [How it Works](#how-it-works)
6. [Usage](#usage)
***
## General Info:
&nbsp; &nbsp;Helper script for qbittorrent-cli, run manually or use for changing settings on a added torrent in qBittorrent.

&nbsp; &nbsp;&nbsp; &nbsp; This script is for users who want to control a torrent. If you are into automating your torrents, this
script may be of use. General uses are setting limits to torrents you add based on category or tracker. You
may want to add a tag, or change category name to a torrent to use when torrent is completed. Adding or editting
your trackers,categorys and settings are easily done in one config. If you need to authenticate with qBittorrent
you can set manually or by using a commandline arguement (see Usage below) <br /> <br />
&nbsp; &nbsp;&nbsp; &nbsp; Besides tagging and using categorys to sort your torrents, you may also want to set options individually. All
that can be done by editing or adding section(s) in the config file. Settings include speeds, seedtimes and ratio
limit. Other options like ATM, superseed and sequential downloading can be enabled or disabled. 

***
## Installation:
Download [qbt-onadd.sh](https://github.com/creptic/qbt-onadd/blob/main/qbt-onadd.sh) 

Or use git-clone: 
```
$ git clone https://github.com/creptic/qbt-onadd
$ cd qbt-onadd
$ chmod +x qbt-onadd.sh
```

Note: If you are using the minimal version in extras folder, use ```` qbt-onadd-minimal.sh ````
    - No settings.conf used with minimal version. the script must be edited.
***
## Setup and testing:
Required: 
- Running qBittorrent or qBittorrent-nox server .
- qbittorrent-cli installed

We have no tracker info in config. so lets start with testing a category.
When qbt-onadd.sh is first run, and no settings.conf found in ```` /home/user/.qbt-onadd/ ````  settings.conf and a empty file log.txt is created. 
* A copy settings.conf is in extras directory (github), or you can write one with -w 

If you want to use your own config path you have two options: 
1) Change the path in script. ```` config="/path/settings.conf" ````
3) Use the ```` qbt-onadd.sh -c /path/settings.conf ```` to point to the path of your config.

Lets get started <br />

&nbsp; &nbsp;&nbsp; &nbsp; First we need to add the path to qbittorrent-cli to the config file. The default path is /usr/bin/qbt). If this is the correct path you can skip this part. 
Open up the config file created (by default is ```` /home/user/.qbt-onadd/settings.conf```` ) . Change ```` qbt_cli="/path/to/qbittorrent-cli" ```` to the path to qbittorrent-cli, you installed earlier.  <br />

*** Note. If you are using a terminal and want to use dry run (-d) also set ```` log_level="1" ```` <br />

run ```` /path/qbt-onadd.sh -t  ```` 
This will show your server settings in qbittorrent-cli, as well as commands to manually change your information via terminal. You can also use qbt-onadd.sh -u -p or -l  to set. (see -h)

Once you are have to correct info set. 
run ```` /path/qbt-onadd.sh -z ```` to get a list of your torrents running. note the 6 character hash of a torrent.

Lets do a dry-run and see what would be set. (hash=the 6 char hash seen on -z) 

run ```` /path/qbt-onadd.sh -d hash test ```` 

```
$ [creptic@mc testing]$ ./qbt-onadd.sh -d aba9f0 test
$ -=[***[Started]***]=-
$   -Checking for qbittorrent-cli:[/usr/bin/qbt]
$   -Checking for matching hash:[aba9f0]
$   -Arguments:[-d aba9f0 test]
$   -Hash:[aba9f0]
$   -Category:[test]
$   -Skipped connection check:[connection_check=0]
$   -Skipped getting name:[skip_name=1]
$   -Checking for matching category ...
$   -Category found:[test]
$   -Getting values from:[Category:test]
$   -Using dry run:[Changes will not be applied]
$   -Applying settings to qBittorrent ...
$   -Tag(s) not set:[test]
$   -Seedtime not set:[00:00:14] (ex:01:02:03) 
$ -=[***[Finished]***]=-
```
run without the -d: 
run ```` /path/qbt-onadd.sh hash test ```` <br /> 
```
$   -Applying settings to qBittorrent ...
$   -Setting tag(s):[test]
$   -Setting seedtime:[00:00:14] (00 Days: 00 Hours: 14 Minutes)
$ -=[***[Finished]***]=-
```
**(shortend to not repeat output above)<br />

After finished you should see a new tag was made called test with a seedtime of 14 minutes. 

Finally 
run  ```` /path/qbt-onadd.sh -s hash ```` 

You should see the seedtime from the -d output. (14 minutes)

That's it. Now you seen how it works, below are a list of variables, settings and command line options.<br />

Customize the settings to your liking in the config you changed path in earlier.
***
## Auto changing when torrent is added:
&nbsp; &nbsp;&nbsp; &nbsp; Open your qBittorrent server (webui), go to options then downloads. At the bottom is a open called "Run external program". In  'Run external program on torrent added' add the the path with "%I" "%L". argument. "%I" is the torrents hash (v1). "%L" is the Category used (if any) when torrent was added. If you do not wish to use category checks simply use just "%I". Check the box, when you have are ready. Click the save button.

1) Example: ```` /home/user/qbt-onadd.sh "%I" "%L" ```` 
2) Example:```` /home/user/qbt-onadd.sh -f "%I" "%L" ````  (log to file specified in settings.conf) See commandline options below. (-f) <br />
***
## How it works:
- When a torrent is added, and the 'External Add' path is set with ```` /path/qbt-onadd.sh "%T" "%L" ````  in qBittorrent server (webui)<br />
- Or qbt-onadd.sh is run in terminal with <args> <torrent_hash> <category> (category and args are optional) <br /> 
-----
By default this script does the following in order:
1) Check for a Category match in settings.conf section [Category:Name] If found apply settings and exit. If not found continue to 2.
2) Check for a Defined  match in settings.conf section [Defined:Name]. Check the url in 'tracker_name' for a match. If found apply settings and exit. If not found continue to 3.
3) Check tracker(s) in 'trackers' list in [Settings]. If found then use settings from [Private] section. If not found use the settings from [Public].

By default, when one of these is found. It will only change the tag name to type found. For example when no tracker is found in list, it will change the torrents tag to "Public" Excluding the test category which sets the tag to "test" and seedtime for testing. New settings and or sections need to be added or edited depending on your needs.

* Note: if no tracker if found in step 2. it will use settings in [Unknown]. <br />
* Change name when adding new types. for example: [Category:Linux] will check for a category named Linux (case sensitive). You can do the same for [Defined:Trackername]. <br /> 
* When adding a defined you must add a url (ex:tracker_name="https<nolink>://tracker.org") to the section.

#### Category: 
&nbsp; &nbsp;&nbsp; &nbsp; Script looks for a matching category in your configuration file [Category:NAME]. If the category you used, when you added torrent matches "NAME" then it will set setting(s) from that section in config. The script will then exit (unless check_both="1" in config). Commented out or null ("") values makes no change to the value. 
Checking by category requires "%L" in qBittorrent, or passed in commandline. <br /> <br/>
Note: Add more sections to add more category checks, and set values. The order of values in section dont matter. <br />
***
#### Trackers:
In order to check trackers check_trackers="1" must be set in config settings. <br />
- Needs least one tracker url in the list (only up to port). Comma seperated.  <br /> 
- Example: ```tracker="http://tracker.net,http://noport.org"``` <br />
- If you are adding a Defined; ```tracker_name="http://noport.net"``` also needs to be in the [Defined:NAME] section.

 There are four types of trackers:
 1. Defined: A tracker that was found in config [Tracker:NAME]. This requires tracker_name to be set (ex:tracker_name="https<nolink>://tracker.org")
 2. Private: Tracker that was found in tracker list ([Settings] in config)
 3. Public: Tracker that was not found in list, and tracker(s) from qbittorent-cli was not empty.
 4. Unknown: No tracker was returned from qbittorrent-cli (Changes tag to "Unknown" and exits)
***
## Usage:
#### Command line options:
/path/script  {Argument} {Torrents Hash} {Category} (Optional)
| Argument | Description  |
| :---: | :---: |
| -c [/path/config] [OPTION] .. HASH .. [CATEGORY]" | Use alternate path to config file. Other arguments can still be used |
| -i [hash]  | Get full Information of a torrent and exit | 
| -s [hash]  | Show Seedtime and ratio limit info of a torrent and exit |
| -d [hash]  | Dry run. Run without changing settings |
| -n [hash]  | Do Not log (log_level=0) [override] <br /> (No output to terminal) |
| -v [hash]  | Log to terminal (Verbose) (log_level=1) [override] |
| -f [hash] | Log to File (log_level=2) [override] |
| -t | Test Connection. Show commands to manually set qBittorrent info in qbitorrent-cli |
| -p | Sets Password in qbittorrent-cli settings (Read prompt) |
| -u [url:port] | Sets qBittorent URL in qbittorrent-cli settings |
| -l [login] | Sets qBittorrent Login name in qbittorent-cli settings | 
| -w [path/filename] | Write a default config file to specified path/name | 
| -z | Show torrent list (Useful to get a torrent's hash) | 
| -h | Display this Help and exit"

#### Settings (settings.conf):
| Name | Value (empty=no change) | Description  |
| :---:   | :---: | :---: |
| qbt_cli | "string" 	| Path to qbittorrent-cli (ex:"/usr/bin/qbt"). Required |
| trackers | "string" | List of comma separated trackers. (ex: "https<nolink>://tracker.com,https<nolink>://tracker2.com").No : or port |
| check_for_trackers | "1" (other=no)| Enable to check for trackers, either defined ones or by tracker list |
| defined_trackers_only | "1" (other=no) | Check defined trackers only, when checking trackers (Category is still checked) |
| wait_time | "number" | Time to wait (sleep) in seconds |
| log_level | "1" or "2" (other=none) | "1" : Output to terminal (console) <br /> "2" : Output to file (see log_file) |
| log_file | "string" | Path to log file (ex."/home/user/.qbt-onadd/log.txt) (see log_level) |
| log_clear | "1" (other=no) | Show only one entry in log. Clears the log every time run |
| skip_wait_dryrun | "1" (other=no) | Skips the wait_time if set, when doing a dry-run |
| skip_hash_check | "1" (other=no) | Skips the hash check. Hash check searches running torrents for a match |
| skip_name | "1" (other=no) | Skips getting the name of the torrent |
| connection_check | "1" (other=no) | Enable to do a connection check |
| check_trackers_if_category_found | "1" (other=no) | If category is found it will apply settings, and check both defined and tracker list |

#### Variables: (settings.conf): 
Values can be used in all sections (besides [Settings]) The order of variables do not matter
| Name | Value (empty=no change) | Description (effects the torrent only) |
| :---:   | :---: | :---: |
| tracker_name | "string" | Needed only for Defined trackers (ex:"https<nolink>://tracker.org") |
| tag | "string"    | Adds tag(s). If it contains blank spaces or comma separated values, then multiple tags will be created. They are shown in alphabetical order in qBittorrent |
| maxup | "number"   | Maximum upload speed in KB/s (0=Unlimited) |
| maxdl | "number"   | Maximum download speed in KB/s (0=Unlimited)|
| seedtime | "00:00:00"   | Seedtime [DD:HH:MM] (00:00:00=Unlimited) <br /> To view seedtime use -s or -i command. See help (-h) |
| ratio_limit | "number"   | The torrents ratio limit |
| new_category | "string"   | Change category name (creates if it dont exist) |
| atm | "0" or "1"   | Enable (1) or Disable(0) Automatic Torrent Management |
| superseed | "0" or "1" | Enable(1) or Disable(0) Superseeding |
| seqdl | "0" or "1"   | Enable or Disable Sequential downloading |
***
