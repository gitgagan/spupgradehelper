Import-Module Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Import-Module SQLPS -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Add-PSSnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue
Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$Script:SessionName = "";
$Script:SqlServer = "";

##############################
#.SYNOPSIS
# Start a new upgrade sessions. Using the tracking database the upgrade is distributed to multiple servers.
#
#.PARAMETER SessionName
# The name of the upgrade session, is used in the tracking db to identify which session is upgrading each database.
#
#.PARAMETER SqlServer
# The SQL server which contains the DBLoop database.
#
#.PARAMETER WebApplication
# The WebApplication which the content databases needs to be attached to.
#
#.EXAMPLE
# Start-UpgradeSession -SessionName "A" -SqlServer "SPSQL" -WebApplication "http://portal"
#
##############################
function Start-UpgradeSession {
    param(
        [Parameter(Mandatory=$true,
            HelpMessage="The name for this session")]
        [string]
        $SessionName,
        [Parameter(Mandatory=$true,
            HelpMessage="SQL Server containing tracking db")]
        [string]
        $SqlServer,
        [Parameter(Mandatory=$true)]
        [string]
        $WebApplication
    )

    $Script:SessionName = "$env:computername-$SessionName"
    $Script:SqlServer = $SqlServer;
    RecordMachineStatus "IDLE"

    # Get the next DB to upgrade
    $db = GetNextAvailableDB
    while ($db) {
        $dbname = $db.DBName
		if (!$dbname) {
			RecordMachineStatus "IDLE"
			break
		}
		Write-Host $dbname -ForegroundColor Green
        RecordMachineStatus "Upgrading-$dbname"
        $status = "$ver-WIP"
		RecordDatabaseStatus $status $dbname
        
        # Mount Content database
        Mount-SPContentDatabase -Name $dbname -DatabaseServer $db.Instance -WebApplication $WebApplication

        # Visual upgrade
        Get-SPContentDatabase $dbname | Get-SPSite -Limit All | Upgrade-SPSite -VersionUpgrade

        #Tracking
		RecordMachineStatus "Complete-$dbname"
		$status = "$ver-DONE"
		RecordDatabaseStatus $status $dbname
		
		#Next
		$db = GetNextAvailableDB
    }

    Write-Host "Execution finished, no more SP Content Databases to upgrade" -ForegroundColor Green
}

##############################
#.SYNOPSIS
# Import a CSV containg the content databases and their location into the tracking database
# Example format:
# DBName,DBInstance
# WSS_Content_001,SQLServer001
#
#.PARAMETER Path
# Path containing the CSV file to import. 
#
#.PARAMETER SqlServer
# The SQL server which contains the DBLoop database.
#
#.EXAMPLE
# Import-UpgradeDatabases -Path "C:\Temp\SPUpgradeHelper-Collab-Farm.csv" -SqlServer "SPSQL"
#
##############################
function Import-UpgradeDatabases {
    param(
        [Parameter(Mandatory=$true,
                   HelpMessage="Path to .csv files containing content databases")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [Parameter(Mandatory=$true,
            HelpMessage="SQL Server containing tracking db")]
        [string]
        $SqlServer
    )

    $dbs = Import-CSV $Path
    foreach ($row in $dbs) {
        $dbname = $row.DBName
        $dbinst = $row.DBInstance
        ExecTSQL "INSERT INTO [Databases] (DBName, Instance) values ('$dbname', '$dbinst')"
    }
}

Export-ModuleMember -Function Start-UpgradeSession, Import-UpgradeDatabases

function RecordMachineStatus($status) {
	$now = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss tt")
    ExecTSQL "EXECUTE [registerOrUpdateMachine] @Machine='$Script:SessionName', @Status='$status', @Time='$now'"
}

function RecordDatabaseStatus($status, $dbname) {
	$now = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss tt")
	ExecTSQL "UPDATE [Databases] SET [Status]='$status',Time='$now',ByMachine='$Script:SessionName' WHERE [DBName]='$dbname'"
}

function GetNextAvailableDB() {
	return ExecTSQL "EXECUTE [getNextAvailableDatabase]"
}

function ExecTSQL($tsql, $instance) {
	Write-Host $tsql -ForegroundColor Yellow
	$result = Invoke-Sqlcmd -Query $tsql -Database "DBLoop" -ServerInstance $instance
	return $result
}





