' dsh-edge-app windowless launcher (shortcut target: wscript.exe //B launcher.vbs)
' click: bg auto-update check -> start dsh web hidden -> open Edge standalone app window
Option Explicit

Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
Dim shell : Set shell = CreateObject("WScript.Shell")
Dim ScriptDir : ScriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
Dim Url : Url = "http://127.0.0.1:3080"
Dim OutLog : OutLog = ScriptDir & "\dsh-web.log"
Dim ErrLog : ErrLog = ScriptDir & "\dsh-web.err.log"

Function IsWebUp()
    IsWebUp = False
    On Error Resume Next
    Dim http : Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
    http.Open "GET", Url, False
    http.SetTimeouts 1500, 1500, 1500, 1500
    http.Send
    If Err.Number = 0 And http.Status = 200 Then IsWebUp = True
    On Error GoTo 0
End Function

Function FindEdge()
    Dim p, cands, i
    On Error Resume Next
    p = shell.RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe\")
    On Error GoTo 0
    If p <> "" And fso.FileExists(p) Then
        FindEdge = p
        Exit Function
    End If
    cands = Array( _
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", _
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe", _
        shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Edge\Application\msedge.exe")
    For i = 0 To UBound(cands)
        If fso.FileExists(cands(i)) Then
            FindEdge = cands(i)
            Exit Function
        End If
    Next
    FindEdge = ""
End Function

Dim edge : edge = FindEdge()
If edge = "" Then
    fso.CreateTextFile(ErrLog, True).WriteLine "ERROR: Microsoft Edge not found. Please install it first: https://www.microsoft.com/edge"
    MsgBox "未找到 Microsoft Edge，请先安装后重试。" & vbCrLf & "Microsoft Edge not found. Please install it first: https://www.microsoft.com/edge", vbExclamation, "DeepSeek Harness"
    WScript.Quit 1
End If

' 0) make sure shortcuts exist, recreate if missing (desktop + start menu)
Dim Ps1File : Ps1File = ScriptDir & "\install.ps1"
Dim lnk, i
For i = 1 To 2
    If i = 1 Then
        lnk = shell.SpecialFolders("Desktop") & "\DeepSeek Harness.lnk"
    Else
        lnk = shell.SpecialFolders("Programs") & "\DeepSeek Harness.lnk"
    End If
    If Not fso.FileExists(lnk) Then
        Dim sc
        Set sc = shell.CreateShortcut(lnk)
        sc.TargetPath = shell.ExpandEnvironmentStrings("%WINDIR%") & "\System32\wscript.exe"
        sc.Arguments = "//B """ & WScript.ScriptFullName & """"
        If fso.FileExists(ScriptDir & "\deepseek.ico") Then sc.IconLocation = ScriptDir & "\deepseek.ico"
        sc.Description = "DeepSeek Harness"
        sc.Save()
    End If
Next

' 1) update check: async when service is already running (skips install, opens instantly);
'    synchronous on cold start so a pending update installs safely BEFORE the service starts
If fso.FileExists(Ps1File) Then
    shell.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & Ps1File & """ -UpdateCheck", 0, (Not IsWebUp())
End If

' 2) start dsh web hidden if not running (lock-protected, waits until ready)
If Not IsWebUp() Then
    shell.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & Ps1File & """ -StartService", 0, True
    If Not IsWebUp() Then
        fso.CreateTextFile(ErrLog, True).WriteLine "ERROR: dsh web failed to start within 90s. See log: " & OutLog
        MsgBox "dsh web 服务启动失败（90 秒超时）。请稍后重试；若反复失败，重新运行安装包里的'双击安装.bat'。" & vbCrLf & "Failed to start the dsh web service within 90s. Please retry, or re-run '双击安装.bat'." & vbCrLf & vbCrLf & "Log: " & ErrLog, vbExclamation, "DeepSeek Harness"
        WScript.Quit 1
    End If
End If

' 3) open Edge standalone app window (no tabs, no address bar)
shell.Run """" & edge & """ --app=" & Url, 1, False
