<# 
.SYNOPSIS  
    Better manage the SharePoint 07 > 10 > 13 content database upgrade
.DESCRIPTION  
    Migrating MOSS 2007 to SP 2013? This script takes a CSV of databases and runs upgrade 
    Cmdlets in bulk (DB version/Mount/Dismount/Upgrade-SPSite/Claims auth)

    Upgrading MOSS to SP2013 is a tedious process with many Cmdlets, especially if you have
    many databases. This script aims to help automate that process. 

    Given a CSV with SQL instance and content database names, this script offers Cmdlets to 
    run upgrade steps across many databases all at once. No more TXT or XLS copy and paste madness.
    Simply populate the CSV, get familiar with UH* Cmdlets and upgrade with ease.

	Comments and suggestions always welcome!  spjeff@spjeff.com or @spjeff
.PARAMETER
	None
.NOTES  
    File Name     : SPUpgradeHelper.ps1
    Author        : Jeff Jones - @spjeff
    Version       : 1.3
	Last Modified : 01-13-2015
.LINK
	http://spupgradehelper.codeplex.com/
#>

$UHFunctions = @"
Function SPUpgradeHelperStartLog {
	# Start LOG file
	`$pc = `$env:computername
	`$time =(Get-Date).ToString("yyyyMddhhmmss")
	Start-Transcript -Path "C:\SPUH\SPUH_`$pc_`$time.txt"
}

Function UHReadCSV () {
	# Read config into memory
	Write-Host "`nRead CSV ..."
	`$filename = Read-Host "Type full path to CSV file"
	if (`$filename) {
		`$global:UHCSV = Import-CSV `$filename
		Write-Host "Read `$filename [OK]"  -ForegroundColor Green
	} else {
		Write-Host "No file path provided" -ForeGroundColor Red
	}
}

Function UHDBVersion (`$upgradeSet, `$webAppUrl) {
	# Any SharePoint version
	# Reads database version from TSQL to guide admin towards next command needed
	Write-Host "`nDB Version ..."
	`$tsql = "SELECT TOP 1 [Version] FROM [dbo].[Versions] WHERE [VersionId]='00000000-0000-0000-0000-000000000000' ORDER BY Id DESC"
	if (`$upgradeSet -eq "*") {
		`$dbs = `$global:UHCSV
	} else {
		`$dbs = `$global:UHCSV |? {`$_.UpgradeSet -eq `$upgradeSet}
	}
	if (!`$dbs) {
		Write-Host "No match found upgrade set = `$upgradeSet" -ForeGroundColor Red
	} else {
		`$coll=@()
		foreach (`$row in `$dbs) {
			`$dbname = `$row.DBName
			`$dbinst = `$row.DBInstance

			# Core command
			`$res = Invoke-Sqlcmd -Query `$tsql -ServerInstance `$dbinst -Database `$dbname
			
			`$ver = `$res[0].ToString()
			`$obj = New-Object -TypeName PSObject -Prop (@{"DBName"=`$dbname;"SPVer"=`$ver})
			`$coll += `$obj
		}
	}
	`$coll
}

Function UHMount (`$upgradeSet, `$webAppUrl) {
	# SharePoint 2010 and 2013
	# Upgrade database schema
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Write-Host "`nMount ..."
	`$dbs = `$global:UHCSV |? {`$_.UpgradeSet -eq `$upgradeSet}
	if (!`$dbs) {
		Write-Host "No match found upgrade set = `$upgradeSet" -ForeGroundColor Red
	} else {
		foreach (`$row in `$dbs) {
			`$d = Get-Date
			`$dbname = `$row.DBName
			`$dbinst = `$row.DBInstance
			Write-Host "START,Time,`$d,DBName,`$dbname,DBInst,`$dbinst" -ForegroundColor Yellow
			
			# Core command
			Mount-SPContentDatabase -Name `$dbname -DatabaseServer `$dbinst -WebApplication `$webAppUrl
			
			`$tot = (((Get-Date) - `$d).TotalMinutes)
			`$d = Get-Date
			Write-Host "FINISH,Start,`$d,DBName,`$dbname,DBInstance,`$dbinst,TotalMin,`$tot" -ForegroundColor Yellow
		}
	}
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
}

Function UHDismount (`$upgradeSet) {
	# SharePoint 2010 and 2013
	# Remove database from farm
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Write-Host "`nDismount ..."
	`$dbs = `$global:UHCSV |? {`$_.UpgradeSet -eq `$upgradeSet}
	if (!`$dbs) {
		Write-Host "No match found upgrade set = `$upgradeSet" -ForeGroundColor Red
	} else {
		foreach (`$row in `$dbs) {
			`$d = Get-Date
			`$dbname = `$row.DBName
			`$dbinst = `$row.DBInstance
			Write-Host "START,Time,`$d,DBName,`$dbname,DBInst,`$dbinst" -ForegroundColor Yellow
			
			# Core command
			Dismount-SPContentDatabase `$dbname -Confirm:`$false
			
			`$tot = (((Get-Date) - `$d).TotalMinutes)
			`$d = Get-Date
			Write-Host "FINISH,Start,`$d,DBName,`$dbname,DBInstance,`$dbinst,TotalMin,`$tot" -ForegroundColor Yellow
		}
	}
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
}

Function UHUpgrade (`$upgradeSet) {
	# SharePoint 2013
	# Upgrade GUI to 15
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Write-Host "`nUpgrade Site ..."
	`$dbs = `$global:UHCSV |? {`$_.UpgradeSet -eq `$upgradeSet}
	if (!`$dbs) {
		Write-Host "No match found upgrade set = `$upgradeSet" -ForeGroundColor Red
	} else {
		foreach (`$row in `$dbs) {
			`$d = Get-Date
			`$dbname = `$row.DBName
			`$dbinst = `$row.DBInstance
			Write-Host "START,Time,`$d,UpgradeSet,`$upgradeSet" -ForegroundColor Yellow
			
			# Core command
			`$db = Get-SPContentDatabase `$dbname
			`$db
			`$sites = `$db | Get-SPSite -Limit All
			foreach (`$site in `$sites) {
				`$site.Url
				`$site | Upgrade-SPSite -VersionUpgrade
				#WIP -QueueOnly
			}
			
			<#WIP
			# Poll status
			Start-Sleep 30
			while (`$true) {
				`$info = `$db | Get-SPSiteUpgradeSessionInfo -ShowInProgress -ShowFailed
				Write-Host `$info -ForeGroundColor Green
				if (!`$info) {break;}
				Start-Sleep 30
			}#>
			
			`$tot = (((Get-Date) - `$d).TotalMinutes)
			`$d = Get-Date
			Write-Host "FINISH,Start,`$d,DBName,`$dbname,DBInstance,`$dbinst,TotalMin,`$tot" -ForegroundColor Yellow
		}
	}
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
}

Function UHClaims (`$webAppUrl) {
	# SharePoint 2010 and 2013
	# Upgrade permissions from Classic to Claims
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Write-Host "`nClaims Auth ..."
	`$d = Get-Date
	Write-Host "START,Time,`$d,WebAppUrl,`$webAppUrl" -ForegroundColor Yellow
	
	# Core command
	Write-Host "WA Convert .."
	Convert-SPWebApplication -Identity `$webAppUrl -From LEGACY -To Claims -RetainPermissions
	Write-Host "OK"
	
	# Also execute MigrateUsers()
	#http://thesharepointfarm.com/2014/11/test-spcontentdatabase-classic-to-claims-conversion/
	Write-Host "WA Migrate Users .."
	(Get-SPWebApplication `$webAppUrl).MigrateUsers(`$true)
	Write-Host "OK"
	
	`$tot = (((Get-Date) - `$d).TotalMinutes)
	`$d = Get-Date
	Write-Host "FINISH,Time,`$d,TotalMin,`$tot" -ForegroundColor Yellow
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
}

Function UHClaimsSEL (`$upgradeSet) {
	# SharePoint 2013 claims SELECT query for SCA removed in AD
	#http://thesharepointfarm.com/2014/11/test-spcontentdatabase-classic-to-claims-conversion/
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Write-Host "`UHClaimsSEL ..."
	if (`$upgradeSet -eq "*") {
		`$dbs = `$global:UHCSV
	} else {
		`$dbs = `$global:UHCSV |? {`$_.UpgradeSet -eq `$upgradeSet}
	}
	if (!`$dbs) {
		Write-Host "No match found upgrade set = `$upgradeSet" -ForeGroundColor Red
	} else {	
		`$tsql = "SELECT [tp_SiteID],[tp_Login] FROM [UserInfo] WITH (NOLOCK) WHERE tp_IsActive = 1 AND tp_SiteAdmin = 1 AND tp_Deleted = 0 and tp_Login not LIKE 'i:%'"
		`$coll=@()
		foreach (`$row in `$dbs) {
			`$dbname = `$row.DBName
			`$dbinst = `$row.DBInstance

			# Core command
			`$res = Invoke-Sqlcmd -Query `$tsql -ServerInstance `$dbinst -Database `$dbname
			
			foreach (`$r in `$res) {
				`$siteid = `$r[0].ToString()
				`$login = `$r[1].ToString()
				`$obj = New-Object -TypeName PSObject -Prop (@{"DBName"=`$dbname;"SiteID"=`$siteid;"Login"=`$login})
				`$coll += `$obj
			}
			
		}
		`$coll
	}
}

Function UHClaimsUPD (`$upgradeSet) {
	# SharePoint 2013 claims SELECT query for SCA removed in AD
	#http://thesharepointfarm.com/2014/11/test-spcontentdatabase-classic-to-claims-conversion/
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Write-Host "`UHClaimsUPD ..."
	if (`$upgradeSet -eq "*") {
		`$dbs = `$global:UHCSV
	} else {
		`$dbs = `$global:UHCSV |? {`$_.UpgradeSet -eq `$upgradeSet}
	}
	if (!`$dbs) {
		Write-Host "No match found upgrade set = `$upgradeSet" -ForeGroundColor Red
	} else {	
		`$tsql = "UPDATE [UserInfo] SET tp_SiteAdmin = 0 WHERE tp_IsActive = 1 AND tp_SiteAdmin = 1 AND tp_Deleted = 0 and tp_Login not LIKE 'i:%'"
		`$coll=@()
		foreach (`$row in `$dbs) {
			`$dbname = `$row.DBName
			`$dbinst = `$row.DBInstance

			# Core command
			`$res = Invoke-Sqlcmd -Query `$tsql -ServerInstance `$dbinst -Database `$dbname
			`$res
			
		}
	}
}


Function UHCompatibility2013 () {
	# SharePoint 2013
	# Show many many websites are using old-14/new-15 UI
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Get-Date
	Write-Host "`nCompatibility Level 2013 ..."
	`$s = Get-SPSite -Limit All | Select Url,CompatibilityLevel
	`$s | group CompatibilityLevel | ft -a
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
}

Function UHUIVersion2010 () {
	# SharePoint 2010
	# Show many many websites are using old-3/new-4 UI
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
	SPUpgradeHelperStartLog
	Get-Date
	Write-Host "`nUI Version 2010 ..."
	`$s = Get-SPSite -Limit All | Select Url,UIVersion
	`$s | group UIVersion | ft -a
	try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch{}
}

Function UHTest () {
	# SharePoint 2010 and 2013
	# Test database in local farm
	Get-SPDatabase |? {`$_.Type -like 'Content*'} |% {`$n=`$_.Name; `$_} | Test-SPContentDatabase | Select *,{`$n}
}
"@

Write-Host "SPUpgradeHelper loaded [OK]"  -ForegroundColor Green
md "$home\Documents\WindowsPowerShell\Modules\SPUpgradeHelper" -ErrorAction SilentlyContinue | Out-Null
$UHFunctions | Out-File "$home\Documents\WindowsPowerShell\Modules\SPUpgradeHelper\SPUpgradeHelper.psm1" -Force
Import-Module SPUpgradeHelper
UHReadCSV
Get-Command UH*