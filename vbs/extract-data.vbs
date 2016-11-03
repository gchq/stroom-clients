	'** Connect to FileSystem
	Set fso = CreateObject("Scripting.FileSystemObject")
	
	'**********************'
	'** VARIABLE SECTION **'
	'**********************'
	
	'** Watch Folder - Set this to the log folder
	strExportFolder = fso.GetAbsolutePathName(".")
	
	'** Working Folder
	strWorkingFolder = fso.GetAbsolutePathName(".")
	
	'********************'
	'** SCRIPT SECTION **'
	'********************'
	
	'** The Key we use to store the last date
	Const strRegLastSendDateKey = "HKCU\Stroom\Stroom_LAST_SENT_DATE"
	
	'** Connect to Shell
	Set objShell = createobject("Wscript.Shell")
	
	Set winShell = createobject("shell.application")
	 
	'** Connect to local environment
	Set objEnv = objShell.Environment("PROCESS")
	
	'** Initialise - we use the log file for exclusive lock to is we can't 
	strLogFileName = strWorkingFolder + "\stroom_extract_data.log"
	Dim objfLog 
	Const ForAppending = 8
	
	'** Handle errors in the script
	On Error Resume Next
	
	Set objfLog = fso.OpenTextFile(strLogFileName, ForAppending, True)
	
	'** Exclusive Lock check
	If (Err <> 0) Then
		wScript.Quit 1
	End If
	
	'** Error handling back on
	On Error Goto 0
	
	'** Log
	objfLog.WriteLine (Now & " Started")
	
	'** Deduce the current time in UTC format
	dtNow = utcDateTime()
	strNowUtcDateTime = Year(dtNow) & "-" & lz(Month(dtNow)) & "-" & lz(Day(dtNow)) & "T" & lz(Hour(dtNow)) & ":" & lz(Minute(dtNow)) & ":" & lz(Second(dtNow)) & ".000Z"
	
	'** Log
	objfLog.WriteLine (Now & " UTC now date time " & strNowUtcDateTime)
	
	'** Handle errors in the script
	On Error Resume Next
	
	'** Pull the date from the registry and check the value looks OK
	strKey = objShell.RegRead(strRegLastSendDateKey)
	
	'** Got a OK Key?
	If (Err <> 0) Then
		'** Error handling back on
		On Error Goto 0
	
		objfLog.WriteLine (Now & " No or invalid last sent date found.  Updating last run time to now andquictting script")
	
		objShell.RegWrite strRegLastSendDateKey, strNowUtcDateTime
	
		wScript.Quit 0
	End If
	
	'** Error handling back on
	On Error Goto 0
	
	
	'** We have a period, now do the extract
	strPeriodStart = strKey
	strPeriodEnd = strNowUtcDateTime
	
	'** Log
	objfLog.WriteLine (Now & " Extracting for period " & strPeriodStart & " to " & strPeriodEnd )
	
	'** Set File Names
	strBaseFileName = Replace(strPeriodStart, ":", "#") & "_" & Replace(strPeriodEnd, ":", "#")
	strLogFileName = strBaseFileName & ".xml"
	strLogFilePath = strExportFolder & "\" & strBaseFileName & "\" & strLogFileName
	strZipFileName = strBaseFileName & ".zip"
	strZipFilePath = strExportFolder & "\" & strZipFileName
	strDirFilePath = strExportFolder & "\" & strBaseFileName
	
	fso.CreateFolder(strDirFilePath)
	
	'** Call wevtutil **
	strXPath = "/q:*[System[TimeCreated[@SystemTime >= '" &strPeriodStart& "' and @SystemTime < '" &strPeriodEnd& "']]]"
	objShell.Run "cmd /c wevtutil.exe qe Security """ & strXPath & """  > " & strLogFilePath, 0, True
	
	'** Log
	objfLog.WriteLine (Now & " XPath is " & strXPath)
	
	zip strZipFilePath, strDirFilePath
	
	fso.DeleteFolder(strDirFilePath)
	
	
	'** Log	
	objfLog.WriteLine (Now & " Finished")
	
	objShell.RegWrite strRegLastSendDateKey, strNowUtcDateTime
	
	objfLog.Close
	
	wScript.Quit 0
	
	
	
	'*******************************
	'* Function to add leading zero to
	'* normalise date format
	function lz(numb)
		'** Adds Leading zeros to numbers
		if (Numb>-1) and (Numb<10) then
			tmpVal = "0" & numb
		else
			tmpval = numb
		end if
		lz = tmpval
	end function
	
	
	function utcDateTime() 
		tmpDateTime = now()
		offsetMin = objShell.RegRead("HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation\ActiveTimeBias")
		utcDateTime = dateadd("n", offsetMin, tmpDateTime)
	end function
	
		
	
	
	'*******************************
	'* Function to zip up a folder
	function zip(strTarget, strSource)
		
		Set file = fso.CreateTextFile(strTarget, True)
		file.write("PK" & chr(5) & chr(6) & string(18,chr(0)))
		file.close
	
		Set sourceFile = winShell.NameSpace((strSource))
		Set targetFile = winShell.NameSpace((strTarget))
		
		targetFile.CopyHere sourceFile.Items
	
		do until targetFile.items.count = sourceFile.items.count
			WScript.Sleep 1000
		loop
	end function
