#SingleInstance, Force
#NoEnv
SetWorkingDir, A_ScriptDir
ListLines, Off
SetBatchLines, -1

#Include <JSON>
#Include <AppiumDriver>
OnMessage(0x201, "WM_LBUTTONDOWN")

; >>--++--<< Минимальные capabilities, необходимые для запуска теста >>--++--<<
	caps =
	(
		{
			"desiredCapabilities": {
				"platformName": "Android",
				"deviceName": "SelendroidTester",
				"app": "{}/apks/selendroid-test-app-0.17.0.apk"
			}
		}
	)
	caps := Format(caps, StrReplace(A_ScriptDir, "\", "/"))
; >>--++--<<  >>--++--<<
	gui_w := 500, gui_h := 220
	defaultPort := 4723, aDesktop := true
	autoConnect := false
; >>--++--<<  >>--++--<<
	guiColor := 0xA9A5A0
; >>--++--<<  >>--++--<<

Gui,1: Color,% guiColor
Gui,1: -Caption +HWNDmain_h
Gui,1: Margin, 10, 10
Gui,1: Add, Button,% Format("x{} ym-10 w{} h{} gReloadMe",gui_w-63,20,18),R
Gui,1: Add, Button,% Format("x+0 ym-10 w{} h{} gMiniMe",20,18),__
Gui,1: Add, Button,% Format("x+0 ym-10 w{} h{} gGuiClose",20,18),X
Gui,1: Font, Bold, Consolas
Gui,1: Add, Text,% Format("xm ym+15 w{} r6 Border v_statusText cBlue",gui_w - 20),Текст
Gui,1: Add, Text,% Format("xm y+5 w{} Border gCopySessionID v_sessionID cRed Border 0x0201",gui_w - 20),Ожидается идентификатор сессии ...
Gui,1: Font

Gui,1: Add, Button,% Format("xm y{} gResetApp",gui_h-80),ResetApp
Gui,1: Add, Button,x+10 gStopApp,StopApp
Gui,1: Add, Button,x+10 gStartApp,StartApp
Gui,1: Add, Button,x+10 gRunServer,Запустить сервер

Gui,1: Font, Bold
Gui,1: Add, Button,% Format("xm y{} v_runMB gRunMain",gui_h-50),Run MainBody
Gui,1: Font
Gui,1: Add, Button,x+10 gGetCurrentActivity,Get activity
Gui,1: Add, Button,x+10 gStartSession,Подключиться/Создать сессию
Gui,1: Add, Button,x+10 gStopSession,Завершить сессию

Gui,1: Add, StatusBar
Gui,1: Show,w%gui_w% h%gui_h%,Selendroid Tester
FrameShadow( main_h )
; >>--++--<<  >>--++--<<
	if (autoConnect) {
		SB_SetText("Подключение к Appium ...")
		Try
			GoSub, ConnectAppium
		Catch e {
			if (e.error == 1000)
				SB_SetText("Нет запущенных серверов")
		}
	}
; >>--++--<<  >>--++--<<
Return
GetCurrentActivity:
	SB_SetText("Текущая activity:`t" . (Clipboard := driver.GetCurrentActivity()))
Return
RunMain:
	if (thread_toggler := !thread_toggler) {
		Gui,1: Submit, NoHide
		SetTimer,MainBody,-1
		GuiControl,Text,_runMB,Stop MainBody
	} else {
		GuiControl,Text,_runMB,Run MainBody
	}
Return
ConnectAppium:
	Try {
		driver := new AppiumDriver(, defaultPort, aDesktop)
		SB_SetText("Подключён к текущей сессии")
	} Catch {
		driver := new AppiumDriver(caps, defaultPort, aDesktop)
		SB_SetText("Создана новая сессия")
	}
	GuiControl,Text,_sessionID,% "Идентификатор сессии:`t" driver._sessionID
Return
CopySessionID:
	if (A_GuiControlEvent == "DoubleClick") {
		if (driver) {
			Clipboard := driver._sessionID
			SB_SetText("ID сессии скопирован в буфер обмена")
		} else
			SB_SetText("Соединение не установлено")
	}
Return
;	###############################################################################################
MainBody:
{
	GuiControl,Text,_statusText,Ожидание кнопки с логотипом папки ...
	While !(folderButton := driver.FindElementByAccessibilityId("startUserRegistrationCD"))
		Sleep(1000)
	GuiControl,Text,_statusText,Кнопка найдена. Клик!
	Sleep(1000)
	folderButton.Click()
	GuiControl,Text,_statusText,Заполняем форму
	Sleep(1000)
	if (driver.IsKeyboardShown())
		driver.HideKeyboard()
	editUsername := driver.FindElementById("io.selendroid.testapp:id/inputUsername")
	editUsername.SetValue(A_UserName)
	driver.FindElementById("io.selendroid.testapp:id/inputEmail").ReplaceValue("script_coding@example_mail.ru")
	if (driver.IsKeyboardShown())
		driver.HideKeyboard()
	driver.FindElementById("io.selendroid.testapp:id/inputPassword").SendKeys("veryStrongPass!!11")
	if (driver.IsKeyboardShown())
		driver.HideKeyboard()
	mr_burns := driver.FindElementById("io.selendroid.testapp:id/inputName")
	mr_burns.Clear()
	if (driver.IsKeyboardShown())
		driver.HideKeyboard()
	mr_burns.SendKeys("Hello Android from AutoHotKey!")
	if (driver.IsKeyboardShown())
		driver.HideKeyboard()
	driver.FindElementById("io.selendroid.testapp:id/input_preferedProgrammingLanguage").Click()
	
	GuiControl,Text,_statusText,Выбираем 'Си Шарп'
	While !(listview_el := driver.FindElementById("android:id/select_dialog_listview"))
		Sleep(1000)
	While !(cSharp := driver.FindElementByXPath("//android.widget.CheckedTextView[contains(@text,'C#')]")) {
		listview_el.Flick(0, -300)
		Sleep(1000)
	}
	
	cSharp.Click()
	Sleep(1000)
	
	driver.FindElementByClassName("android.widget.ScrollView").Flick(0, -300)
	
	Sleep(1000)
	driver.FindElementById("io.selendroid.testapp:id/input_adds").Click()
	Sleep(1000)
	driver.FindElementById("io.selendroid.testapp:id/btnRegisterUser").Click()
	
	GuiControl,Text,_statusText,Выбираем текстовые поля с введёнными только что данными
	Sleep(1000), data := []
	textFields := driver.FindElementsByXPath("//android.widget.TableRow/android.widget.TextView[@index='1']")
	For index, element in textFields
		data.Push( element.GetText() )
	string := Format("Name '{}' | UserName '{}' | Password '{}' | E-Mail '{}' | Programming Language '{}' | I accept adds '{}'", data*)
	GuiControl,Text,_statusText,% string
	
	/*
	name		:= driver.FindElementById("io.selendroid.testapp:id/label_name_data").GetText()
	userName	:= driver.FindElementById("io.selendroid.testapp:id/label_username_data").GetText()
	pass		:= driver.FindElementById("io.selendroid.testapp:id/label_password_data").GetText()
	email		:= driver.FindElementById("io.selendroid.testapp:id/label_email_data").GetText()
	pLang		:= driver.FindElementById("io.selendroid.testapp:id/label_preferedProgrammingLanguage_data").GetText()
	accept		:= driver.FindElementById("io.selendroid.testapp:id/label_acceptAdds_data").GetText()
	*/
	
	MsgBox, В лог выбраны строки со страницы верификации пользователя. Продолжаем?
	driver.FindElementById("io.selendroid.testapp:id/buttonRegisterUser").Click()
	GuiControl,Text,_runMB,Run MainBody
	thread_toggler := !thread_toggler
	MsgBox, Тестовый образец кода завершён.
}
;SetTimer,MainBody,-1
Return
;	###############################################################################################
Sleep(Delay) {
	Global thread_toggler
	Start := A_TickCount
 	While A_TickCount - Start < Delay && thread_toggler
		Sleep 1
	If !(thread_toggler)
		Exit
}
WM_LBUTTONDOWN()  {
   PostMessage, WM_NCLBUTTONDOWN := 0xA1, HTCAPTION := 2
}
FrameShadow(HGui) {
	DllCall("dwmapi\DwmIsCompositionEnabled","IntP",_ISENABLED)
	if !_ISENABLED
		DllCall("SetClassLong","UInt",HGui,"Int",-26,"Int",DllCall("GetClassLong","UInt",HGui,"Int",-26)|0x20000)
	else {
		VarSetCapacity(_MARGINS,16)
		NumPut(1,&_MARGINS,0,"UInt")
		NumPut(1,&_MARGINS,4,"UInt")
		NumPut(1,&_MARGINS,8,"UInt")
		NumPut(1,&_MARGINS,12,"UInt")
		DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", HGui, "UInt", 2, "Int*", 2, "UInt", 4)
		DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", HGui, "Ptr", &_MARGINS)
	}
}
;	==================================================================================================
;		Подпрограммы
;	==================================================================================================
Return
RunServer:
	if (aDesktop) {
		if (id := WinExist("ahk_exe Appium.exe")) {
			WinActivate,ahk_id %id%
			SB_SetText("UI версия сервера уже запущена")
			Return
		}
		SB_SetText("Запускаем UI версия сервера ...")
		Run,% Format("C:\Users\{}\AppData\Local\Programs\Appium\Appium.exe",A_UserName)
		Return
	}
	if (!FileExist(moduleFolder := Format("C:\Users\{}\AppData\Roaming\npm\node_modules\appium",A_UserName))) {
		MsgBox,16,Ошибка!,NodeJS модуль 'Appium' не установлен`, или услановлен не по ожидаемому пути:`n%moduleFolder%
		Return
	}
	
	InputBox, newPort,Порт,Порт сервера. Если это новая сессия`, подойдёт дефолтный.,,,150,,,,,% defaultPort
	if (ErrorLevel) {
		MsgBox,,Отмена операции.,Попробуйте снова.
		Return
	}
	SetWorkingDir, %moduleFolder%
	Run, % "cmd /c " . Format("appium --address 127.0.0.1 --port {}", newPort)
	SetWorkingDir, %A_ScriptDir%
Return
ResetApp:
	driver.ResetApp()
Return
StopApp:
	driver.CloseApp()
Return
StartApp:
	driver.LaunchApp()
Return
MiniMe:
	WinMinimize, ahk_id%main_h%
return
ReloadMe:
	Reload
GuiClose:
	ExitApp
StartSession:
	GoSub, ConnectAppium
Return
StopSession:
	driver.Quit()
	driver := ""
	GuiControl,Text,_sessionID,Сессия завершена
	SB_SetText("Отключен от Appium")
Return
