# qbt-onadd 
 - Sets custom settings to a single torrent in qBittorent, when added or run manually.
 - Does not effect other settings or torrents in qBittorrent. No cron or required.
 - Change tag name, speed and ratio limits, seeding time limit, and category (must exist).
 - Customize values depending on category(s) and/or user defined tracker(s). 
 - Customize settings depending on private, public or unknown (no tracker info found) tracker(s).
 - Options and settings are edited directly in script. Uses qBittorrent setting for empty values.  
 - Command line options including dry run and log level overrides.
 - Commented code. Ability to add more categoy checks (copy/paste and edit existing code).
 - Example code included in script (bottom code-block). Moduler which makes changing code easy. 
 - Logging can be set to none, console (terminal), or file (must be writable). Useful for testing.
 - Run from terminal, or add to qBittorrent External Add path.
 
### Requirements:
- https://github.com/fedarovich/qbittorrent-cli
- qBittorent url and login must be set in qbittorrent-cli manually. (See [Installation](#installation) for instructions)    
***
### Basic Usage:
- Teminal: (category is optional)
```
 $ ./path/to/script/ torrent_hash category 
```
Note: torrent_hash must be 40 characters in length, or change skip_hash_check="1" setting in script.
- qBittorrent
  add ```/scriptpath/qbt-onadd.sh "%T" "%L"``` to External Add path in qBittorent. 
***
## Table of Contents
1. [General Info](#general-info)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Wiki](#wiki)
### General Info
***
Write down general information about your project. It is a good idea to always put a project status in the readme file. This is where you can add it. 
### Screenshot
![Image text](https://www.united-internet.de/fileadmin/user_upload/Brands/Downloads/Logo_IONOS_by.jpg)
## Installation
***
A little intro about the installation. 
```
$ git clone https://example.com
$ cd ../path/to/the/file
$ chmod +x file
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
