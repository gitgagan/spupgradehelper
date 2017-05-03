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
Write-Host "DBLoopEmail"
Import-Module Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Import-Module SQLPS -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Add-PSSnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue

#Functions
function Main() {
	#Gather data
	$a = ExecTSQL "SELECT status, count(*) AS count FROM [dbo].[Databases] group by status"
	$b = ExecTSQL "SELECT top 10 * FROM [dbo].[Databases] order by [time] desc"
	$c = ExecTSQL "SELECT * FROM [dbo].[Machines]"
	$now = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss tt")
	
	#A
	<#
	$html += " <table border=1> "
	$html += "<tr><td><b>Status</b></td><td><b>Count</b></td></tr> "
	$a |% {$html += " <tr><td>" +$_.Status+ "</td><td>" +$_.Count+ "</td></tr>" ;}
	$html += " </table> "
	#>
	
	#B
	$html += "<table border=1 style='background-color:lightblue'> "
	$html += "<tr><td><b>DBName</b></td><td><b>Instance</b></td><td><b>Status</b></td><td><b>Time</b></td><td><b>ByMachine</b></td></tr> "
	$b |% {$html += " <tr><td>" +$_.DBName+ "</td><td>" +$_.Instance+ "</td><td>" +$_.Status+ "</td><td>" +$_.Time+ "</td><td>" +$_.ByMachine+ "</td></tr>" ;}
	$html += " </table> "
	
	#C
	$html += "<br><br> <table border=1> "
	$html += "<tr><td><b>Machine</b></td><td><b>Status</b></td><td><b>Time</b></td></tr> "
	$c |% {$html += " <tr><td>" +$_.Machine+ "</td><td style='background-color:yellow'>" +$_.Status+ "</td><td>" +$_.Time+ "</td></tr>" ;}
	$html += " </table> "
	
	#Send email
	$done = ($a |? {$_.Status -like '*DONE*'}).count
	$wip = ($a |? {$_.Status -like '*WIP*'}).count
	$assign = ($a |? {$_.Status -like '*ASSIGN*'}).count
	$total = ($a | measure count -sum).sum
	$nullrow = ($a |? {$_.Status.length -eq 1}).count
	$prct = [System.Math]::Round(($done/$total)*100.0,2)
	$subj = "{4} % >> DONE {0} - WIP {1} - ASSIGN {2} - NULL {3}" -f $done,$wip,$assign,$nullrow,$prct
	SendMail $subj $html
}

function ExecTSQL($tsql) {
	Write-Host $tsql -ForegroundColor Yellow
	$result = Invoke-Sqlcmd -Query $tsql -Database "SPUpgradeHelper" -ServerInstance "MSSQL\INSTANCE"
	return $result
}

function SendMail($subj, $body) {
	$to = @("sharepoint_team@company.com","person_one@company.com","person_two@company.com")
	Send-MailMessage -To $to -From "spupgrade@company.com" -Subject $subj -body $body -BodyAsHtml -SmtpServer "smtprelayhost"
}

#Main
Main