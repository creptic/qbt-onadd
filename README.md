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
 
### Requirements:
- https://github.com/fedarovich/qbittorrent-cli  also available in [AUR](https://aur.archlinux.org/packages/qbittorrent-cli)
- qBittorent server info can be set manully in qbittorrent-cli or via script. (See [Installation](#installation) for instructions)    
- qbittorrent-cli also runs in powershell. This script has not been tested in powershell yet. 
***
### Basic Usage:
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
3. [Usage](#usage)
4. [Wiki](#wiki)
### General Info
***
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
A little intro about the installation. 
```
$ cd ../path/to/qbt-onadd.sh (qbt-onadd-minimal.sh if using minimal version from the extras folder)
$ chmod +x qbt-onadd.sh
```
Side information: To use the application in a special environment use ```lorem ipsum``` to start
## Usage
***
Give instructions on how to collaborate with your project.
> Maybe you want to write a quote in this part. 
> Should it encompass several lines?
> This is how you do it.
## Wiki
***
For more information visit the WIki page
