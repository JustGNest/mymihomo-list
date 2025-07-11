#Persistent
#SingleInstance force
;@Ahk2Exe-SetProductName ppttimer
;@Ahk2Exe-SetVersion 0.7

global pt_IniFile := A_ScriptDir "\ppttimer.ini"
global lastProfile, profiles := [], MonitorCount, lastMonitor, manualModeSupressDetection, showOnAllMonitors, isPptTimerOn
global startKey, stopKey, resetKey, pauseKey, quitKey, moveKey, allMonitorKey
global opacity, fontface, fontweight, fontsize, indicator_fontsize := 12, textColor, AheadColor, timeoutColor, backgroundColor, bannerWidth, bannerHeight, bannerPosition, bannerMargin, stopResetsTimer,  pt_Duration, pt_Ahead, pt_PlayFinishSound, pt_FinishSoundFile, pt_PlayWarningSound, pt_WarningSoundFile, sendOnTimeout
global currentIndicator := ""
global Guis := [], Texts := [], Indicators := [], defaultFont := GuiDefaultFont()
global settingsMenuItems := []

SysGet, MonitorCount, MonitorCount
Loop, %MonitorCount% {
  DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
  Gui, New, +HwndhCountDown
  Gui, -DPIScale +AlwaysOnTop +LastFound +ToolWindow -Caption
  Gui Add, Text, x0 y0 HwndhDurationText
  Gui Add, Text, x0 y0 HwndhIndicatorText
  GuiControl, +0x200 +center, %hDurationText%
  GuiControl, +0x200 BackgroundTrans, %hIndicatorText%
  Winset, ExStyle, +0x20
  Guis.push(hCountDown)
  Texts.push(hDurationText)
  Indicators.push(hIndicatorText)
}

loadSettings()
creatMenus()
createSettingsMenu()

isPptTimerOn := false
resetTimer()
SetTimer, checkFullscreenWindow, 250
return
;;;;;;;;;; SUBRUTINES ;;;;;;;;;;

createSettingsMenu() {
    ; 主设置菜单
    Menu, SettingsMenu, Add, 字体设置, :FontMenu
    Menu, SettingsMenu, Add, 颜色设置, :ColorMenu
    Menu, SettingsMenu, Add, 显示设置, :DisplayMenu
    Menu, SettingsMenu, Add, 计时设置, :TimerMenu
    Menu, SettingsMenu, Add, 声音设置, :SoundMenu
    Menu, SettingsMenu, Add, 快捷键设置, :ShortcutMenu
    Menu, SettingsMenu, Add, 其他设置, :OtherMenu
    
    ; 字体子菜单
    Menu, FontMenu, Add, 字体名称, MenuFontFace
    Menu, FontMenu, Add, 字体大小, MenuFontSize
    Menu, FontMenu, Add, 字体粗细, MenuFontWeight
    
    ; 颜色子菜单
    Menu, ColorMenu, Add, 文字颜色, MenuTextColor
    Menu, ColorMenu, Add, 提前警告颜色, MenuAheadColor
    Menu, ColorMenu, Add, 超时颜色, MenuTimeoutColor
    Menu, ColorMenu, Add, 背景颜色, MenuBackgroundColor
    
    ; 显示子菜单
    Menu, DisplayMenu, Add, 透明度, MenuOpacity
    Menu, DisplayMenu, Add, 横幅宽度, MenuBannerWidth
    Menu, DisplayMenu, Add, 横幅高度, MenuBannerHeight
    Menu, DisplayMenu, Add, 显示位置, MenuBannerPosition
    Menu, DisplayMenu, Add, 边距, MenuBannerMargin
    
    ; 计时子菜单
    Menu, TimerMenu, Add, 总计时长(秒), MenuDuration
    Menu, TimerMenu, Add, 提前警告时间(秒), MenuAheadTime
    
    ; 声音子菜单
    Menu, SoundMenu, Add, 播放警告声音, MenuPlayWarningSound
    Menu, SoundMenu, Add, 警告声音文件, MenuWarningSoundFile
    Menu, SoundMenu, Add, 播放结束声音, MenuPlayFinishSound
    Menu, SoundMenu, Add, 结束声音文件, MenuFinishSoundFile
    
    ; 快捷键子菜单
    Menu, ShortcutMenu, Add, 开始快捷键, MenuStartKey
    Menu, ShortcutMenu, Add, 停止快捷键, MenuStopKey
    Menu, ShortcutMenu, Add, 重置快捷键, MenuResetKey
    Menu, ShortcutMenu, Add, 暂停快捷键, MenuPauseKey
    Menu, ShortcutMenu, Add, 退出快捷键, MenuQuitKey
    Menu, ShortcutMenu, Add, 移动快捷键, MenuMoveKey
    Menu, ShortcutMenu, Add, 全屏显示快捷键, MenuAllMonitorKey
    
    ; 其他子菜单
    Menu, OtherMenu, Add, 手动模式禁止检测, MenuManualMode
    Menu, OtherMenu, Add, 停止时重置计时器, MenuStopResetsTimer
    Menu, OtherMenu, Add, 超时发送按键, MenuSendOnTimeout
    
    ; 将设置菜单添加到主菜单
    Menu, MainMenu, Add, 设置, :SettingsMenu
    Menu, Tray, Add, 设置, :SettingsMenu
}

; 字体设置菜单项
MenuFontFace:
    InputBox, newFontFace, 设置字体名称, 请输入字体名称:,, 300, 150,,,,, %fontface%
    if (!ErrorLevel && newFontFace != "") {
        fontface := newFontFace
        saveSetting("Main", "fontface", fontface)
        refreshUI()
    }
return

MenuFontSize:
    InputBox, newFontSize, 设置字体大小, 请输入字体大小(单位:像素):,, 300, 150,,,,, %fontsize%
    if (!ErrorLevel && newFontSize != "") {
        fontsize := newFontSize
        saveSetting("Main", "fontsize", fontsize)
        refreshUI()
    }
return

MenuFontWeight:
    InputBox, newFontWeight, 设置字体粗细, 请输入字体粗细(如:normal,bold):,, 300, 150,,,,, %fontweight%
    if (!ErrorLevel && newFontWeight != "") {
        fontweight := newFontWeight
        saveSetting("Main", "fontweight", fontweight)
        refreshUI()
    }
return
; 颜色设置菜单项
MenuTextColor:
    InputBox, newTextColor, 设置文字颜色, 请输入文字颜色(十六进制,如FFFFFF):,, 300, 150,,,,, %textColor%
    if (!ErrorLevel && newTextColor != "") {
        textColor := newTextColor
        saveSetting("Main", "textcolor", textColor)
        refreshUI()
    }
return

MenuAheadColor:
    InputBox, newAheadColor, 设置提前警告颜色, 请输入提前警告颜色(十六进制,如FF0000):,, 300, 150,,,,, %AheadColor%
    if (!ErrorLevel && newAheadColor != "") {
        AheadColor := newAheadColor
        saveSetting("Main", "aheadColor", AheadColor)
        refreshUI()
    }
return

MenuTimeoutColor:
    InputBox, newTimeoutColor, 设置超时颜色, 请输入超时颜色(十六进制,如FF0000):,, 300, 150,,,,, %timeoutColor%
    if (!ErrorLevel && newTimeoutColor != "") {
        timeoutColor := newTimeoutColor
        saveSetting("Main", "timeoutColor", timeoutColor)
        refreshUI()
    }
return

MenuBackgroundColor:
    InputBox, newBackgroundColor, 设置背景颜色, 请输入背景颜色(十六进制,如FFFFAA):,, 300, 150,,,,, %backgroundColor%
    if (!ErrorLevel && newBackgroundColor != "") {
        backgroundColor := newBackgroundColor
        saveSetting("Main", "backgroundColor", backgroundColor)
        refreshUI()
    }
return

; 显示设置菜单项
MenuOpacity:
    InputBox, newOpacity, 设置透明度, 请输入透明度(0-255):,, 300, 150,,,,, %opacity%
    if (!ErrorLevel && newOpacity != "") {
        opacity := newOpacity
        saveSetting("Main", "opacity", opacity)
        refreshUI()
    }
return

MenuBannerWidth:
    InputBox, newBannerWidth, 设置横幅宽度, 请输入横幅宽度(像素):,, 300, 150,,,,, %bannerWidth%
    if (!ErrorLevel && newBannerWidth != "") {
        bannerWidth := newBannerWidth
        saveSetting("Main", "width", bannerWidth)
        refreshUI()
    }
return

MenuBannerHeight:
    InputBox, newBannerHeight, 设置横幅高度, 请输入横幅高度(像素):,, 300, 150,,,,, %bannerHeight%
    if (!ErrorLevel && newBannerHeight != "") {
        bannerHeight := newBannerHeight
        saveSetting("Main", "height", bannerHeight)
        refreshUI()
    }
return

MenuBannerPosition:
    positions := "LT,RT,MT,LB,MB,RB"
    InputBox, newBannerPosition, 设置显示位置, 请输入显示位置(LT,RT,MT,LB,MB,RB):,, 300, 150,,,,, %bannerPosition%
    if (!ErrorLevel && newBannerPosition != "" && InStr(positions, newBannerPosition)) {
        bannerPosition := newBannerPosition
        saveSetting("Main", "position", bannerPosition)
        refreshUI()
    }
return

MenuBannerMargin:
    InputBox, newBannerMargin, 设置边距, 请输入边距(像素):,, 300, 150,,,,, %bannerMargin%
    if (!ErrorLevel && newBannerMargin != "") {
        bannerMargin := newBannerMargin
        saveSetting("Main", "margin", bannerMargin)
        refreshUI()
    }
return
; 计时设置菜单项
MenuDuration:
    InputBox, newDuration, 设置总计时长, 请输入总计时长(秒):,, 300, 150,,,,, %pt_Duration%
    if (!ErrorLevel && newDuration != "") {
        pt_Duration := newDuration
        saveSetting("Main", "duration", pt_Duration)
        resetTimer()
    }
return

MenuAheadTime:
    InputBox, newAheadTime, 设置提前警告时间, 请输入提前警告时间(秒):,, 300, 150,,,,, %pt_Ahead%
    if (!ErrorLevel && newAheadTime != "") {
        pt_Ahead := newAheadTime
        saveSetting("Main", "ahead", pt_Ahead)
    }
return

; 声音设置菜单项
MenuPlayWarningSound:
    warningSoundState := pt_PlayWarningSound ? "关闭" : "开启"
    MsgBox, 4,, 当前警告声音状态: %warningSoundState%`n是否切换状态?
    IfMsgBox Yes
    {
        pt_PlayWarningSound := !pt_PlayWarningSound
        saveSetting("Main", "playWarningSound", pt_PlayWarningSound)
    }
return

MenuWarningSoundFile:
    FileSelectFile, newWarningSoundFile, 3, %A_MyDocuments%, 选择警告声音文件, 声音文件 (*.wav; *.mp3)
    if (newWarningSoundFile != "") {
        pt_WarningSoundFile := newWarningSoundFile
        saveSetting("Main", "warningSoundFile", pt_WarningSoundFile)
    }
return

MenuPlayFinishSound:
    finishSoundState := pt_PlayFinishSound ? "关闭" : "开启"
    MsgBox, 4,, 当前结束声音状态: %finishSoundState%`n是否切换状态?
    IfMsgBox Yes
    {
        pt_PlayFinishSound := !pt_PlayFinishSound
        saveSetting("Main", "playFinishSound", pt_PlayFinishSound)
    }
return

MenuFinishSoundFile:
    FileSelectFile, newFinishSoundFile, 3, %A_MyDocuments%, 选择结束声音文件, 声音文件 (*.wav; *.mp3)
    if (newFinishSoundFile != "") {
        pt_FinishSoundFile := newFinishSoundFile
        saveSetting("Main", "finishSoundFile", pt_FinishSoundFile)
    }
return

; 快捷键设置菜单项
MenuStartKey:
    Hotkey, %startKey%, off
    InputBox, newStartKey, 设置开始快捷键, 请输入新的开始快捷键(如F5):,, 300, 150,,,,, %startKey%
    if (!ErrorLevel && newStartKey != "") {
        startKey := newStartKey
        saveSetting("Hotkeys", "start", startKey)
        Hotkey, %startKey%, startTimer, On
    }
return

MenuStopKey:
    Hotkey, %stopKey%, off
    InputBox, newStopKey, 设置停止快捷键, 请输入新的停止快捷键(如F6):,, 300, 150,,,,, %stopKey%
    if (!ErrorLevel && newStopKey != "") {
        stopKey := newStopKey
        saveSetting("Hotkeys", "stop", stopKey)
        Hotkey, %stopKey%, stopTimer, On
    }
return

MenuResetKey:
    Hotkey, %resetKey%, off
    InputBox, newResetKey, 设置重置快捷键, 请输入新的重置快捷键(如F7):,, 300, 150,,,,, %resetKey%
    if (!ErrorLevel && newResetKey != "") {
        resetKey := newResetKey
        saveSetting("Hotkeys", "reset", resetKey)
        Hotkey, %resetKey%, resetTimer, On
    }
return

MenuPauseKey:
    Hotkey, %pauseKey%, off
    InputBox, newPauseKey, 设置暂停快捷键, 请输入新的暂停快捷键(如F8):,, 300, 150,,,,, %pauseKey%
    if (!ErrorLevel && newPauseKey != "") {
        pauseKey := newPauseKey
        saveSetting("Hotkeys", "pause", pauseKey)
        Hotkey, %pauseKey%, pauseTimer, On
    }
return
; 其他设置菜单项
MenuManualMode:
    manualModeState := pt_ManualMode ? "关闭" : "开启"
    MsgBox, 4,, 当前手动模式状态: %manualModeState%`n是否切换状态?
    IfMsgBox Yes
    {
        pt_ManualMode := !pt_ManualMode
        saveSetting("Main", "manualMode", pt_ManualMode)
    }
return

MenuStopResetsTimer:
    stopResetsState := pt_StopResetsTimer ? "关闭" : "开启"
    MsgBox, 4,, 当前停止重置状态: %stopResetsState%`n是否切换状态?
    IfMsgBox Yes
    {
        pt_StopResetsTimer := !pt_StopResetsTimer
        saveSetting("Main", "stopResetsTimer", pt_StopResetsTimer)
    }
return

MenuSendOnTimeout:
    InputBox, newSendOnTimeout, 设置超时发送按键, 请输入超时时要发送的按键(如Enter):,, 300, 150,,,,, %pt_SendOnTimeout%
    if (!ErrorLevel) {
        pt_SendOnTimeout := newSendOnTimeout
        saveSetting("Main", "sendOnTimeout", pt_SendOnTimeout)
    }
return

; 移动窗口功能
moveWindow:
    CoordMode, Mouse, Screen
    MouseGetPos, moveStartX, moveStartY
    WinGetPos, winX, winY,,, ahk_id %hBanner%
    offsetX := winX - moveStartX
    offsetY := winY - moveStartY
    
    SetTimer, updateWindowPosition, 10
    KeyWait, LButton
    SetTimer, updateWindowPosition, Off
    
    ; 保存新位置
    WinGetPos, newX, newY,,, ahk_id %hBanner%
    saveWindowPosition(newX, newY)
return

updateWindowPosition:
    MouseGetPos, currentX, currentY
    newX := currentX + offsetX
    newY := currentY + offsetY
    WinMove, ahk_id %hBanner%,, newX, newY
return

saveWindowPosition(x, y) {
    global bannerPosition
    ; 根据位置自动设置位置标记
    SysGet, screenWidth, 78
    SysGet, screenHeight, 79
    
    if (x < screenWidth/3) {
        if (y < screenHeight/2) {
            bannerPosition := "LT"
        } else {
            bannerPosition := "LB"
        }
    } else if (x > screenWidth*2/3) {
        if (y < screenHeight/2) {
            bannerPosition := "RT"
        } else {
            bannerPosition := "RB"
        }
    } else {
        if (y < screenHeight/2) {
            bannerPosition := "MT"
        } else {
            bannerPosition := "MB"
        }
    }
    
    saveSetting("Main", "position", bannerPosition)
    saveSetting("Main", "customX", x)
    saveSetting("Main", "customY", y)
}

; 全屏显示功能
allMonitorKey:
    if (allMonitorsActive) {
        ; 关闭所有额外显示器上的窗口
        Loop % monitorCount {
            if (A_Index > 1) {
                WinClose, % "ahk_id " extraMonitors[A_Index].hWnd
            }
        }
        allMonitorsActive := false
    } else {
        ; 在所有显示器上创建窗口
        SysGet, monitorCount, MonitorCount
        if (monitorCount > 1) {
            Loop % monitorCount {
                if (A_Index > 1) {
                    SysGet, mon, Monitor, %A_Index%
                    createExtraBanner(monLeft, monTop, monRight-monLeft, monBottom-monTop, A_Index)
                }
            }
            allMonitorsActive := true
        } else {
            MsgBox 未检测到多个显示器
        }
    }
return

createExtraBanner(x, y, w, h, monitorNum) {
    global extraMonitors
    extraMonitors[monitorNum] := {}
    extraMonitors[monitorNum].hWnd := createBannerWindow(x, y, w, h, true)
}
; 计时器核心功能
startTimer:
    if (pt_ManualMode) {
        InputBox, manualDuration, 手动输入时长, 请输入计时时长(秒):,, 300, 150
        if (ErrorLevel || manualDuration = "")
            return
        pt_Duration := manualDuration
        saveSetting("Main", "duration", pt_Duration)
    }
    
    if (timerRunning) {
        stopTimer()
        Sleep 100
    }
    
    startTime := A_TickCount
    endTime := startTime + (pt_Duration * 1000)
    aheadTime := endTime - (pt_Ahead * 1000)
    timerRunning := true
    timerPaused := false
    SetTimer, updateTimer, 50
    refreshUI()
    
    ; 播放开始音效
    if (pt_PlayStartSound && FileExist(pt_StartSoundFile)) {
        SoundPlay, % pt_StartSoundFile
    }
return

stopTimer:
    timerRunning := false
    SetTimer, updateTimer, Off
    
    if (pt_StopResetsTimer) {
        resetTimer()
    } else {
        refreshUI()
    }
    
    ; 播放停止音效
    if (pt_PlayStopSound && FileExist(pt_StopSoundFile)) {
        SoundPlay, % pt_StopSoundFile
    }
return

resetTimer:
    timerRunning := false
    timerPaused := false
    remainingTime := pt_Duration
    SetTimer, updateTimer, Off
    refreshUI()
return

pauseTimer:
    if (!timerRunning)
        return
    
    if (timerPaused) {
        ; 恢复计时
        endTime := A_TickCount + (remainingTime * 1000)
        aheadTime := endTime - (pt_Ahead * 1000)
        timerPaused := false
        SetTimer, updateTimer, 50
    } else {
        ; 暂停计时
        SetTimer, updateTimer, Off
        timerPaused := true
    }
    refreshUI()
return

updateTimer:
    currentTime := A_TickCount
    remainingTime := (endTime - currentTime) / 1000
    
    if (remainingTime <= 0) {
        ; 计时结束
        timerRunning := false
        SetTimer, updateTimer, Off
        remainingTime := 0
        
        ; 播放结束音效
        if (pt_PlayFinishSound && FileExist(pt_FinishSoundFile)) {
            SoundPlay, % pt_FinishSoundFile
        }
        
        ; 发送超时按键
        if (pt_SendOnTimeout != "") {
            Send, % pt_SendOnTimeout
        }
    } else if (currentTime >= aheadTime && !warningShown) {
        ; 提前警告
        warningShown := true
        
        ; 播放警告音效
        if (pt_PlayWarningSound && FileExist(pt_WarningSoundFile)) {
            SoundPlay, % pt_WarningSoundFile
        }
    }
    
    refreshUI()
return

; UI刷新逻辑
refreshUI() {
    global
    ; 计算显示时间
    if (timerRunning && !timerPaused) {
        currentTime := A_TickCount
        remainingTime := (endTime - currentTime) / 1000
    } else if (timerPaused) {
        remainingTime := remainingTime
    } else {
        remainingTime := pt_Duration
    }
    
    ; 格式化时间显示
    hours := Floor(remainingTime / 3600)
    minutes := Floor(Mod(remainingTime, 3600) / 60)
    seconds := Floor(Mod(remainingTime, 60))
    milliseconds := Round(Mod(remainingTime, 1) * 1000)
    
    timeText := Format("{1:02d}:{2:02d}:{3:02d}", hours, minutes, seconds)
    if (showMilliseconds) {
        timeText .= Format(".{1:03d}", milliseconds)
    }
    
    ; 确定显示颜色
    if (remainingTime <= 0) {
        displayColor := timeoutColor
    } else if (warningShown && remainingTime <= pt_Ahead) {
        displayColor := AheadColor
    } else {
        displayColor := textColor
    }
    
    ; 更新主窗口
    GuiControl, Banner:, TimeText, %timeText%
    GuiControl, Banner: +c%displayColor%, TimeText
    
    ; 更新额外显示器窗口
    if (allMonitorsActive) {
        Loop % monitorCount {
            if (A_Index > 1 && extraMonitors.HasKey(A_Index)) {
                GuiControl, % "Banner" A_Index ":", TimeText, %timeText%
                GuiControl, % "Banner" A_Index ": +c" displayColor, TimeText
            }
        }
    }
    
    ; 更新任务栏提示
    if (timerRunning) {
        if (timerPaused) {
            tipText := "已暂停 - " timeText
        } else {
            tipText := "计时中 - " timeText
        }
    } else {
        tipText := "就绪 - " timeText
    }
    Menu, Tray, Tip, %tipText%
}
; 创建主窗口
createBannerWindow(x := "", y := "", w := "", h := "", isExtra := false) {
    global
    local guiNum := isExtra ? "Banner" A_Index : "Banner"
    local guiTitle := isExtra ? "计时器 - 显示器" A_Index : "计时器"
    
    ; 设置默认窗口大小和位置
    if (w = "" || h = "") {
        w := bannerWidth
        h := bannerHeight
    }
    
    if (x = "" || y = "") {
        ; 使用保存的位置或默认位置
        if (bannerPosition != "") {
            positionWindowByFlag(bannerPosition, w, h)
            x := bannerX
            y := bannerY
        } else {
            x := A_ScreenWidth - w - 20
            y := 20
        }
    }
    
    ; 创建GUI
    Gui, %guiNum%:New, +AlwaysOnTop +ToolWindow -Caption +LastFound +E0x20
    hWnd := WinExist()
    
    if (!isExtra) {
        hBanner := hWnd
    }
    
    ; 设置窗口透明度
    WinSet, Transparent, %bannerTransparency%
    
    ; 添加时间显示控件
    Gui, %guiNum%:Font, s%textSize% c%textColor% Bold, %textFont%
    Gui, %guiNum%:Add, Text, vTimeText Center x0 y0 w%w% h%h%, 00:00:00
    
    ; 设置窗口背景颜色
    Gui, %guiNum%:Color, %backgroundColor%
    
    ; 显示窗口
    Gui, %guiNum%:Show, x%x% y%y% w%w% h%h% NoActivate, %guiTitle%
    
    ; 为拖动窗口添加热键
    if (!isExtra) {
        Hotkey, IfWinActive, ahk_id %hWnd%
        Hotkey, ~LButton, moveWindow, On
        Hotkey, IfWinActive
    }
    
    return hWnd
}

; 根据位置标记设置窗口位置
positionWindowByFlag(position, w, h) {
    global bannerX, bannerY
    SysGet, screenWidth, 78
    SysGet, screenHeight, 79
    
    switch position {
        case "LT":  ; 左上
            bannerX := 10
            bannerY := 10
        case "MT":  ; 中上
            bannerX := (screenWidth - w) / 2
            bannerY := 10
        case "RT":  ; 右上
            bannerX := screenWidth - w - 10
            bannerY := 10
        case "LB":  ; 左下
            bannerX := 10
            bannerY := screenHeight - h - 10
        case "MB":  ; 中下
            bannerX := (screenWidth - w) / 2
            bannerY := screenHeight - h - 10
        case "RB":  ; 右下
            bannerX := screenWidth - w - 10
            bannerY := screenHeight - h - 10
        default:  ; 自定义位置
            bannerX := getSetting("Main", "customX", screenWidth - w - 20)
            bannerY := getSetting("Main", "customY", 20)
    }
}

; 初始化函数
initialize() {
    global
    
    ; 加载设置
    loadSettings()
    
    ; 创建主窗口
    createBannerWindow()
    
    ; 设置热键
    Hotkey, %startKey%, startTimer, On
    Hotkey, %stopKey%, stopTimer, On
    Hotkey, %resetKey%, resetTimer, On
    Hotkey, %pauseKey%, pauseTimer, On
    
    ; 初始化计时器状态
    remainingTime := pt_Duration
    refreshUI()
    
    ; 检查多显示器
    SysGet, monitorCount, MonitorCount
    if (monitorCount > 1) {
        Menu, Tray, Add, 全屏显示, allMonitorKey
    }
}

; 程序入口
#Persistent
SetBatchLines, -1
initialize()
return
; 设置文件操作函数
loadSettings() {
    global
    ; 初始化默认值
    pt_Duration := 300        ; 默认5分钟
    pt_Ahead := 30            ; 默认提前30秒警告
    pt_ManualMode := false    ; 默认关闭手动模式
    pt_StopResetsTimer := true ; 默认停止时重置计时器
    pt_SendOnTimeout := "Enter" ; 默认超时发送Enter键
    bannerPosition := "RB"    ; 默认右下角
    bannerTransparency := 220 ; 默认透明度
    textSize := 36            ; 默认字体大小
    textColor := "FFFFFF"     ; 默认白色文字
    backgroundColor := "000000" ; 默认黑色背景
    AheadColor := "FFA500"    ; 默认橙色警告
    timeoutColor := "FF0000"  ; 默认红色超时
    textFont := "Arial"       ; 默认字体
    showMilliseconds := false ; 默认不显示毫秒
    startKey := "^!s"         ; 默认Ctrl+Alt+S开始
    stopKey := "^!e"          ; 默认Ctrl+Alt+E停止
    resetKey := "^!r"         ; 默认Ctrl+Alt+R重置
    pauseKey := "^!p"         ; 默认Ctrl+Alt+P暂停
    
    ; 声音设置默认值
    pt_PlayStartSound := false
    pt_PlayStopSound := false
    pt_PlayWarningSound := true
    pt_PlayFinishSound := true
    pt_StartSoundFile := ""
    pt_StopSoundFile := ""
    pt_WarningSoundFile := ""
    pt_FinishSoundFile := ""
    
    ; 检查配置文件是否存在
    if (!FileExist(configFile)) {
        createDefaultConfig()
        return
    }
    
    ; 从配置文件加载设置
    IniRead, pt_Duration, %configFile%, Main, duration, %pt_Duration%
    IniRead, pt_Ahead, %configFile%, Main, ahead, %pt_Ahead%
    IniRead, pt_ManualMode, %configFile%, Main, manualMode, %pt_ManualMode%
    IniRead, pt_StopResetsTimer, %configFile%, Main, stopResetsTimer, %pt_StopResetsTimer%
    IniRead, pt_SendOnTimeout, %configFile%, Main, sendOnTimeout, %pt_SendOnTimeout%
    IniRead, bannerPosition, %configFile%, Main, position, %bannerPosition%
    IniRead, bannerTransparency, %configFile%, Main, transparency, %bannerTransparency%
    IniRead, textSize, %configFile%, Main, textSize, %textSize%
    IniRead, textColor, %configFile%, Main, textColor, %textColor%
    IniRead, backgroundColor, %configFile%, Main, backgroundColor, %backgroundColor%
    IniRead, AheadColor, %configFile%, Main, aheadColor, %AheadColor%
    IniRead, timeoutColor, %configFile%, Main, timeoutColor, %timeoutColor%
    IniRead, textFont, %configFile%, Main, textFont, %textFont%
    IniRead, showMilliseconds, %configFile%, Main, showMilliseconds, %showMilliseconds%
    IniRead, startKey, %configFile%, Hotkeys, startKey, %startKey%
    IniRead, stopKey, %configFile%, Hotkeys, stopKey, %stopKey%
    IniRead, resetKey, %configFile%, Hotkeys, resetKey, %resetKey%
    IniRead, pauseKey, %configFile%, Hotkeys, pauseKey, %pauseKey%
    
    ; 加载声音设置
    IniRead, pt_PlayStartSound, %configFile%, Sound, playStartSound, %pt_PlayStartSound%
    IniRead, pt_PlayStopSound, %configFile%, Sound, playStopSound, %pt_PlayStopSound%
    IniRead, pt_PlayWarningSound, %configFile%, Sound, playWarningSound, %pt_PlayWarningSound%
    IniRead, pt_PlayFinishSound, %configFile%, Sound, playFinishSound, %pt_PlayFinishSound%
    IniRead, pt_StartSoundFile, %configFile%, Sound, startSoundFile, %pt_StartSoundFile%
    IniRead, pt_StopSoundFile, %configFile%, Sound, stopSoundFile, %pt_StopSoundFile%
    IniRead, pt_WarningSoundFile, %configFile%, Sound, warningSoundFile, %pt_WarningSoundFile%
    IniRead, pt_FinishSoundFile, %configFile%, Sound, finishSoundFile, %pt_FinishSoundFile%
    
    ; 加载窗口位置
    bannerX := getSetting("Main", "customX", A_ScreenWidth - bannerWidth - 20)
    bannerY := getSetting("Main", "customY", 20)
}

createDefaultConfig() {
    global configFile
    ; 创建默认配置文件
    saveSetting("Main", "duration", 300)
    saveSetting("Main", "ahead", 30)
    saveSetting("Main", "manualMode", 0)
    saveSetting("Main", "stopResetsTimer", 1)
    saveSetting("Main", "sendOnTimeout", "Enter")
    saveSetting("Main", "position", "RB")
    saveSetting("Main", "transparency", 220)
    saveSetting("Main", "textSize", 36)
    saveSetting("Main", "textColor", "FFFFFF")
    saveSetting("Main", "backgroundColor", "000000")
    saveSetting("Main", "aheadColor", "FFA500")
    saveSetting("Main", "timeoutColor", "FF0000")
    saveSetting("Main", "textFont", "Arial")
    saveSetting("Main", "showMilliseconds", 0)
    saveSetting("Hotkeys", "startKey", "^!s")
    saveSetting("Hotkeys", "stopKey", "^!e")
    saveSetting("Hotkeys", "resetKey", "^!r")
    saveSetting("Hotkeys", "pauseKey", "^!p")
    
    ; 保存声音设置默认值
    saveSetting("Sound", "playStartSound", 0)
    saveSetting("Sound", "playStopSound", 0)
    saveSetting("Sound", "playWarningSound", 1)
    saveSetting("Sound", "playFinishSound", 1)
    saveSetting("Sound", "startSoundFile", "")
    saveSetting("Sound", "stopSoundFile", "")
    saveSetting("Sound", "warningSoundFile", "")
    saveSetting("Sound", "finishSoundFile", "")
}

saveSetting(section, key, value) {
    global configFile
    IniWrite, %value%, %configFile%, %section%, %key%
}

getSetting(section, key, defaultValue := "") {
    global configFile
    IniRead, value, %configFile%, %section%, %key%, %defaultValue%
    return value
}

; 辅助函数
getColorRGB(color) {
    ; 将十六进制颜色转换为RGB值
    if (StrLen(color) = 6) {
        r := "0x" SubStr(color, 1, 2)
        g := "0x" SubStr(color, 3, 2)
        b := "0x" SubStr(color, 5, 2)
        return {r: r, g: g, b: b}
    }
    return {r: 0xFF, g: 0xFF, b: 0xFF} ; 默认白色
}

isValidHotkey(hotkey) {
    ; 简单的热键有效性检查
    try {
        Hotkey, %hotkey%,, UseErrorLevel
        return (ErrorLevel = 0)
    }
    return false
}

; 程序退出时保存设置
GuiClose:
ExitApp
return
; 多显示器支持
allMonitorKey:
    allMonitorsActive := !allMonitorsActive
    
    if (allMonitorsActive) {
        ; 在所有显示器上创建窗口
        SysGet, monitorCount, MonitorCount
        extraMonitors := {}
        
        Loop % monitorCount {
            if (A_Index = 1)  ; 跳过主显示器(已存在主窗口)
                continue
            
            SysGet, monitorInfo, Monitor, %A_Index%
            monitorWidth := monitorInfoRight - monitorInfoLeft
            monitorHeight := monitorInfoBottom - monitorInfoTop
            
            ; 计算窗口位置(右下角)
            winX := monitorInfoRight - bannerWidth - 20
            winY := monitorInfoBottom - bannerHeight - 20
            
            ; 创建额外显示器窗口
            hWnd := createBannerWindow(winX, winY, bannerWidth, bannerHeight, true)
            extraMonitors[A_Index] := hWnd
        }
    } else {
        ; 关闭所有额外显示器窗口
        Loop % monitorCount {
            if (A_Index > 1 && extraMonitors.HasKey(A_Index)) {
                Gui, % "Banner" A_Index ":Destroy"
            }
        }
        extraMonitors := {}
    }
    
    ; 更新菜单状态
    Menu, Tray, ToggleCheck, 全屏显示
    refreshUI()
return

; 窗口拖动功能
moveWindow:
    PostMessage, 0xA1, 2,,, A  ; 发送拖动消息
    while GetKeyState("LButton", "P") {
        Sleep 10
    }
    
    ; 保存新位置
    WinGetPos, newX, newY,,, ahk_id %hBanner%
    bannerX := newX
    bannerY := newY
    
    ; 标记为自定义位置并保存
    bannerPosition := "Custom"
    saveSetting("Main", "customX", bannerX)
    saveSetting("Main", "customY", bannerY)
    saveSetting("Main", "position", bannerPosition)
return

; 系统托盘菜单
createTrayMenu() {
    Menu, Tray, NoStandard
    Menu, Tray, Add, 开始计时, startTimer
    Menu, Tray, Add, 停止计时, stopTimer
    Menu, Tray, Add, 重置计时器, resetTimer
    Menu, Tray, Add, 暂停/继续, pauseTimer
    Menu, Tray, Add
    Menu, Tray, Add, 设置..., showSettings
    Menu, Tray, Add, 窗口位置, windowPositionMenu
    Menu, Tray, Add, 全屏显示, allMonitorKey
    Menu, Tray, Add
    Menu, Tray, Add, 显示/隐藏窗口, toggleWindow
    Menu, Tray, Add, 退出, GuiClose
    Menu, Tray, Default, 开始计时
    Menu, Tray, Tip, 计时器
}

; 窗口位置子菜单
windowPositionMenu:
    Menu, PositionMenu, Add, 左上角, setWindowPosition
    Menu, PositionMenu, Add, 中上, setWindowPosition
    Menu, PositionMenu, Add, 右上角, setWindowPosition
    Menu, PositionMenu, Add
    Menu, PositionMenu, Add, 左下角, setWindowPosition
    Menu, PositionMenu, Add, 中下, setWindowPosition
    Menu, PositionMenu, Add, 右下角, setWindowPosition
    Menu, PositionMenu, Add
    Menu, PositionMenu, Add, 自定义位置, setWindowPosition
    Menu, PositionMenu, Show
return

setWindowPosition:
    bannerPosition := A_ThisMenuItem = "自定义位置" ? "Custom" : 
                    (A_ThisMenuItem = "左上角" ? "LT" : 
                    (A_ThisMenuItem = "中上" ? "MT" : 
                    (A_ThisMenuItem = "右上角" ? "RT" : 
                    (A_ThisMenuItem = "左下角" ? "LB" : 
                    (A_ThisMenuItem = "中下" ? "MB" : "RB")))))
    
    if (bannerPosition != "Custom") {
        positionWindowByFlag(bannerPosition, bannerWidth, bannerHeight)
        saveSetting("Main", "position", bannerPosition)
        
        ; 重新创建窗口
        recreateWindows()
    }
return

; 窗口显示/隐藏
toggleWindow:
    if (WinExist("ahk_id " hBanner)) {
        Gui, Banner:Hide
    } else {
        Gui, Banner:Show, NoActivate
    }
    
    ; 更新额外显示器窗口状态
    if (allMonitorsActive) {
        Loop % monitorCount {
            if (A_Index > 1 && extraMonitors.HasKey(A_Index)) {
                if (WinExist("ahk_id " hBanner)) {
                    Gui, % "Banner" A_Index ":Show", NoActivate
                } else {
                    Gui, % "Banner" A_Index ":Hide"
                }
            }
        }
    }
return

; 重新创建所有窗口
recreateWindows() {
    global
    
    ; 销毁所有窗口
    Gui, Banner:Destroy
    
    if (allMonitorsActive) {
        Loop % monitorCount {
            if (A_Index > 1 && extraMonitors.HasKey(A_Index)) {
                Gui, % "Banner" A_Index ":Destroy"
            }
        }
    }
    
    ; 重新创建主窗口
    createBannerWindow(bannerX, bannerY, bannerWidth, bannerHeight)
    
    ; 重新创建额外显示器窗口
    if (allMonitorsActive) {
        SysGet, monitorCount, MonitorCount
        extraMonitors := {}
        
        Loop % monitorCount {
            if (A_Index = 1)  ; 跳过主显示器
                continue
            
            SysGet, monitorInfo, Monitor, %A_Index%
            monitorWidth := monitorInfoRight - monitorInfoLeft
            monitorHeight := monitorInfoBottom - monitorInfoTop
            
            ; 计算窗口位置(与主窗口相同相对位置)
            winX := monitorInfoLeft + (bannerX - A_ScreenLeft)
            winY := monitorInfoTop + (bannerY - A_ScreenTop)
            
            ; 创建额外显示器窗口
            hWnd := createBannerWindow(winX, winY, bannerWidth, bannerHeight, true)
            extraMonitors[A_Index] := hWnd
        }
    }
    
    refreshUI()
}

; 在初始化函数中添加托盘菜单创建
initialize() {
    global
    
    ; 加载设置
    loadSettings()
    
    ; 创建托盘菜单
    createTrayMenu()
    
    ; 创建主窗口
    createBannerWindow()
    
    ; 设置热键
    Hotkey, %startKey%, startTimer, On
    Hotkey, %stopKey%, stopTimer, On
    Hotkey, %resetKey%, resetTimer, On
    Hotkey, %pauseKey%, pauseTimer, On
    
    ; 初始化计时器状态
    remainingTime := pt_Duration
    refreshUI()
    
    ; 检查多显示器
    SysGet, monitorCount, MonitorCount
    if (monitorCount > 1) {
        Menu, Tray, Add, 全屏显示, allMonitorKey
    }
}
; 计时器核心功能
startTimer:
    if (timerRunning)  ; 已经在运行则不做处理
        return
        
    ; 检查是否需要重置计时器
    if (pt_StopResetsTimer || remainingTime <= 0) {
        remainingTime := pt_Duration
    }
    
    ; 播放开始音效
    if (pt_PlayStartSound && pt_StartSoundFile != "") {
        SoundPlay, % pt_StartSoundFile
    }
    
    timerRunning := true
    timerPaused := false
    startTime := A_TickCount
    elapsedPausedTime := 0
    
    ; 设置定时器
    SetTimer, updateTimer, 50  ; 20次/秒更新
    
    ; 更新UI和菜单状态
    refreshUI()
    Menu, Tray, Enable, 停止计时
    Menu, Tray, Enable, 暂停/继续
    Menu, Tray, Disable, 开始计时
return

stopTimer:
    if (!timerRunning)
        return
        
    ; 停止计时器
    timerRunning := false
    SetTimer, updateTimer, Off
    
    ; 播放停止音效
    if (pt_PlayStopSound && pt_StopSoundFile != "") {
        SoundPlay, % pt_StopSoundFile
    }
    
    ; 更新UI和菜单状态
    refreshUI()
    Menu, Tray, Enable, 开始计时
    Menu, Tray, Disable, 停止计时
    Menu, Tray, Disable, 暂停/继续
return

resetTimer:
    remainingTime := pt_Duration
    timerRunning := false
    timerPaused := false
    SetTimer, updateTimer, Off
    
    ; 更新UI和菜单状态
    refreshUI()
    Menu, Tray, Enable, 开始计时
    Menu, Tray, Disable, 停止计时
    Menu, Tray, Disable, 暂停/继续
return

pauseTimer:
    if (!timerRunning)
        return
        
    timerPaused := !timerPaused
    
    if (timerPaused) {
        pauseStartTime := A_TickCount
        SetTimer, updateTimer, Off
    } else {
        elapsedPausedTime += A_TickCount - pauseStartTime
        SetTimer, updateTimer, 50
    }
    
    ; 更新UI和菜单状态
    refreshUI()
    Menu, Tray, Rename, 暂停/继续, % timerPaused ? "继续" : "暂停"
return

; 计时器更新逻辑
updateTimer:
    if (timerPaused)
        return
        
    elapsedTime := (A_TickCount - startTime - elapsedPausedTime) // 1000
    remainingTime := pt_Duration - elapsedTime
    
    ; 检查是否到达警告时间
    if (pt_Ahead > 0 && remainingTime = pt_Ahead && pt_PlayWarningSound && pt_WarningSoundFile != "") {
        SoundPlay, % pt_WarningSoundFile
    }
    
    ; 检查是否超时
    if (remainingTime <= 0) {
        remainingTime := 0
        timerRunning := false
        SetTimer, updateTimer, Off
        
        ; 播放完成音效
        if (pt_PlayFinishSound && pt_FinishSoundFile != "") {
            SoundPlay, % pt_FinishSoundFile
        }
        
        ; 发送超时按键
        if (pt_SendOnTimeout != "") {
            Send, % "{" pt_SendOnTimeout "}"
        }
        
        ; 更新菜单状态
        Menu, Tray, Enable, 开始计时
        Menu, Tray, Disable, 停止计时
        Menu, Tray, Disable, 暂停/继续
    }
    
    refreshUI()
return

; UI刷新函数
refreshUI() {
    global
    
    ; 计算显示的时间
    if (showMilliseconds && timerRunning && !timerPaused) {
        elapsedMs := Mod((A_TickCount - startTime - elapsedPausedTime), 1000)
        timeText := Format("{1:02d}:{2:02d}:{3:02d}.{4:03d}", remainingTime // 3600, Mod(remainingTime // 60, 60), Mod(remainingTime, 60), elapsedMs)
    } else {
        timeText := Format("{1:02d}:{2:02d}:{3:02d}", remainingTime // 3600, Mod(remainingTime // 60, 60), Mod(remainingTime, 60))
    }
    
    ; 确定文本颜色
    if (remainingTime <= 0) {
        currentColor := timeoutColor
    } else if (remainingTime <= pt_Ahead) {
        currentColor := AheadColor
    } else {
        currentColor := textColor
    }
    
    ; 更新主窗口
    GuiControl, Banner:, TimeText, %timeText%
    GuiControl, Banner:+c%currentColor%, TimeText
    
    ; 更新额外显示器窗口
    if (allMonitorsActive) {
        Loop % monitorCount {
            if (A_Index > 1 && extraMonitors.HasKey(A_Index)) {
                GuiControl, % "Banner" A_Index ":", TimeText, %timeText%
                GuiControl, % "Banner" A_Index ":+c" currentColor, TimeText
            }
        }
    }
    
    ; 更新托盘提示
    Menu, Tray, Tip, % "计时器 - " timeText "`n左键拖动窗口`n右键打开菜单"
}

; 窗口调整大小函数
adjustWindowSize() {
    global
    
    ; 根据文本大小重新计算窗口尺寸
    GuiControlGet, textSize, Banner:, TimeText
    bannerWidth := textSize * 8  ; 根据字体大小调整宽度
    bannerHeight := textSize * 1.5  ; 根据字体大小调整高度
    
    ; 重新创建窗口
    recreateWindows()
}

; 在初始化函数中添加热键注册
initialize() {
    global
    
    ; 加载设置
    loadSettings()
    
    ; 创建托盘菜单
    createTrayMenu()
    
    ; 创建主窗口
    createBannerWindow()
    
    ; 设置热键
    registerHotkey(startKey, "startTimer")
    registerHotkey(stopKey, "stopTimer")
    registerHotkey(resetKey, "resetTimer")
    registerHotkey(pauseKey, "pauseTimer")
    
    ; 初始化计时器状态
    remainingTime := pt_Duration
    refreshUI()
    
    ; 检查多显示器
    SysGet, monitorCount, MonitorCount
    if (monitorCount > 1) {
        Menu, Tray, Add, 全屏显示, allMonitorKey
    }
}

; 热键注册辅助函数
registerHotkey(hotkey, label) {
    if (hotkey != "") {
        try {
            Hotkey, %hotkey%, %label%, On
        } catch {
            MsgBox, 错误的热键设置: %hotkey%
        }
    }
}
; 设置界面GUI
showSettings:
    ; 如果设置窗口已存在则显示并返回
    if (IsObject(settingsGui)) {
        Gui, Settings:Show
        return
    }
    
    ; 创建设置窗口
    Gui, Settings:New, +LabelSettings +HwndhSettings, 计时器设置
    settingsGui := {hWnd: hSettings}
    
    ; 基本设置区域
    Gui, Settings:Font, s10, Arial
    Gui, Settings:Add, GroupBox, x10 y10 w450 h150, 基本设置
    
    ; 计时持续时间
    Gui, Settings:Add, Text, x20 y40, 计时持续时间(秒):
    Gui, Settings:Add, Edit, x150 y37 w60 Number Limit5 vnewDuration, % pt_Duration
    
    ; 提前警告时间
    Gui, Settings:Add, Text, x20 y70, 提前警告时间(秒):
    Gui, Settings:Add, Edit, x150 y67 w60 Number Limit5 vnewAhead, % pt_Ahead
    
    ; 手动模式
    Gui, Settings:Add, Text, x20 y100, 操作模式:
    Gui, Settings:Add, Radio, x150 y100 vnewManualMode Checked%pt_ManualMode%, 手动模式
    Gui, Settings:Add, Radio, x250 y100 Checked%!pt_ManualMode%, 自动模式
    
    ; 停止时重置计时器
    Gui, Settings:Add, Checkbox, x20 y130 vnewStopResetsTimer Checked%pt_StopResetsTimer%, 停止时重置计时器
    
    ; 超时发送按键
    Gui, Settings:Add, Text, x20 y160, 超时发送按键:
    Gui, Settings:Add, DropDownList, x150 y157 w100 vnewSendOnTimeout, Enter||Tab|Space|Esc|None
    
    ; 显示设置区域
    Gui, Settings:Add, GroupBox, x10 y190 w450 h180, 显示设置
    
    ; 窗口位置
    Gui, Settings:Add, Text, x20 y220, 窗口位置:
    Gui, Settings:Add, DropDownList, x150 y217 w100 vnewPosition, 左上角|中上|右上角||左下角|中下|右下角|自定义
    
    ; 窗口透明度
    Gui, Settings:Add, Text, x20 y250, 窗口透明度(0-255):
    Gui, Settings:Add, Slider, x150 y247 w200 Range0-255 TickInterval32 ToolTip vnewTransparency, % bannerTransparency
    
    ; 字体大小
    Gui, Settings:Add, Text, x20 y280, 字体大小:
    Gui, Settings:Add, Edit, x150 y277 w60 Number Limit3 vnewTextSize, % textSize
    
    ; 显示毫秒
    Gui, Settings:Add, Checkbox, x20 y310 vnewShowMilliseconds Checked%showMilliseconds%, 显示毫秒
    
    ; 颜色设置区域
    Gui, Settings:Add, GroupBox, x10 y380 w450 h120, 颜色设置
    
    ; 正常颜色
    Gui, Settings:Add, Text, x20 y410, 正常颜色:
    Gui, Settings:Add, Edit, x150 y407 w70 vnewTextColor, % textColor
    Gui, Settings:Add, Button, x230 y407 w30 gpickColor, 选择
    
    ; 警告颜色
    Gui, Settings:Add, Text, x20 y440, 警告颜色:
    Gui, Settings:Add, Edit, x150 y437 w70 vnewAheadColor, % AheadColor
    Gui, Settings:Add, Button, x230 y437 w30 gpickColor, 选择
    
    ; 超时颜色
    Gui, Settings:Add, Text, x20 y470, 超时颜色:
    Gui, Settings:Add, Edit, x150 y467 w70 vnewTimeoutColor, % timeoutColor
    Gui, Settings:Add, Button, x230 y467 w30 gpickColor, 选择
    
    ; 背景颜色
    Gui, Settings:Add, Text, x270 y410, 背景颜色:
    Gui, Settings:Add, Edit, x350 y407 w70 vnewBackgroundColor, % backgroundColor
    Gui, Settings:Add, Button, x430 y407 w30 gpickColor, 选择
    
    ; 声音设置区域
    Gui, Settings:Add, GroupBox, x470 y10 w300 h250, 声音设置
    
    ; 开始音效
    Gui, Settings:Add, Checkbox, x480 y40 vnewPlayStartSound Checked%pt_PlayStartSound%, 播放开始音效
    Gui, Settings:Add, Edit, x480 y70 w200 vnewStartSoundFile, % pt_StartSoundFile
    Gui, Settings:Add, Button, x690 y70 w70 gbrowseSoundFile, 浏览...
    
    ; 停止音效
    Gui, Settings:Add, Checkbox, x480 y110 vnewPlayStopSound Checked%pt_PlayStopSound%, 播放停止音效
    Gui, Settings:Add, Edit, x480 y140 w200 vnewStopSoundFile, % pt_StopSoundFile
    Gui, Settings:Add, Button, x690 y140 w70 gbrowseSoundFile, 浏览...
    
    ; 警告音效
    Gui, Settings:Add, Checkbox, x480 y180 vnewPlayWarningSound Checked%pt_PlayWarningSound%, 播放警告音效
    Gui, Settings:Add, Edit, x480 y210 w200 vnewWarningSoundFile, % pt_WarningSoundFile
    Gui, Settings:Add, Button, x690 y210 w70 gbrowseSoundFile, 浏览...
    
    ; 完成音效
    Gui, Settings:Add, Checkbox, x480 y250 vnewPlayFinishSound Checked%pt_PlayFinishSound%, 播放完成音效
    Gui, Settings:Add, Edit, x480 y280 w200 vnewFinishSoundFile, % pt_FinishSoundFile
    Gui, Settings:Add, Button, x690 y280 w70 gbrowseSoundFile, 浏览...
    
    ; 热键设置区域
    Gui, Settings:Add, GroupBox, x470 y270 w300 h230, 热键设置
    
    ; 开始热键
    Gui, Settings:Add, Text, x480 y300, 开始计时:
    Gui, Settings:Add, Hotkey, x550 y297 w120 vnewStartKey, % startKey
    
    ; 停止热键
    Gui, Settings:Add, Text, x480 y330, 停止计时:
    Gui, Settings:Add, Hotkey, x550 y327 w120 vnewStopKey, % stopKey
    
    ; 重置热键
    Gui, Settings:Add, Text, x480 y360, 重置计时器:
    Gui, Settings:Add, Hotkey, x550 y357 w120 vnewResetKey, % resetKey
    
    ; 暂停热键
    Gui, Settings:Add, Text, x480 y390, 暂停/继续:
    Gui, Settings:Add, Hotkey, x550 y387 w120 vnewPauseKey, % pauseKey
    
    ; 重置热键按钮
    Gui, Settings:Add, Button, x480 y430 w120 gresetHotkeys, 重置为默认热键
    
    ; 确定/取消按钮
    Gui, Settings:Add, Button, x580 y510 w100 gsaveSettings, 确定
    Gui, Settings:Add, Button, x690 y510 w80 gSettingsClose, 取消
    
    ; 显示设置窗口
    Gui, Settings:Show, w790 h550
return

; 颜色选择器
pickColor:
    Gui, Settings:Submit, NoHide
    ctrlName := A_GuiControl = "选择" ? A_GuiControl - 1 : A_GuiControl
    
    ; 获取当前颜色值
    GuiControlGet, currentColor, Settings:, %ctrlName%
    
    ; 显示颜色选择对话框
    Color := ChooseColor(currentColor)
    if (Color != "") {
        ; 更新颜色控件
        GuiControl, Settings:, %ctrlName%, %Color%
    }
return

; 浏览声音文件
browseSoundFile:
    Gui, Settings:Submit, NoHide
    ctrlName := A_GuiControl = "浏览..." ? A_GuiControl - 1 : A_GuiControl
    
    ; 显示文件选择对话框
    FileSelectFile, selectedFile, 3, , 选择声音文件, 声音文件 (*.wav; *.mp3; *.mid)
    if (selectedFile != "") {
        ; 更新文件路径控件
        GuiControl, Settings:, %ctrlName%, %selectedFile%
    }
return

; 重置热键为默认值
resetHotkeys:
    GuiControl, Settings:, newStartKey, ^!s
    GuiControl, Settings:, newStopKey, ^!e
    GuiControl, Settings:, newResetKey, ^!r
    GuiControl, Settings:, newPauseKey, ^!p
return

; 保存设置
saveSettings:
    Gui, Settings:Submit, NoHide
    
    ; 验证输入
    if (newDuration <= 0) {
        MsgBox, 请输入有效的计时持续时间
        return
    }
    
    if (newAhead < 0 || newAhead >= newDuration) {
        MsgBox, 提前警告时间必须小于计时持续时间
        return
    }
    
    ; 保存基本设置
    saveSetting("Main", "duration", newDuration)
    saveSetting("Main", "ahead", newAhead)
    saveSetting("Main", "manualMode", newManualMode)
    saveSetting("Main", "stopResetsTimer", newStopResetsTimer)
    saveSetting("Main", "sendOnTimeout", newSendOnTimeout)
    
    ; 保存显示设置
    saveSetting("Main", "position", newPosition)
    saveSetting("Main", "transparency", newTransparency)
    saveSetting("Main", "textSize", newTextSize)
    saveSetting("Main", "showMilliseconds", newShowMilliseconds)
    
    ; 保存颜色设置
    saveSetting("Main", "textColor", newTextColor)
    saveSetting("Main", "aheadColor", newAheadColor)
    saveSetting("Main", "timeoutColor", newTimeoutColor)
    saveSetting("Main", "backgroundColor", newBackgroundColor)
    
    ; 保存声音设置
    saveSetting("Sound", "playStartSound", newPlayStartSound)
    saveSetting("Sound", "playStopSound", newPlayStopSound)
    saveSetting("Sound", "playWarningSound", newPlayWarningSound)
    saveSetting("Sound", "playFinishSound", newPlayFinishSound)
    saveSetting("Sound", "startSoundFile", newStartSoundFile)
    saveSetting("Sound", "stopSoundFile", newStopSoundFile)
    saveSetting("Sound", "warningSoundFile", newWarningSoundFile)
    saveSetting("Sound", "finishSoundFile", newFinishSoundFile)
    
    ; 保存热键设置
    saveSetting("Hotkeys", "startKey", newStartKey)
    saveSetting("Hotkeys", "stopKey", newStopKey)
    saveSetting("Hotkeys", "resetKey", newResetKey)
    saveSetting("Hotkeys", "pauseKey", newPauseKey)
    
    ; 更新全局变量
    loadSettings()
    
    ; 重新创建窗口以应用新设置
    recreateWindows()
    
    ; 关闭设置窗口
    Gui, Settings:Destroy
    settingsGui := ""
return

SettingsClose:
SettingsEscape:
    Gui, Settings:Destroy
    settingsGui := ""
return
; 配置文件路径
global configFile := A_ScriptDir "\TimerConfig.ini"

; 加载设置
loadSettings() {
    global
    
    ; 如果配置文件不存在，则创建默认配置
    if (!FileExist(configFile)) {
        createDefaultConfig()
    }
    
    ; 加载主设置
    IniRead, pt_Duration, %configFile%, Main, duration, 300
    IniRead, pt_Ahead, %configFile%, Main, ahead, 60
    IniRead, pt_ManualMode, %configFile%, Main, manualMode, 0
    IniRead, pt_StopResetsTimer, %configFile%, Main, stopResetsTimer, 1
    IniRead, pt_SendOnTimeout, %configFile%, Main, sendOnTimeout, None
    
    ; 加载显示设置
    IniRead, bannerPosition, %configFile%, Main, position, RB
    IniRead, bannerTransparency, %configFile%, Main, transparency, 200
    IniRead, textSize, %configFile%, Main, textSize, 24
    IniRead, showMilliseconds, %configFile%, Main, showMilliseconds, 0
    
    ; 加载颜色设置
    IniRead, textColor, %configFile%, Main, textColor, FFFFFF
    IniRead, AheadColor, %configFile%, Main, aheadColor, FFFF00
    IniRead, timeoutColor, %configFile%, Main, timeoutColor, FF0000
    IniRead, backgroundColor, %configFile%, Main, backgroundColor, 000000
    
    ; 加载声音设置
    IniRead, pt_PlayStartSound, %configFile%, Sound, playStartSound, 1
    IniRead, pt_PlayStopSound, %configFile%, Sound, playStopSound, 1
    IniRead, pt_PlayWarningSound, %configFile%, Sound, playWarningSound, 1
    IniRead, pt_PlayFinishSound, %configFile%, Sound, playFinishSound, 1
    IniRead, pt_StartSoundFile, %configFile%, Sound, startSoundFile, %A_WinDir%\Media\notify.wav
    IniRead, pt_StopSoundFile, %configFile%, Sound, stopSoundFile, %A_WinDir%\Media\notify.wav
    IniRead, pt_WarningSoundFile, %configFile%, Sound, warningSoundFile, %A_WinDir%\Media\Alarm01.wav
    IniRead, pt_FinishSoundFile, %configFile%, Sound, finishSoundFile, %A_WinDir%\Media\Alarm02.wav
    
    ; 加载热键设置
    IniRead, startKey, %configFile%, Hotkeys, startKey, ^!s
    IniRead, stopKey, %configFile%, Hotkeys, stopKey, ^!e
    IniRead, resetKey, %configFile%, Hotkeys, resetKey, ^!r
    IniRead, pauseKey, %configFile%, Hotkeys, pauseKey, ^!p
    
    ; 加载自定义窗口位置
    IniRead, bannerX, %configFile%, Main, customX, % A_ScreenWidth - bannerWidth - 20
    IniRead, bannerY, %configFile%, Main, customY, % A_ScreenHeight - bannerHeight - 20
    
    ; 转换布尔值
    pt_ManualMode := (pt_ManualMode = "1")
    pt_StopResetsTimer := (pt_StopResetsTimer = "1")
    pt_PlayStartSound := (pt_PlayStartSound = "1")
    pt_PlayStopSound := (pt_PlayStopSound = "1")
    pt_PlayWarningSound := (pt_PlayWarningSound = "1")
    pt_PlayFinishSound := (pt_PlayFinishSound = "1")
    showMilliseconds := (showMilliseconds = "1")
    
    ; 初始化剩余时间
    remainingTime := pt_Duration
    
    ; 计算窗口尺寸
    bannerWidth := textSize * 10
    bannerHeight := textSize * 1.5
    
    ; 根据位置标志设置窗口坐标
    if (bannerPosition != "Custom") {
        positionWindowByFlag(bannerPosition, bannerWidth, bannerHeight)
    }
}

; 保存设置到INI文件
saveSetting(section, key, value) {
    global configFile
    
    ; 转换布尔值为1/0
    if (value = true || value = false) {
        value := value ? "1" : "0"
    }
    
    ; 写入INI文件
    IniWrite, %value%, %configFile%, %section%, %key%
}

; 创建默认配置文件
createDefaultConfig() {
    global configFile
    
    ; 主设置
    saveSetting("Main", "duration", 300)
    saveSetting("Main", "ahead", 60)
    saveSetting("Main", "manualMode", 0)
    saveSetting("Main", "stopResetsTimer", 1)
    saveSetting("Main", "sendOnTimeout", "None")
    
    ; 显示设置
    saveSetting("Main", "position", "RB")
    saveSetting("Main", "transparency", 200)
    saveSetting("Main", "textSize", 24)
    saveSetting("Main", "showMilliseconds", 0)
    
    ; 颜色设置
    saveSetting("Main", "textColor", "FFFFFF")
    saveSetting("Main", "aheadColor", "FFFF00")
    saveSetting("Main", "timeoutColor", "FF0000")
    saveSetting("Main", "backgroundColor", "000000")
    
    ; 声音设置
    saveSetting("Sound", "playStartSound", 1)
    saveSetting("Sound", "playStopSound", 1)
    saveSetting("Sound", "playWarningSound", 1)
    saveSetting("Sound", "playFinishSound", 1)
    saveSetting("Sound", "startSoundFile", A_WinDir "\Media\notify.wav")
    saveSetting("Sound", "stopSoundFile", A_WinDir "\Media\notify.wav")
    saveSetting("Sound", "warningSoundFile", A_WinDir "\Media\Alarm01.wav")
    saveSetting("Sound", "finishSoundFile", A_WinDir "\Media\Alarm02.wav")
    
    ; 热键设置
    saveSetting("Hotkeys", "startKey", "^!s")
    saveSetting("Hotkeys", "stopKey", "^!e")
    saveSetting("Hotkeys", "resetKey", "^!r")
    saveSetting("Hotkeys", "pauseKey", "^!p")
}

; 根据位置标志设置窗口坐标
positionWindowByFlag(flag, width, height) {
    global bannerX, bannerY
    
    switch flag
    {
        case "LT":  ; 左上角
            bannerX := 20
            bannerY := 20
        case "MT":  ; 中上
            bannerX := (A_ScreenWidth - width) // 2
            bannerY := 20
        case "RT":  ; 右上角
            bannerX := A_ScreenWidth - width - 20
            bannerY := 20
        case "LB":  ; 左下角
            bannerX := 20
            bannerY := A_ScreenHeight - height - 20
        case "MB":  ; 中下
            bannerX := (A_ScreenWidth - width) // 2
            bannerY := A_ScreenHeight - height - 20
        case "RB":  ; 右下角
            bannerX := A_ScreenWidth - width - 20
            bannerY := A_ScreenHeight - height - 20
    }
    
    ; 保存位置设置
    saveSetting("Main", "position", flag)
    saveSetting("Main", "customX", bannerX)
    saveSetting("Main", "customY", bannerY)
}

; 颜色选择对话框封装
ChooseColor(DefaultColor := "", Owner := "") {
    ; 创建自定义颜色数组
    CustomColors := []
    Loop 16 {
        CustomColors.Push("0x" SubStr(DefaultColor, (A_Index - 1) * 6 + 1, 6))
    }
    
    ; 准备颜色选择对话框结构
    VarSetCapacity(CHOOSECOLOR, 36 + (A_PtrSize * 3), 0)
    NumPut(36 + (A_PtrSize * 3), CHOOSECOLOR, 0, "UInt")  ; lStructSize
    NumPut(Owner ? Owner : 0, CHOOSECOLOR, A_PtrSize, "Ptr")  ; hwndOwner
    NumPut(&CustomColors, CHOOSECOLOR, 36, "Ptr")  ; lpCustColors
    
    ; 调用系统颜色选择对话框
    if (!DllCall("comdlg32\ChooseColor", "Ptr", &CHOOSECOLOR, "UInt")) {
        return ""
    }
    
    ; 提取选择的颜色
    ChosenColor := NumGet(CHOOSECOLOR, 16, "UInt")
    return Format("{:06X}", ChosenColor & 0xFFFFFF)
}
; 多显示器支持功能
allMonitorKey:
    allMonitorsActive := !allMonitorsActive
    
    if (allMonitorsActive) {
        ; 在所有显示器上创建窗口
        createExtraMonitorWindows()
    } else {
        ; 关闭所有额外显示器窗口
        closeExtraMonitorWindows()
    }
    
    ; 更新菜单状态
    Menu, Tray, ToggleCheck, 全屏显示
return

; 创建额外显示器窗口
createExtraMonitorWindows() {
    global
    
    ; 获取显示器数量
    SysGet, monitorCount, MonitorCount
    
    ; 为每个额外显示器创建窗口
    Loop % monitorCount {
        if (A_Index = 1)  ; 跳过主显示器(已存在主窗口)
            continue
            
        ; 获取显示器工作区域
        SysGet, monitorInfo, MonitorWorkArea, %A_Index%
        
        ; 计算窗口位置(右下角)
        winX := monitorInfoRight - bannerWidth - 20
        winY := monitorInfoBottom - bannerHeight - 20
        
        ; 创建窗口
        guiName := "Banner" A_Index
        Gui, %guiName%:New, +LabelBanner +HwndhWnd -Caption +ToolWindow +AlwaysOnTop
        Gui, %guiName%:Margin, 0, 0
        Gui, %guiName%:Color, %backgroundColor%
        Gui, %guiName%:Font, s%textSize% c%textColor%, Arial
        
        ; 添加时间文本控件
        Gui, %guiName%:Add, Text, vTimeText Center, 00:00:00
        
        ; 设置窗口透明度和位置
        WinSet, Transparent, %bannerTransparency%, ahk_id %hWnd%
        Gui, %guiName%:Show, x%winX% y%winY% w%bannerWidth% h%bannerHeight%, 计时器显示器%A_Index%
        
        ; 存储窗口句柄
        extraMonitors[A_Index] := {hWnd: hWnd, guiName: guiName}
        
        ; 启用拖动功能
        setWindowDrag(guiName, hWnd)
    }
    
    ; 刷新所有窗口显示
    refreshUI()
}

; 关闭额外显示器窗口
closeExtraMonitorWindows() {
    global extraMonitors
    
    ; 遍历所有额外窗口并关闭
    for index, monitor in extraMonitors {
        Gui, % monitor.guiName ":Destroy"
    }
    
    ; 清空存储的窗口信息
    extraMonitors := {}
}

; 窗口拖动功能
setWindowDrag(guiName, hWnd) {
    ; 为窗口添加鼠标事件处理
    GuiControl, %guiName%: +gstartWindowDrag, TimeText
    
    ; 存储窗口信息
    windowInfo := {guiName: guiName, hWnd: hWnd}
    windows[hWnd] := windowInfo
}

; 开始窗口拖动
startWindowDrag:
    ; 获取当前窗口信息
    MouseGetPos,,, hWndUnderMouse
    if (!windows.HasKey(hWndUnderMouse))
        return
        
    windowInfo := windows[hWndUnderMouse]
    
    ; 设置窗口拖动标志
    draggingWindow := true
    dragStartX := A_GuiX
    dragStartY := A_GuiY
    
    ; 设置鼠标捕获
    SetSystemCursor("IDC_SIZEALL")
    SetCapture(windowInfo.hWnd)
    
    ; 启动拖动跟踪
    SetTimer, trackWindowDrag, 10
return

; 跟踪窗口拖动
trackWindowDrag:
    if (!draggingWindow) {
        SetTimer, trackWindowDrag, Off
        return
    }
    
    ; 获取鼠标位置
    MouseGetPos, mouseX, mouseY
    
    ; 计算新窗口位置
    WinGetPos, winX, winY,,, ahk_id %hWndUnderMouse%
    newX := winX + (mouseX - dragStartX)
    newY := winY + (mouseY - dragStartY)
    
    ; 限制窗口在屏幕内
    newX := Max(0, Min(newX, A_ScreenWidth - bannerWidth))
    newY := Max(0, Min(newY, A_ScreenHeight - bannerHeight))
    
    ; 移动窗口
    WinMove, ahk_id %hWndUnderMouse%,, newX, newY
    
    ; 更新起始位置
    dragStartX := mouseX
    dragStartY := mouseY
    
    ; 如果是主窗口则保存位置
    if (hWndUnderMouse = mainHwnd) {
        bannerX := newX
        bannerY := newY
        saveSetting("Main", "position", "Custom")
        saveSetting("Main", "customX", bannerX)
        saveSetting("Main", "customY", bannerY)
    }
return

; 结束窗口拖动
stopWindowDrag() {
    global
    
    if (!draggingWindow)
        return
        
    draggingWindow := false
    ReleaseCapture()
    RestoreCursors()
    SetTimer, trackWindowDrag, Off
}

; 设置系统光标
SetSystemCursor(cursorName) {
    static blankCursor
    if (!blankCursor) {
        VarSetCapacity(blankCursor, 8, 0)
        DllCall("SetSystemCursor", "Ptr", &blankCursor, "Int", 32512)  ; IDC_ARROW
    }
    
    hCursor := DllCall("LoadCursor", "Ptr", 0, "Ptr", cursorName, "Ptr")
    DllCall("SetSystemCursor", "Ptr", hCursor, "Int", 32512)  ; IDC_ARROW
}

; 恢复光标
RestoreCursors() {
    DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)
}

; 设置鼠标捕获
SetCapture(hWnd) {
    DllCall("SetCapture", "Ptr", hWnd)
}

; 释放鼠标捕获
ReleaseCapture() {
    DllCall("ReleaseCapture")
}

; 重新创建所有窗口
recreateWindows() {
    global
    
    ; 关闭所有窗口
    Gui, Banner:Destroy
    closeExtraMonitorWindows()
    
    ; 重新创建主窗口
    createBannerWindow()
    
    ; 如果启用了多显示器支持，则重新创建额外窗口
    if (allMonitorsActive) {
        createExtraMonitorWindows()
    }
    
    ; 刷新显示
    refreshUI()
}

; 窗口调整大小函数
adjustWindowSize() {
    global
    
    ; 根据文本大小重新计算窗口尺寸
    GuiControlGet, textSize, Banner:, TimeText
    bannerWidth := textSize * 10  ; 根据字体大小调整宽度
    bannerHeight := textSize * 1.5  ; 根据字体大小调整高度
    
    ; 重新创建窗口
    recreateWindows()
}

; 窗口右键菜单
BannerContextMenu:
    ; 显示上下文菜单
    Menu, ContextMenu, Show, %A_GuiX%, %A_GuiY%
return

; 创建上下文菜单
createContextMenu() {
    Menu, ContextMenu, Add, 设置, showSettings
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, 开始计时, startTimer
    Menu, ContextMenu, Add, 停止计时, stopTimer
    Menu, ContextMenu, Add, 重置计时器, resetTimer
    Menu, ContextMenu, Add, 暂停/继续, pauseTimer
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, 退出, exitApp
}

; 窗口拖放支持
BannerDropFiles:
    ; 检查是否拖放了声音文件
    if (A_GuiEvent = "DropFiles") {
        Loop, parse, A_GuiControlEvent, `n
        {
            ; 检查文件扩展名
            if (A_LoopField ~= "\.(wav|mp3|mid)$") {
                ; 根据当前设置界面状态更新对应的声音文件路径
                if (IsObject(settingsGui)) {
                    Gui, Settings:Submit, NoHide
                    if (A_GuiControl = "TimeText") {
                        ; 默认更新开始音效
                        GuiControl, Settings:, newStartSoundFile, %A_LoopField%
                    }
                } else {
                    ; 直接更新开始音效
                    pt_StartSoundFile := A_LoopField
                    saveSetting("Sound", "startSoundFile", pt_StartSoundFile)
                }
                break
            }
        }
    }
return
