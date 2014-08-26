# Specify a sender email address
$emailFrom = "networkadmin@resdat.com"
# Specify a recipient email address
$emailTo = "Intraneterrors@resdat.com"
# Put in a subject line
$subject = "The CI2 Jenkins Slave Service has Stopped Unexpectedly"
# Add the Service state from line 6 to some body text
$body = $service + "Attempting to restart."
# Put the DNS name or IP address of your SMTP Server
$smtpServer = "mail.resdat.com"
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
# This line pieces together all the info into an email and sends it
$smtp.Send($emailFrom, $emailTo, $subject, $body)

(get-service -displayname "Jenkins Slave").start()

start-sleep -s 10

if((get-service -displayname "Jenkins Slave").Status -eq "Running")
{
	# Put in a subject line
	$subject = "The CI2 Jenkins Slave Service has restarted successfully"
	# Add the Service state from line 6 to some body text
	$body = $service + "Jenkins Slave Service Has Restarted"
}
else
{
	# Put in a subject line
	$subject = "The CI2 Jenkins Slave Service fail to restart automatically. Please manually restart the service."
	# Add the Service state from line 6 to some body text
	$body = $service + "Jenkins Slave Service Fail to Restart"
}

$smtp.Send($emailFrom, $emailTo, $subject, $body)
