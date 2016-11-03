	' Connect to FileSystem
	Set fso = CreateObject(Scripting.FileSystemObject)
	
	''
	' VARIABLE SECTION '
	''
	
	' Watch Folder - Set this to the log folder
	strExportFolder = dEclipseLogs
	
	' Working Folder
	strWorkingFolder = dEclipse
	
	' Feed
	strFeed = PIA-TXT-EVENTS
	
	' System
	strSystem = PIA
	
	' Environment
	strEnvironment = OPS
	
	' Stroom Server
	strServer = https://<Stroom_HOST>/stroom/datafeed
	
	' Certificate to use ... this should default to the logged in user
	strUserName = CreateObject(WScript.Network).UserName
	strClientCert = CURRENT_USER & strUserName
	
	''
	' SCRIPT SECTION '
	''
	
	' Connect to Shell
	set objshell = createobject(Wscript.Shell)
	
	' Connect to local environment
	set objEnv = objShell.Environment(PROCESS)
	
	
	ok = 1
	sent = 0
	
	' Initialise 
	set objfLog = fso.Createtextfile(strWorkingFolder & stroom_send_data.log)
	
	' Log
	objfLog.WriteLine (Now &  Started)
	objfLog.WriteLine (Now &  Using Certificate  & strClientCert)
	
	
	' Open Export Folder
	set oFiles = fso.getFolder(strExportFolder).files
	
	
	' Loop through the files
	for each oFile in oFiles
	
	                ' Valid Log File            
	                if (Left(oFile.Name, 2) = sg) then
	                                resp = SendFile(oFile, strFeed, strSystem, strEnvironment)
	                                
	                                if resp = OK then 
	                                                objfLog.WriteLine (Now &  Sent file  & oFile)
	                                                fso.DeleteFile oFile
	                                                sent = sent + 1
	                                else 
	                                                objfLog.WriteLine (Now &  Failed to send file  & oFile)
	                                                objfLog.WriteLine (Now &  Failed message  & resp)
	                                                
	                                                ok = 0
	                                
	                                end if
	                end if
	Next
	
	' Log  
	objfLog.WriteLine (Now &  Finished)
	objfLog.close
	
	if ok = 0 then
	
	                msgbox(Warning!!! Upload Failed (check  & strWorkingFolder & stroom_send_data.log) - Contact IAS)
	
	else 
	                if sent = 0 then
	                                msgbox(Warning!!! Uploaded NO Files (check  & strWorkingFolder & stroom_send_data.log) - Contact IAS)
	                else
	                                msgbox(Uploaded  & sent &  Files OK)
	                end if
	end if    
	                
	
	
	''
	' FUNCTION SECTION '
	''
	Function SendFile(oLogFile, strFeed, strSystem, strEnvironment)
	                objfLog.WriteLine (Now &  Processing File= & oLogFile.Path &  System= & strSystem &  Environment= & strEnvironment)
	                
	
	                ' Connect to HTTP object
	                set objWinHttp = CreateObject(WinHttp.WinHttpRequest.5.1)
	
	                ' Open connection to server
	                objWinHttp.Open POST, strServer
	                
	                ' Set Header data
	                objWinHttp.setRequestHeader Content-type, applicationaudit
	                objWinHttp.setRequestHeader Feed, strFeed
	                objWinHttp.setRequestHeader System, strSystem 
	                objWinHttp.setRequestHeader Environment, strEnvironment 
	                if (Right(oFile.Name, 3) = .gz) then
	                                objWinHttp.setRequestHeader Compression, GZIP
	                end if
	                if (Right(oFile.Name, 3) = .zip) then
	                                objWinHttp.setRequestHeader Compression, ZIP
	                end if
	                objWinHttp.setRequestHeader RemoteFile, oLogFile.Path
	                
	
	                ' Client Cert
	                objWinHttp.SetClientCertificate(strClientCert)
	
	
	
	                ' Send file contents
	                Set streamLog = CreateObject(ADODB.Stream)
	                streamLog.Open
	                streamLog.Type = 1
	                streamLog.LoadFromFile(oLogFile)
	                
	                objWinHttp.Send(streamLog)
	
	                streamLog.Close
	
	                If Err.Number = 0 then
	                                ' If there is no error
	                                ' Check for HTTP status message
	                                if objWinHttp.Status = 200 then
	                                                ' Status 200 is a success
	                                                SendFile = OK
	                                else
	                                                ' any other status is an error
	                                                SendFile = HTTP  & objWinHttp.Status &   & objWinHttp.StatusText
	                                end if
	                else
	                                ' If there is an error return the message
	                                SendFile = Error  & Err.Number &   & Err.Source &   & Err.Description
	                end if
	                
	End Function
