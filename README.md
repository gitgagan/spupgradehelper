## Description
Migrating MOSS 2007 to SP 2013? This script takes a CSV of databases and runs upgrade Cmdlets in bulk (DB version/Mount/Dismount/Upgrade-SPSite/Claims auth)

![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/logo.png)

Upgrading MOSS to SP2013 is a tedious process with many Cmdlets, especially if you have many databases. This script aims to help automate that process. 

Given a CSV with SQL instance and content database names, this script offers Cmdlets to run upgrade steps across many databases all at once. No more TXT or XLS copy and paste madness. Simply populate the CSV, get familiar with UH* Cmdlets and upgrade with ease.

## Key Features
* Read CSV of databases
* Load helper functions into memory
* Enable admin to more easily run Cmdlets in bulk
* Measure time duration for each step (# minutes)
* Provide detailed LOG file of actions, result, and duration

## Quick Start Guide
* Extract "SPUpgradeHelper.ZIP" to any SharePoint machine in your farm
* Run "SPUpgradeHelper.ps1" to load helper functions
* Type in full path to your CSV file (i.e. "C:\TEMP\COLLAB.CSV")

## Function Names
* UHCIaims - execute SPWebApplication function to upgrade Classic to Claims auth
* UHCompatibiIity - execute Get-SPSite for "set" of databases to show GUI version (14/15)
* UHDBVersion - execute TSQL for "set" of databases to show build number (12.0, 14.0, 15.0)
* UHDismount - execute DisMount-SPContentDatabase for "set" of databases
* UHMount - execute Mount-SPContentDatabase for "set" of databases
* UHReadCSV - load CSV file into memory with upgrade "set", SQL instance, and database names
* UHUpgrade - execute Upgrade-SPSite for "set" of databases

## Microsoft Upgrade Process
![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/msupg.png)

## DBLoop
Fully automatic high speed upgrade with parallel processing. Central SQL database contains table with available Content Database targets. Each SP worker machines runs "DBLoop.ps1" to get next available database, mark reserved, upgrade, and report status. Email can be sent based on the central tracking database detail to show % complete and status. Works great on farms with a high number of content databases (ex: 100+)

* DBLoop.tsql (creates SQL database schema and stored procedures)
* DBLoop.ps1 (SP worker thread to request next available DB name and run * upgrade)
* DBLoopEmail.ps1 (Sends email with HTML table of above data for easy monitoring)

![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/dbloop.png)

## Screenshots
* Download ZIP and extract
* ![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/1.png)
* Run SPUpgradeHelper.ps1
* ![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/2b.png)
* Type full path to CSV
* ![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/2c.png)
* Type function you'd like to execute (Mount/Dismount/UpgradeSite/etc.) Screenshot below demonstrate how to query the database version (12.9/14.0/15.0) and SPSite GUI compatibility version (14/15).
* ![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/3.png)
* ![image](https://raw.githubusercontent.com/spjeff/spupgradehelper/master/doc/4.png)

## Contact
Please drop a line to [@spjeff](https://twitter.com/spjeff) or [spjeff@spjeff.com](mailto:spjeff@spjeff.com)
Thanks!  =)

![image](http://img.shields.io/badge/first--timers--only-friendly-blue.svg?style=flat-square)

## License

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.