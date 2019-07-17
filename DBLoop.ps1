Param(
	[string]$global:pswin
)

# DESCRIPTION #
# creates central SQL tracking database
# manages queue
# SharePoint worker machines request next available DB name and run upgrade
# overall % complete available centrally with TSQL query (EXEC showProgress)

# FILES #
# DBLoop.tsql      Creates SQL database schema and stored procedures
# DBLoop.ps1       SP worker thread to request next available DB name and run upgrade
#                  PARAM = Window Identifier (A,B,C,D) which goes to 
#                  central DB for thread status tracking
#
#                  Run like:
#                  .\DBLoop.ps1 A
#                  .\DBLoop.ps1 B
#                  .\DBLoop.ps1 C
#                  .\DBLoop.ps1 D
#
# DBLoopEmail.ps1  Sends email with HTML table of above data for easy mobile monitoring
# ----------------------------------------

#DBLoop
Write-Host "DBLoop"
Import-Module Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Import-Module SQLPS -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Add-PSSnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue

#Functions
function Main() {

	#Version
	$ver = (get-spfarm).buildversion.major
	
	#Loop
	$db = GetNextAvailableDB
	while ($db) {
	Write-Host "#-"
	
		#Web Application URL
		$mach = $env:computername
		$mach = "$mach-$pswin"
		if ($ver -eq "14") {$url="http://fmhomesite"}
		if ($ver -eq "15") {$url="http://sharepoint"}
		#if ($mach -eq "SPFEUBV01") {$url="http://sharepoint2010"}
		#if ($mach -eq "SPFEUBV02") {$url="http://sharepoint2010"}
		
		#Tracking
		$dbname = $db.DBName
		if (!$dbname) {
			RecordMachineStatus "IDLE"
			break
		}
		Write-Host $dbname -ForegroundColor Green
		RecordMachineStatus "Upgrading-$dbname"
		$status = "$ver-WIP"
		RecordDatabaseStatus $status $dbname
		
		#Core
		#Mount-SPContentDatabase -Name $dbname -DatabaseServer $db.Instance -WebApplication $url 
		#Get-SPContentDatabase $dbname | Get-SPSite -Limit All | Upgrade-SPSite -VersionUpgrade -Unthrottled
		
		#Get-SPContentDatabase $dbname | Get-SPSite -Limit All |% {$u=$_.url; $u; Disable-SPFeature 87294c72-f260-42f3-a41b-981a2ffce37a -Url $u -Confirm:$false}
		
		#Get-SPContentDatabase $dbname | Get-SPSite -Limit All |% {$u=$_.url; Enable-SPFeature 8581a8a7-cf16-4770-ac54-260265ddb0b2 -Url $u -Confirm:$false}
		
		
		$sql = "delete FROM [dbo].[Features] where featureid IN ('367b94a9-4a15-42ba-b4a2-32420363e018','389156cf-498b-41cd-a078-6cb086d2474b','448e1394-5e76-44b4-9e1c-169b7a389a1b','525dc00c-0745-47c0-8073-221c2ec22f0f','60d1e34f-0eb3-4e56-9049-85daabfec68c','75a0fea7-0017-4993-85fe-c37971507bbc','75a0fea7-040e-4abb-b94b-32f1e7572840','75a0fea7-07c7-453d-866c-979c401d0105','75a0fea7-12fe-4cad-a1b2-525fa776c07e','75a0fea7-24d7-4907-81ec-2d71dd3dfde9','75a0fea7-2791-45a2-896f-e538f91032d8','75a0fea7-2d1e-451a-b445-16bc346d7d8e','75a0fea7-30ba-45d8-bf12-3c0855491ad1','75a0fea7-3b2a-4838-8a0c-57ba864feed3','75a0fea7-3cc9-4c20-bf74-9bfa9fd5d614','75a0fea7-42e8-4527-8313-f63c4c49a7e6','75a0fea7-5dd8-40af-b960-12af3053f5ec','75a0fea7-625d-4b31-be9e-24cee53d0d72','75a0fea7-70e3-40b1-b395-c06f85d0d158','75a0fea7-7478-44e1-8b39-d600e3f4f53f','75a0fea7-775b-4ae1-bbc6-ad5ef0d22413','75a0fea7-7afc-4a13-b91a-7dc661f04785','75a0fea7-7ce3-4ba1-84b7-4bd9da4c9468','75a0fea7-84d9-447d-b9ec-bc49570874db','75a0fea7-8d3c-455d-89d3-4ece8739402d','75a0fea7-92c2-4fdf-9b21-8cfbb6d3b240','75a0fea7-9454-48ab-883d-ede5b98710d6','75a0fea7-b0ef-434e-90d6-ce997d970564','75a0fea7-b4c2-46ca-b4b1-819331cf2e4b','75a0fea7-b5a0-47d5-90e6-4b3205b02278','75a0fea7-c256-49cb-bf7f-de124ca9bf13','75a0fea7-c54f-46b9-86b1-2e103a8fedba','75a0fea7-c671-4696-ac6f-5decfca3173e','75a0fea7-c966-4e74-b74e-8f77e7bae175','75a0fea7-cd50-401e-af0e-782f3662a299','75a0fea7-d01e-48b3-ba36-8cbbdfeef1d6','75a0fea7-d31d-491a-9177-f0e461a81e3f','75a0fea7-e63b-4059-8f5a-ce9cbbadad2a','75a0fea7-f780-458c-b53d-441b33a9ac32','75a0fea7-fe65-41c3-a965-c5df83fb098b','75a0fea7-fe9d-4119-9615-2c2ef22d6fdb','7a8b11f4-38b2-402b-ad94-1213e25150ca','8a7f09e0-b05f-4368-aef6-26e0afb41159','90014905-433f-4a06-8a61-fd153a27a2b5','d8d8df90-7b1f-49c1-b170-6f46a94f8c3c','de6e1f2d-6409-4ed6-a82a-d503a67f94c6','e78330fb-10f5-4b0d-b92d-44ab51e49adf','f386a1b6-b0f4-46d2-a122-b3a1e56eeb16','0b533840-adad-4f11-8351-d7198d981e6a','0cb27286-df67-4360-985b-ed7f52b026ec','294ee2ab-1f37-41de-a57a-1fa8703ceda9','3fe828c5-3675-408a-aeb4-74249b2397cc','5701f249-4929-401f-9ce6-84579a6b3769','5b5c3326-04be-43fc-9380-9f0e7304aa89','6d84433f-af19-4fd6-9a83-be554a4d7002','74a3d656-3bae-47b2-a789-db4f98a91ef3','8182bcc7-cbe3-43fe-afee-e119a3274347','86354765-251c-4428-8948-2f2e2893ef8e','90781af3-bdab-46e8-afe6-b0fd50f44dad','95e911ba-59d8-4f83-8748-ed31f50e9a7a','9eb26489-f731-4908-8f72-875c4cb9d9dd','b18e5c5e-93f6-4abd-ab0d-6a76710d30e0','c49fbaa9-7cb1-419c-a01a-46edacedca79','ca20d80e-946f-4d84-a040-a9d6d4259e74','cfd2ed92-cef8-4c92-97cf-19fe555d2a2b','d4872078-91f2-427e-8ee3-7dff9878c988','d9d72f8c-7273-4dc8-97d3-8527e1e32bd1','448e1394-5e76-44b4-9e1c-169b7a389a1b','525dc00c-0745-47c0-8073-221c2ec22f0f','60d1e34f-0eb3-4e56-9049-85daabfec68c','75a0fea7-0017-4993-85fe-c37971507bbc','75a0fea7-040e-4abb-b94b-32f1e7572840','75a0fea7-12fe-4cad-a1b2-525fa776c07e','75a0fea7-2d1e-451a-b445-16bc346d7d8e','75a0fea7-3cc9-4c20-bf74-9bfa9fd5d614','75a0fea7-42e8-4527-8313-f63c4c49a7e6','75a0fea7-775b-4ae1-bbc6-ad5ef0d22413','75a0fea7-8d3c-455d-89d3-4ece8739402d','75a0fea7-b5a0-47d5-90e6-4b3205b02278','75a0fea7-d31d-491a-9177-f0e461a81e3f','7a8b11f4-38b2-402b-ad94-1213e25150ca','d8d8df90-7b1f-49c1-b170-6f46a94f8c3c','75a0fea7-5dd8-40af-b960-12af3053f5ec','75a0fea7-7ce3-4ba1-84b7-4bd9da4c9468','75a0fea7-92c2-4fdf-9b21-8cfbb6d3b240')"
		$r = Invoke-Sqlcmd -Query $sql -Database $dbname -ServerInstance $db.Instance
		$r
		
		#$sec = (Get-Random -Minimum 0 -Maximum 10)
		#Sleep $sec
		
		#Tracking
		RecordMachineStatus "Complete-$dbname"
		$status = "$ver-DONE"
		RecordDatabaseStatus $status $dbname
		
		#Next
		$db = GetNextAvailableDB
	}

	#Complete
	RecordMachineStatus "IDLE"

}

function RecordMachineStatus($status) {
	$now = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss tt")
	$mach = $env:computername
	$mach = "$mach-$pswin"
	ExecTSQL "UPDATE [Machines] SET [Status]='$status',Time='$now' WHERE [Machine]='$mach'"
}

function RecordDatabaseStatus($status, $dbname) {
	$now = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss tt")
	$mach = $env:computername
	$mach = "$mach-$pswin"
	ExecTSQL "UPDATE [Databases] SET [Status]='$status',Time='$now',ByMachine='$mach' WHERE [DBName]='$dbname'"
}

function GetNextAvailableDB() {
	return ExecTSQL "EXECUTE [getNextAvailableDatabase]"
}

function ExecTSQL($tsql) {
	Write-Host $tsql -ForegroundColor Yellow
	$result = Invoke-Sqlcmd -Query $tsql -Database "DBLoop" -ServerInstance "MSSQL\INSTANCE"
	return $result
}


#Main
Start-Transcript
Main
Stop-Transcript
