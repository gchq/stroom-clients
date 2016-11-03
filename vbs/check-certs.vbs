	'** Connect to FileSystem
	Set fso = CreateObject("Scripting.FileSystemObject")
	
	'**********************'
	'** VARIABLE SECTION **'
	'**********************'
	
	'** Stroom Server
	strServer = "https://<Stroom_HOST>/stroom/datafeed"
	
	'** Certificate to use
	'** This depends where you install the client p12 certificate which should be
	'** CURRENT_USER\<certificate name> or LOCAL_MACHINE\<certificate name>
	
	strCertName = InputBox("Enter your cert name")
	
	strClientCert = "CURRENT_USER\" + strCertName 
	
	
	'********************'
	'** SCRIPT SECTION **'
	'********************'
	
	'** Connect to Shell
	set objshell = createobject("Wscript.Shell")
	
	'** Connect to local environment
	set objEnv = objShell.Environment("PROCESS")
	
	
	'** Connect to HTTP object
	set objWinHttp = CreateObject("WinHttp.WinHttpRequest.5.1")
	
	'** Open connection to server
	objWinHttp.Open "POST", strServer
	
	'** Set Header data
	objWinHttp.setRequestHeader "Content-type", "application/audit"
	objWinHttp.setRequestHeader "Feed", "TEST-FEED"
		
	'** Client Cert
	objWinHttp.SetClientCertificate(strClientCert)
	
	'** Send file contents
	Set streamLog = CreateObject("ADODB.Stream")
	streamLog.Open
	streamLog.Type = 1
	streamLog.LoadFromFile("check_my_cert.vbs")
	
	objWinHttp.Send(streamLog)
	
	streamLog.Close
	
	If Err.Number = 0 then
		'** If there is no error
		'** Check for HTTP status message
		if objWinHttp.Status = "200" then
			'** Status 200 is a success
			MsgBox("Certificate OK ")
		else
			'** any other status is an error
			MsgBox("Not OK - " & "HTTP " & objWinHttp.Status & " " & objWinHttp.StatusText)
		end if
	else
		'** If there is an error return the message
		SendFile = "Error " & Err.Number & " " & Err.Source & " " & Err.Description
		MsgBox("Not OK - " & SendFile)
	end if
		
