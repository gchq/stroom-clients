	'** Connect to FileSystem
	Set fso = CreateObject("Scripting.FileSystemObject")
	
	'**********************'
	'** VARIABLE SECTION **'
	'**********************'
	
	'** Watch Folder - Set this to the log folder
	strExportFolder = "d:\Eclipse\DVD"
	
	'** Working Folder
	strWorkingFolder = fso.GetAbsolutePathName(".")
	
	'** System
	strSystem = "EXAMPLE_SYSTEM"
	
	'** Environment
	strEnvironment = "EXAMPLE_ENVIRONMENT"
	
	'** Stroom Server
	strServer = "https://<Stroom_HOST>/stroom/datafeed"
	
	'** Certificate to use
	'** This depends where you install the client p12 certificate which should be
	'** CURRENT_USER\<certificate name> or LOCAL_MACHINE\<certificate name>
	strClientCert = "CURRENT_USER\Stroom_W2K8"
	
	'********************'
	'** SCRIPT SECTION **'
	'********************'
	
	'** Connect to Shell
	set objshell = createobject("Wscript.Shell")
	
	'** Connect to local environment
	set objEnv = objShell.Environment("PROCESS")
	
	
	'** Initialise 
	set objfLog = fso.Createtextfile(strWorkingFolder + "\stroom_send_data.log")
	
	
	rtnCode = MsgBox("About to send data to " & vbNewLine & vbNewLine & strServer & vbNewLine & vbNewLine & "Ensure you check log file stroom_send_data.log" & vbNewLine & vbNewLine & "Continue?", VBYesNo, "Tom")
	
	if rtnCode = 7 then
		WScript.Quit(1)
	end if
	
	
	'** Log
	objfLog.WriteLine (Now & " Started")
	
	intSentFiles = 0
	intErrorFiles = 0
	
	
	ProcessFolder(fso.getFolder(strExportFolder))
	
	MsgBox("Finished!!")
	
	
	'**********************'
	'** FUNCTION SECTION **'
	'**********************'
	Function ProcessFolder(oFolder)
	
		set oFiles = oFolder.files
	
		'** Loop through the files
		for each oFile in oFiles
		
			strFeed = "UNKNOWN"
			
			if (InStr(oFile, "windows")>0) then 
				strFeed = "TEST_FEED"
			end if
			if (InStr(oFile, "syslog")>0) then 
				strFeed = "TEST_FEED"
			end if
			if (InStr(oFile, "ironport")>0) then 
				strFeed = "TEST_FEED"
			end if
	
			if (strFeed <> "UNKNOWN") then 
	
	
				resp = SendFile(oFile, strFeed, strSystem, strEnvironment)
	
	
				if resp = "OK" then 
					objfLog.WriteLine (Now & " Sent file " & oFile)
					intSentFiles = intSentFiles + 1
				else 
					objfLog.WriteLine (Now & " Failed to send file " & oFile)
					objfLog.WriteLine (Now & " Failed message " & resp)
					intErrorFiles = intErrorFiles + 1
				end if
			end if
	
		Next
	
		set oSubFolders = oFolder.subFolders
		for each oSubFolder in oSubFolders
	
			ProcessFolder(oSubFolder)
		Next
	
	
	
	End Function
	
	
	
	'**********************'
	'** FUNCTION SECTION **'
	'**********************'
	Function SendFile(oLogFile, strFeed, strSystem, strEnvironment)
		objfLog.WriteLine (Now & " Processing File=" & oLogFile.Name & " Feed=" & strFeed & " System=" & strSystem & " Environment=" & strEnvironment)
		
	
		'** Connect to HTTP object
		set objWinHttp = CreateObject("WinHttp.WinHttpRequest.5.1")
	
		'** Open connection to server
		objWinHttp.Open "POST", strServer
		
		'** Set Header data
		objWinHttp.setRequestHeader "Content-type", "application/audit"
		objWinHttp.setRequestHeader "Feed", strFeed
		objWinHttp.setRequestHeader "System", strSystem 
		objWinHttp.setRequestHeader "Environment", strEnvironment 
		'** objWinHttp.setRequestHeader "Compression", "Zip"
		
	
		'** Client Cert
		objWinHttp.SetClientCertificate(strClientCert)
	
	
	
		'** Send file contents
		Set streamLog = CreateObject("ADODB.Stream")
		streamLog.Open
		streamLog.Type = 1
		streamLog.LoadFromFile(oLogFile)
		
		objWinHttp.Send(streamLog)
	
		streamLog.Close
	
		If Err.Number = 0 then
			'** If there is no error
			'** Check for HTTP status message
			if objWinHttp.Status = "200" then
				'** Status 200 is a success
				SendFile = "OK"
			else
				'** any other status is an error
				SendFile = "HTTP " & objWinHttp.Status & " " & objWinHttp.StatusText
			end if
		else
			'** If there is an error return the message
			SendFile = "Error " & Err.Number & " " & Err.Source & " " & Err.Description
		end if
		
	End Function
