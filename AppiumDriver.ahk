;	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;	Обертка над REST API, HTTP-сервера 'Appium'. Детали на официальном источнике:
;	 | http://appium.io/
;	
;	Код написан и опубликован за авторством KusochekDobra, 22.02.2019.
;	Версия 1.0.0
;	
;	Распространяется по лицензии MIT.
;	 | https://ru.wikipedia.org/wiki/%D0%9B%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%8F_MIT
;	
;	Копируйте, изменяйте, распространяйте, продавайте... Но, с обязательным указанием 
;		на источник оригинала.
;	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;	♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥
;						★★★★★★★★ Благодарности ★★★★★★★★
;	♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥
;	Большая благодарность сообществу "Серого форума" за, всегда живой диалог, интересные
;		идеи и традиционное постоянство.
;	
;	А так же, низкий поклон отцам начинателям, положившим начало AutoHotKey и всем, кто
;		развивает его популярность бескорыстно делясь своим мнением, проектами, временем.
;	♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥
;
;	========================================================================================
;						| ######## |  Полезные ресурсы  | ######## |
;	========================================================================================
;	ADB command list
;	 | https://developer.android.com/studio/command-line/adb#issuingcommands
;	
;	JsonWireProtocol(JSONWP)
;	 | https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
;	
;	WebDriver
;	 | https://w3c.github.io/webdriver/
;	
;	Appium API Documentation
;	 | http://appium.io/docs/en/about-appium/api/
;	
;	Appium Desired Capabilities
;	 | http://appium.io/docs/en/writing-running-appium/caps/
;	
;	XPath
;	 | https://www.w3.org/TR/1999/REC-xpath-19991116/
;	 | https://ru.wikipedia.org/wiki/XPath
;
;	UiSelector
;	 | https://developer.android.com/reference/android/support/test/uiautomator/UiSelector
;	UiScrollable
;	 | https://developer.android.com/reference/android/support/test/uiautomator/UiScrollable
;	========================================================================================
;
;	****************************************************************************************
;	desiredCapabilities	- JSON-сериализованный объект, содержащий желаемые возможности
;							сессии. Ссылка выше.
;						{"desiredCapabilities":{"app":"C:/app/full/path/app.apk", ... }}
;
;	port				- порт, который будет прослушивать Appium в ожидании команд.
;						Стандартный порт 4723, будет установлен по умолчанию, если 
;							appiumDesktop = true.
;							
;	appiumDesktop		- сообщает, будет ли использована Desktop-версия Appium. 
;						Необходимо из-за специфичности подключения, а так же некоторой
;							разницы принимаемых аргументов, некоторых методов.
;	****************************************************************************************

Class AppiumDriver Extends __SearchContext
{
	__New(desiredCapabilities := "", port := "", appiumDesktop := true) {
		if (this._ad := appiumDesktop) {
			if (!WinExist("ahk_exe Appium.exe"))
				throw {"msg":"Для Appium-Desktop - нет запущенного 'Appium.exe'. Получение сессий, или создание подключения не имеет смысла.","error":1000}
			port := !port ? 4723 : port
		} else if !(port) {
			if (inst := this.FindInstances()) {
				if (inst.Length() > 1) {
					str := ""
					For k, v in inst
						str .= v.port " "
					InputBox, newPort, Выберите порт,Оставьте в этом поле только нужный порт для подключения. Отмена завершит приложение.,,,150,,,,,%str%
					if (ErrorLevel)
						ExitApp
					port := Trim(newPort)
				} else
					port := inst[1].port
			} else
				throw {"msg":"Для Appium-CMD, нет запущенных серверов. Для создания нового подключения, запустите сервер и передайте конструктору 'desiredCapabilities'.","error":1000}
		} this._API := Format("http://127.0.0.1:{}/wd/hub/", port)
		
		if (desiredCapabilities) {
			Try
				this._sessionObj := this._NewSession(desiredCapabilities)
			Catch e {
				if (e.error == 2000)
					throw {"msg":"Сервер не запущен, или слушает другой порт. Запустите сервер, и/или выполните соединение на ожидаемом порту.","error":1001}
				throw {"msg":Format("Неизвестная ошибка:`n`n'{}'",e),"error":1}
			}
			this._sessionID := this._sessionObj.sessionID
		} else {
			Try
				this._sessionObj := this.GetSessionList()
			Catch e {
				if (e.error == 2000)
					throw {"msg":"Сервер не активен, или слушает другой порт. Активируйте сервер, и/или выполните соединение на ожидаемом порту.","error":1002}
				throw {"msg":Format("Неизвестная ошибка:`n`n'{}'",e),"error":1}
			}
			
			if (sessionNumber := len := this._sessionObj.Length()) {
				While (len > 1) {
					InputBox,sessionNumber,Выбор подключения,Всего активных сеансов = '%len%'. Укажите желаемый номер сессии для подключения. Отмена завершит приложение.,,,150,,,,,1
					if (ErrorLevel)
						ExitApp
					if sessionNumber is not integer
					{
						MsgBox,16,Ошибка!,Значение '%sessionNumber%' не является целым числом. Укажите значение от 1 до %len% включительно.
						Continue
					} if (sessionNumber < 1 || sessionNumber > len) {
						MsgBox,16,Ошибка!,Значение '%sessionNumber%' - вне диапазона. Укажите значение от 1 до %len% включительно.
						Continue
					} Break
				} this._sessionID := this._sessionObj[sessionNumber].id
			} else
				throw {"msg":Format("На порту '{}' - активных сессий не найдено. Для создания новой передайте конструктору 'desiredCapabilities', или выберите другой порт.", port),"error":1003}
		} this.action := new this.TouchActions(this._API, this._sessionID, this._ad)
	}
	
	/*	
	*	Возвращает массив объектов с параметрами запущенных серверов из командной строки,
	*		или false - если таковых не найдено
	*	[
	*		{
	*			port:		"порт прослушиваемый сервером",
	*			cmdLine:	"аргументы cmd",
	*			h:			"pid сервера"
	*		}, { ... }
	*	]
	*/
	FindInstances() {
		out := []
		For item in ComObjGet("winmgmts:")
			.ExecQuery("SELECT CommandLine FROM Win32_Process WHERE Name = 'cmd.exe'")
			if RegExMatch(item.CommandLine, "--address 127.0.0.1 --port (\d+)", m)
				out.Push({"port": m1, "cmdLine": item.CommandLine, "h": item.Handle})
		Return out.Length() ? out : false
	}
	
	/*	
	*	Создаёт сессию, возвращая объект, идентичный результату вызова GetSessionCapabilities()
	*/
	_NewSession(capabilities) {
		if ((o := this._Post(this._API "session/", capabilities)).error) {
			if (InStr(o.error.Message, "0x80072EFD"))
				throw {"msg":"Не удается установить соединение с сервером","error":2000}
			throw {"msg":"_NewSession()", "error":o.error, "request":o.req}
		} Return o
	}
	
	/*	
	*	Возвращает true, если appPackage установлено.
	*/
	IsAppInstalled(appPackage) {
		temp = {"bundleId":"{}"}
		url := Format("{}session/{}/appium/device/app_installed",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, appPackage))).error)
			throw {"msg":Format("IsAppInstalled('{}')", appPackage), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Устанавливает приложение из полного пути в appPath.
	*	Возвращает: "null"
	*/
	InstallApp(appPath) {
		temp = {"appPath":"{}"}
		url := Format("{}session/{}/appium/device/install_app",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, appPath))).error)
			throw {"msg":Format("InstallApp('{}')", appPath), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Удаляет приложение указанное в appPackage.
	*	Возвращает: "null"
	*/
	RemoveApp(appPackage) {
		temp = {"bundleId":"{}"}
		url := Format("{}session/{}/appium/device/remove_app",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, appPackage))).error)
			throw {"msg":Format("RemoveApp('{}')", appPackage), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Запускает приложение текущей сессии, указанное в capabilities в поле app.
	*	Возвращает: "null"
	*/
	LaunchApp() {
		url := Format("{}session/{}/appium/app/launch",this._API,this._sessionID)
		if ((o := this._Post( url )).error)
			throw {"msg":"LaunchApp()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Завершает приложение текущей сессии, указанное в capabilities в поле app.
	*	Возвращает: "null"
	*/
	CloseApp() {
		url := Format("{}session/{}/appium/app/close",this._API,this._sessionID)
		if ((o := this._Post( url )).error)
			throw {"msg":"CloseApp()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Сбрасывает приложение текущей сессии, указанное в capabilities в поле app.
	*		После перезапуска, состояние приложения будет таким, как если бы его
	*		запустили впервые.
	*	Возвращает: "null"
	*/
	ResetApp() {
		url := Format("{}session/{}/appium/app/reset",this._API,this._sessionID)
		if ((o := this._Post( url )).error)
			throw {"msg":"ResetApp()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Отправляет команду "вернуться". Возвращает объект, "value" которого содержит "true",
	*		если операция проведена успешно
	*/
	Back() {
		if ((o := this._Post(Format("{}session/{}/back",this._API, this._sessionID))).error)
			throw {"msg":"Back()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Блокирует девайс.
	*	seconds	- как долго находиться в состоянии блокировки( !!! ТОЛЬКО ДЛЯ IOS !!! )
	*/
	LockDevice(seconds := "") {
		temp := seconds ? Format("{""seconds"":{1}}", seconds) : ""
		url := Format("{}session/{}/appium/device/lock",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":"LockDevice()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	
	*	Разблокирует девайс.
	*/
	UnlockDevice() {
		url := Format("{}session/{}/appium/device/unlock",this._API,this._sessionID)
		if ((o := this._Post( url )).error)
			throw {"msg":"UnlockDevice()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	
	*	Возвращает true, если девайс заблокирован, иначе, false.
	*/
	IsLocked() {
		url := Format("{}session/{}/appium/device/is_locked",this._API,this._sessionID)
		if ((o := this._Post( url )).error)
			throw {"msg":"IsLocked()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Встряхивает девайс( !!! ТОЛЬКО ДЛЯ IOS !!! )
	*		| http://appium.io/docs/en/commands/device/interactions/shake/index.html
	*/
	Shake() {
		url := Format("{}session/{}/appium/device/shake",this._API,this._sessionID)
		if ((o := this._Post( url )).error)
			throw {"msg":"Shake()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Изменяет состояние питания эмулятора(ВКЛ / ВЫКЛ).
	*	state	- может быть только "ON" или "OFF"
	*/
	SetPowerAC(state) {
		temp := Format("{""state"":""{:L}""}", state)
		url := Format("{}session/{}/appium/device/power_ac",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":"SetPowerAC()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Изменяет состояние заряда батареи( !!! ТОЛЬКО ДЛЯ Andriod !!! )
	*	percent	- целочисленное значение процентов в интервале [0 - 100]
	*/
	SetPowerCapacity(percent) {
		percent := percent ? percent > 0 ? percent > 100 ? 100 : percent : 0 : 100
		temp := Format("{""percent"":{1}}", percent)
		url := Format("{}session/{}/appium/device/power_capacity",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":"SetPowerCapacity()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Возвращает объект, описывающий состояние сервера, "status" которого сообщает
	*		о возможности сервера создавать новые сеансы(doc).
	*			| http://appium.io/docs/en/commands/status/index.html
	*	Всегда возвращает один и тот же результат:
	*	{"status":0,"value":{"build":{"version":"1.10.0"}},"sessionId":null}
	*/
	GetStatus() {
		if ((o := this._Get(this._API "status")).error)
			throw {"msg":"GetStatus()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	
	*	Возвращает имя текущей activity.
	*/
	GetCurrentActivity() {
		url := Format("{}session/{}/appium/device/current_activity",this._API,this._sessionID)
		if ((o := this._Get( url )).error)
			throw {"msg":"GetCurrentActivity()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	
	*	Возвращает LANDSCAPE или PORTRAIT.
	*/
	GetOrientation() {
		url := Format("{}session/{}/orientation",this._API,this._sessionID)
		if ((o := this._Get( url )).error)
			throw {"msg":"GetOrientation()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Принимает регистро-независимую строку = LANDSCAPE или PORTRAIT.
	*	Возвращает: 'Rotation (PORTRAIT) successful.'
	*/
	SetOrientation(orientation := "PORTRAIT") {
		temp = {"orientation":"{}"}
		url := Format("{}session/{}/orientation",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, orientation))).error)
			throw {"msg":"SetOrientation()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	
	*	Возвращает имя текущего package.
	*/
	GetCurrentPackage() {
		url := Format("{}session/{}/appium/device/current_package",this._API,this._sessionID)
		if ((o := this._Get( url )).error)
			throw {"msg":"GetCurrentPackage()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Получить текущий контекст, в котором работает Appium.
	*	Это может быть как "NATIVE_APP" для собственного контекста, так
	*		и для контекста веб-просмотра, который будет:
	*		 * iOS - WEBVIEW_<id>
	*		 * Android - WEBVIEW_<package name>
	*	Для получения информации о контекстах см. Документацию по
	*		гибридной автоматизации Appium.
	*		http://appium.io/docs/en/writing-running-appium/web/hybrid/index.html
	*/
	GetContext() {
		url := Format("{}session/{}/context",this._API,this._sessionID)
		if ((o := this._Get( url )).error)
			throw {"msg":"GetContext()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Получить все контексты, доступные для автоматизации в Appium.
	*	Будет включать, по крайней мере, родной контекст. Также может
	*		быть ноль или более контекстов веб-просмотра.
	*/
	GetContexts() {
		url := Format("{}session/{}/contexts",this._API,this._sessionID)
		if ((o := this._Get( url )).error)
			throw {"msg":"GetContexts()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Устанавливает текущий контекст на переданный. Если при этом происходит
	*		перемещение в контекст веб-представления, это будет включать попытку
	*		подключения к этому веб-представлению.
	*/
	SetContext(name := "NATIVE_APP") {
		temp = {"name":{1}}
		url := Format("{}session/{}/context",this._API,this._sessionID)
		if ((o := this._Post(url, temp := Format(temp, name))).error)
			throw {"msg":"SetContext()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Возвращает массив сессий с их capabilities. 
	*	{"value":[{"capabilities": {...}, "id": "899316a1-047f-4973-bc5f-a4b033d457b2"}, ... ]}
	*/
	GetSessionList() {
		if ((o := this._Get(this._API "sessions")).error ) {
			if (InStr(o.error.Message, "0x80072EFD"))
				throw {"msg":"GetSessionList() - не удается установить соединение с сервером","error":2000}
			throw {"msg":"GetSessionList()", "error":o.error, "request":o.req}
		} Return o.value
	}
	
	/*	
	*	Возвращает base64 строку, представляющую скрин viewport.
	*/
	TakeScreenshot() {
		url := Format("{}session/{}/screenshot",this._API,this._sessionID)
		if ((o := this._Get( url )).error)
			throw {"msg":"TakeScreenshot()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Возвращает объект, "value" которого содержит возможности(capabilities) текущей сессии:
	{
		"status": 0,
		"value": {
			"platform":"LINUX",
			"webStorageEnabled":false,
			"takesScreenshot":true,
			"javascriptEnabled":true,
			"databaseEnabled":false,
			"networkConnectionEnabled":true,
			"locationContextEnabled":false,
			"warnings": {},
			"desired": {
				"app":"C:/full/path/to/com.application.apk",
				"appActivity":".main.MainActivity",
				"appPackage":"com.application",
				"automationName":"Appium",
				"deviceName":"AndroidTestDevice",
				"platformName":"Android",
				"platformVersion":"5.1.1",
				"newCommandTimeout":0,
				"connectHardwareKeyboard":true
			},
			"app":"C:/full/path/to/com.application.apk",
			"appActivity":".main.MainActivity",
			"appPackage":"com.application",
			"automationName":"Appium",
			"deviceName":"emulator-5554",
			"platformName":"Android",
			"platformVersion":"5.1.1",
			"newCommandTimeout":0,
			"connectHardwareKeyboard":true,
			"deviceUDID":"emulator-5554",
			"deviceScreenSize":"480x800",
			"deviceModel":"Android SDK built for x86",
			"deviceManufacturer":"unknown"
		},
		"sessionId":"899316a1-047f-4973-bc5f-a4b033d457b2"
	}
	*/
	GetSessionCapabilities() {
		if ((o := this._Get(this._API "session/" this._sessionID)).error)
			throw {"msg":"GetSessionCapabilities()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Возвращает xml контекста текущей сессии
	*		в виде строки
	*	{"sessionID": "899316a1-047f-4973-bc5f-a4b033d457b2", "status": 0,
	*	"value": "<?xml version="1.0" encoding="UTF-8"?><hierarchy rotation="0"><android.widget.FrameLayout ..."}
	*/
	GetPageSourse() {
		if ((o := this._Get(Format("{}session/{}/source",this._API,this._sessionID))).error)
			throw {"msg":"GetPageSourse()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Возвращает объект: 
	*	{
	*		"altitude": 5,				- высота над уровнем моря
	*		"latitude": 37.422000,		- широта
	*		"longitude": -122.084000	- долгота
	*	}
	*	Работает с типом автоматизации UiAutomator и выше
	*/
	GetGeolocation() {
		if ((o := this._Get(Format("{}session/{}/location",this._API,this._sessionID))).error)
			throw {"msg":"GetGeolocation()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Устанавливает новые значения для геолокации.
	*	Работает с типом автоматизации UiAutomator и выше
	*/
	SetGeolocation(latitude := 37.422, longitude := -122.084, altitude := 5) {
		temp = {"location":{"altitude":{},"latitude":{},"longitude":{3}}}
		;temp = ["location"]
		url := Format("{}session/{}/location",this._API,this._sessionID)
		if ((o := this._Post(url, temp := Format(temp, altitude, latitude, longitude))).error)
			throw {"msg":Format("SetGeolocation('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Получает текущие настройки устройства. 
	*		http://appium.io/docs/en/advanced-concepts/settings/index.html
	*	{"imageMatchThreshold":0.4,"fixImageFindScreenshotDims":true,"fixImageTemplateSize":false, ... }
	*	От типа автоматизации девайса зависит количество настроек.
	*/
	GetDeviceSettings() {
		if ((o := this._Get(Format("{}session/{}/appium/settings",this._API,this._sessionID))).error)
			throw {"msg":"GetDeviceSettings()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/* Обновляет настройки устройства. 
	*		http://appium.io/docs/en/advanced-concepts/settings/index.html
	*	В settings - ожидается объект = {"ignoreUnimportantViews":true, ... }
	*	
	*	Булевы true и false, а так же строковый литерал ссылочного(?) типа на
	*		значение null, оборачивайте в кавычки. Перед отправкой, они будут
	*		преобразованы из строкового, в ожидаемый тип.
	*	От типа автоматизации девайса зависит количество настроек.
	*/
	SetDeviceSettings(settings) {
		temp := JSON.Stringify( {"settings": settings} )
		temp := RegExReplace(temp, """(true|false|null)""", "$1")
		url := Format("{}session/{}/appium/settings",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":Format("SetDeviceSettings('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	
	*	Возвращает true, если виртуальная клавиатура показана, иначе, false.
	*/
	IsKeyboardShown() {
		if ((o := this._Get(Format("{}session/{}/appium/device/is_keyboard_shown",this._API,this._sessionID))).error)
			throw {"msg":"IsKeyboardShown()", "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Скрыть виртуальную клавиатуру.
	*	strategy	- Необязательно. Только для UIAutomation. Может принимать значения:
	*					+ "press"
	*					+ "pressKey"
	*					+ "swipeDown"
	*					+ "tapOut"
	*					+ "tapOutside"
	*					+ "default"
	*/
	HideKeyboard(strategy := "") {
		temp := strategy ? Format("{""strategy"":{1}}", strategy) : ""
		url := Format("{}session/{}/appium/device/hide_keyboard",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":Format("HideKeyboard('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Отправить текущее приложение для этого сеанса в фоновый режим. 
	*		secs	- целое число секунд, в течении которых приложение
	*				будет выполняться в фоне. Значение равное -1
	*				полностью деактивирует приложение.
	*/
	BackgroundApp(secs) {
		temp = {"secs":{1}}
		url := Format("{}session/{}/appium/settings",this._API,this._sessionID)
		if ((o := this._Post(url, temp := Format(temp, secs))).error)
			throw {"msg":Format("BackgroundApp('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Выполнить JavaScript сценарий в контексте текущего выбранного фрейма(Web context only).
	*	http://appium.io/docs/en/commands/web/execute/index.html
	*	
	*	Доступен так же некоторый набор команд для native-app.
	*	http://appium.io/docs/en/commands/mobile-command/index.html
	*	
	*	Возвращает результат выполненного кода.
	*	
	*	cmd:	- строка, представляющая скрипт / mobile:commandName
	*	args:	- JSON-сериализованные аргументы, в виде объекта/массива({}/[])
	*	
	*	Пример:	driver.Execute("window.location.href")
	*	
	*	!!! Не тестировалось. В документации указано как "Не добавлено" !!!
	*/
	Execute(cmd, args := "") {
		temp = {"script":"{}","args":[{2}]}
		url := Format("{}session/{}/execute",this._API,this._sessionID)
		if ((o := this._Post(url, temp := Format(temp, cmd, args))).error)
			throw {"msg":Format("Execute('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Выполнить JavaScript сценарий в контексте текущего выбранного фрейма(Web context only)
	*	http://appium.io/docs/en/commands/web/execute-async/index.html
	*	
	*	Предполагается, что исполняемый скрипт является асинхронным и должен сигнализировать о
	*		своём выполнении, вызывая callback, который всегда предоставляется последним
	*		аргументом функции. Значение обратного вызова будет возвращено клиенту.
	*	
	*	Пример:	driver.ExecuteAsync("window.setTimeout(arguments[arguments.length - 1], 500);")
	*	
	*	!!! Не тестировалось. В документации указано как "Не добавлено" !!!
	*/
	ExecuteAsync(cmd, args := "") {
		temp = {"script":"{}","args":[{2}]}
		url := Format("{}session/{}/execute_async",this._API,this._sessionID)
		if ((o := this._Post(url, temp := Format(temp, cmd, args))).error)
			throw {"msg":Format("ExecuteAsync('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Отправляет файл девайсу, располагая в его файловой системе по указанному пути.
	*
	*	file 			- имя отправляемого файла, или путь до него
	*	pathToInstall	- полный путь в файловой системе девайса, в который будет сохранён
	*						одноимённый файл, если новое имя фала с расширением, не указано.
	*	
	*	Пример:	driver.PushFile("pictureName.png", "storage/sdcard/Download/")
	*			driver.PushFile("..\MyLib\pictureName.png"
	*											, "storage/sdcard/Download/newPictureName.png")
	*			driver.PushFile("C:\Users\{your_user_name}\Pictures\pictureName.png"
	*											, "storage/sdcard/Download/")
	*	
	*	Существующий файл с таким же именем и расширением будет перезаписан.
	*/
	PushFile(file, pathToInstall) {
		FileGetSize, binLen, %file%
		FileRead, bin, *c %file%
		if (!InStr(pathToInstall, ".")) {
			file := RegExReplace(file, ".*[\\|\/]+?(.*\..*)", "$1")
			pathToInstall := Format("{}/{}", RTrim(pathToInstall, "/\"), file)
		} temp := JSON.Stringify({"path": pathToInstall, "data": this.Base64Encode(bin,binLen)})
		url := Format("{}session/{}/appium/device/push_file", this._API, this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":Format("PushFile('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Получает файл из файловой системы девайса, расположенного по указанному пути,
	*		сохраняя в файловой системе компьютера.
	*	
	*	pathOnDevice	- полный путь до файла на устройстве
	*	pathOnComputer	- имя получаемого файла, или путь до него(необязательно)
	*	
	*	Пример:	driver.PullFile("storage/sdcard/Download/pictureName.png")
	*			driver.PullFile("storage/sdcard/Download/pictureName.png", "newPictureName.png")
	*			driver.PullFile("storage/sdcard/Download/pictureName.png"
	*									, "C:\Users\{your_user_name}\Pictures\pictureName.png")
	*	
	*	Создаёт одноимённый файл в месте расположения скрипта, если pathOnComputer не указано.
	*	Существующий файл с таким же именем и расширением будет перезаписан.
	*/
	PullFile(pathOnDevice, pathOnComputer := "") {
		temp := JSON.Stringify( {"path": pathOnDevice} )
		url := Format("{}session/{}/appium/device/pull_file",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":Format("PullFile('{}')", temp), "error":o.error, "request":o.req}
		bCount := this.Base64Decode( o.value, bin )
		pathOnComputer := pathOnComputer ? pathOnComputer : RegExReplace(pathOnDevice, ".*[\\|\/]+?(.*\..*)", "$1")
		oFile := FileOpen(pathOnComputer, "w"), oFile.RawWrite(bin, bCount), oFile.Close()
	}
	
	
	/*	Получает папку из файловой системы девайса, расположенную по указанному пути,
	*		сохраняя в файловой системе компьютера в виде ZIP архива.
	*	
	*	pathOnDevice	- полный путь до папки на устройстве
	*	pathOnComputer	- имя архива, или путь до него(необязательно)
	*	
	*	Пример:	driver.PullFile("storage/sdcard/Download/")
	*			driver.PullFile("storage/sdcard/Download/", "newDownload.zip")
	*			driver.PullFile("storage/sdcard/Download/"
	*									, "C:\Users\{your_user_name}\Documents\Download.zip")
	*	
	*	Создаёт одноимённый с конечной папкой ZIP-файл в месте расположения скрипта, если
	*		pathOnComputer не указано.
	*	Существующий файл с таким же именем и расширением будет перезаписан.
	*/
	PullFolder(pathOnDevice, pathOnComputer := "") {
		temp := JSON.Stringify( {"path": pathOnDevice} )
		url := Format("{}session/{}/appium/device/pull_folder",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":Format("PullFolder('{}')", temp), "error":o.error, "request":o.req}
		bCount := this.Base64Decode( o.value, bin )
		pathOnComputer := pathOnComputer ? pathOnComputer : RegExReplace(pathOnDevice, ".*\/(.*)\/$", "$1") . ".zip"
		oFile := FileOpen(pathOnComputer, "w"), oFile.RawWrite(bin, bCount), oFile.Close()
	}
	
	Base64Encode(bin, binLen) {
		DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &bin, "UInt", binLen, "UInt", 0x01, "Ptr", 0, "UIntP", b64Len)
		VarSetCapacity(b64, b64Len << !!A_IsUnicode, 0)
		DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &bin, "UInt", binLen, "UInt", 0x01, "Ptr", &b64, "UIntP", b64Len)
		VarSetCapacity(b64, -1)
		Return StrReplace(b64, "`r`n")
	}
	
	Base64Decode(b64, ByRef bin) {
		len := StrLen(b64), bCount := 0
		DllCall("Crypt32.dll\CryptStringToBinary","Str",b64,"UInt",len,"UInt",0x1,"UInt",0,"UIntP",bCount,"Int",0,"Int",0)
		VarSetCapacity(bin, bCount, 0)
		DllCall("Crypt32.dll\CryptStringToBinary","Str",b64,"UInt",len,"UInt",0x1,"Ptr",&bin,"UIntP",bCount,"Int",0,"Int",0)
		Return bCount
	}
	
	/*	Отправить SMS на указанный номер телефона.
	*	phoneNumber	- номер телефона получателя
	*	message		- текст сообщения
	*	
	*	В документации дано следующее пояснение:
	*		| Simulate an SMS message (Emulator only)
	*		| http://appium.io/docs/en/commands/device/network/send-sms/index.html
	*	Не теститровалось.
	*/
	SendSMS(phoneNumber, message) {
		temp := JSON.Stringify( {"phoneNumber": phoneNumber, "message": message} )
		url := Format("{}session/{}/appium/device/send_sms",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":Format("SendSMS('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	Сделать GSM-звонок
	*	phoneNumber	- номер телефона получателя
	*	action		- одно из следующих значений:
	*					+ "call"	= набрать номер
	*					+ "accept"	= принять вызов
	*					+ "cancel"	= отменить звонок
	*					+ "hold"	= удержать
	*	
	*	В документации дано следующее пояснение:
	*		| Make GSM call (Emulator only)
	*		| http://appium.io/docs/en/commands/device/network/gsm-call/index.html
	*	Не тестировалось.
	*/
	MakeGsmCall(phoneNumber, action) {
		temp := JSON.Stringify( {"phoneNumber": phoneNumber, "action": action} )
		url := Format("{}session/{}/appium/device/gsm_call",this._API,this._sessionID)
		if ((o := this._Post(url, temp)).error)
			throw {"msg":Format("MakeGsmCall('{}')", temp), "error":o.error, "request":o.req}
		Return o.value
	}
	
	/*	=============================================================================
	*		Завершение сессии. Отключение Appium от девайса.
	*/
	Quit() {
		oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Try {
			oHTTP.Open("DELETE", this._API "session/" this._sessionID, false)
			oHTTP.Send()
			oHTTP.WaitForResponse()
		} Catch e {
			Return {"error": e}
		} Return oHTTP.Status == 200 ? JSON.Parse(oHTTP.ResponseText) : {"error": oHTTP.Status}
	}
	;	=============================================================================
	
	Class TouchActions
	{
		__New(API, sessionID, appiumDesktop) {
			this.actions := [], this._API := API, this._sessionID := sessionID
			this._ad := appiumDesktop
		}
		
		/*	Методы следующие до LongPress() включительно, реализованы настолько
		*		через жопу, что не работают, принимая аргументы не в том
		*		количестве, что регламентирует официальная документация.
		*		В итоге получается, что передавая указанные аргументы - не
		*		передаёшь все, а если передаёшь все, то нарушаешь шаблон
		*		ожидаемых аргументов.
		*		
		*	В будущих редакциях будут добавлены, когда существующий конфликт
		*		окажется исчерпан. Или удалены вовсе. Следующая за ними
		*		метода, позволяющая собирать несколько действий в один запрос,
		*		выполняет те же функции и в этой связи, необходимость их наличия
		*		весьма сомнительна.
		
		MouseMove(xoffset, yoffset, elementID := "") {
			if (elementID)
				temp = {"element":{3},"xoffset":{1},"yoffset":{2}}
			else
				temp = {"xoffset":{1},"yoffset":{2}}
			url := Format("{}session/{}/moveto",this._API,this._sessionID)
			if ((o := AppiumDriver._Post(url, Format(temp, xoffset, yoffset, elementID))).error)
				throw {"msg":"MouseMove()", "error":o.error, "request":o.req}
			Return o.value
			
		}
		Click(buttonNumber := 0) {
			temp = {"button":"{}"}
			url := Format("{}session/{}/click",this._API,this._sessionID)
			if ((o := AppiumDriver._Post(url, Format(temp,buttonNumber))).error)
				throw {"msg":"Click()", "error":o.error, "request":o.req}
			Return o.value
		}
		
		TouchDown(x, y) {
			temp = {"x":{},"y":{2}}
			url := Format("{}session/{}/touch/down",this._API,this._sessionID)
			if ((o := AppiumDriver._Post(url, Format(temp, x, y))).error)
				throw {"msg":"TouchDown()", "error":o.error, "request":o.req}
			Return o.value
		}
		
		TouchUp(x, y) {
			temp = {"x":{},"y":{2}}
			url := Format("{}session/{}/touch/up",this._API,this._sessionID)
			if ((o := AppiumDriver._Post(url, Format(temp, x, y))).error)
				throw {"msg":"TouchUp()", "error":o.error, "request":o.req}
			Return o.value
		}
		
		Scroll(x, y) {
			temp = {"x":{},"y":{2}}
			url := Format("{}session/{}/touch/scroll",this._API,this._sessionID)
			if ((o := AppiumDriver._Post(url, Format(temp, x, y))).error)
				throw {"msg":"Scroll()", "error":o.error, "request":o.req}
			Return o.value
		}
		
		LongPress(element) {
			temp := JSON.Stringify({"elements": element.element})
			url := Format("{}session/{}/touch/longclick",this._API,this._sessionID)
			if ((o := AppiumDriver._Post(url, temp)).error)
				throw {"msg":"LongPress()", "error":o.error, "request":o.req}
			Return o.value
		}
		*/
		
		/*	Имитирует движение пальцем по viewport. Используйте, если не критично
		*		начальное положение пальца.
		*	Параметры, обозначают количество пикселей, которые должен пройти
		*		"палец" до отпускания. Сохраняет инерцию.
		*	xspeed:	положительное - пальцем вправо(viewport влево)
		*				отрицательное - влево
		*	yspeed:	положительное - пальцем вниз(viewport вверх)
		*				отрицательное - вверх
		*	
		*	Требует способ автоматизации - UiAutomator2
		*	
		*	Может вызывать исключение "JSONException: No value for xSpeed", если сервер запущен
		*		из CMD.exe и "JSONException: No value for xspeed", если из десктоп-версии, когда
		*		имена полей не соответствуют ожидаемому регистру символов.
		*/
		Flick(xspeed := 0, yspeed := -100) {
			temp := JSON.Stringify( this._ad
								? {"xspeed": xspeed, "yspeed": yspeed}
								: {"xSpeed": xspeed, "ySpeed": yspeed} )
			url := Format("{}session/{}/touch/flick", this._API,this._sessionID)
			if ((o := AppiumDriver._Post(url, temp )).error)
				throw {"msg":Format("action.Flick('{}')", temp), "error":o.error, "request":o.req}
			Return o.value
		}
		
		;	###########################################################################
		
		/*	Ниже приведены методы, позволяющие собирать несколько действий
		*		в один запрос. Например, FlickDown() и FlickUp() - это
		*		наборы, описывающие движение пальцем по viewport,
		*		прокручивающие последний на 10 пикселей вниз, или вверх
		*		соответственно, а LongTap() - держит палец в координатах
		*		с короткой паузой и отпускает.
		*	В отличии от action.Flick() и element.Flick(), эта имитация
		*		более схожа с реальным движением, так как сохраняет
		*		инерцию прокручивания после "отпускания", в результате
		*		чего, точность прокрутки не обеспечивается.
		*	
		*	Tap(x, y)		- одиночное касание в x и y координатах.
		*	Wait(ms)		- ожидание в миллисекундах до следующего действия.
		*	Press(x, y)		- опускает палец в x и y координатах.
		*	MoveTo(x, y)	- перемещает палец в x и y координаты.
		*	Release()		- отпускает палец.
		*	PerformAll()	- формирует запрос из описанного набора.
		*/
		Tap(x, y) {
			this.actions.Push( {"action":"tap","options":{"x":x,"y":y}} )
		} Wait(ms) {
			this.actions.Push( {"action":"wait","options":{"ms":ms}} )
		} Press(x, y) {
			this.actions.Push( {"action":"press","options":{"x":x,"y":y}} )
		} MoveTo(x, y) {
			this.actions.Push( {"action":"moveTo","options":{"x":x,"y":y}} )
		} Release() {
			this.actions.Push( {"action":"release","options":{}} )
		} FlickDown(from_x := 1, from_y := 200, to_x := 1, to_y := 190, ms := 0) {
			this.Press(from_x, from_y), (ms && this.Wait(ms)), this.MoveTo(to_x, to_y), this.Release()
			this.PerformAll()
		} FlickUp(from_x := 1, from_y := 200, to_x := 1, to_y := 210, ms := 0) {
			this.Press(from_x, from_y), (ms && this.Wait(ms)), this.MoveTo(to_x, to_y), this.Release()
			this.PerformAll()
		} LongTap(x, y, ms := 1000) {
			this.Press(x, y), this.Wait(ms), this.Release()
			this.PerformAll()
		} PerformAll() {
			url	 := Format("{}session/{}/touch/perform",this._API,this._sessionID)
			temp := JSON.Stringify(this.actions), this.actions := []
			if ((o := AppiumDriver._Post(url, temp)).error)
				throw {"msg":Format("PerformAll('{}')", temp), "error":o.error, "request":o.req}
			Return o
		}
	}
}

Class __SearchContext
{
	/*	https://www.w3.org/TR/1999/REC-xpath-19991116/
	*	Возвращает первый найденный элемент по локатору xPath
	*	Возвращаемый результат:
	*	{"status":0,"value":{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementByXPath(xPath) {
		temp = {"using":"xpath","value":"{}"}
		url := Format("{}session/{}/element",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, xPath))).error && o.error != 500)
			throw {"msg":Format("FindElementByXPath('{}')", xPath), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Возвращает массив элементов, найденных по локатору xPath
	*	Возвращаемый результат:
	*	{"status":0,"value":[{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}]
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementsByXPath(xPath) {
		temp = {"using":"xpath","value":"{}"}
		url := Format("{}session/{}/elements",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, xPath))).error && o.error != 500)
			throw {"msg":Format("FindElementsByXPath('{}')", xPath), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Возвращает элемент, найденный по ID
	*	Возвращаемый результат:
	*	{"status":0,"value":{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementById(id) {
		temp = {"using":"id","value":"{}"}
		url := Format("{}session/{}/element",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, id))).error && o.error != 500)
			throw {"msg":Format("FindElementsById('{}')", id), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Возвращает массив элементов, найденных по по ID
	*	Возвращаемый результат:
	*	{"status":0,"value":[{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}]
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementsById(id) {
		temp = {"using":"id","value":"{}"}
		url := Format("{}session/{}/elements",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, id))).error && o.error != 500)
			throw {"msg":Format("FindElementsById('{}')", id), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Возвращает элемент, найденный по className
	*	Возвращаемый результат:
	*	{"status":0,"value":{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementByClassName(className) {
		temp = {"using":"class name","value":"{}"}
		url := Format("{}session/{}/element",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, className))).error && o.error != 500)
			throw {"msg":Format("FindElementByClassName('{}')", className), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Возвращает массив элементов, найденных по className
	*	Возвращаемый результат:
	*	{"status":0,"value":[{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}, ...]
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementsByClassName(className) {
		temp = {"using":"class name","value":"{}"}
		url := Format("{}session/{}/elements",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, className))).error && o.error != 500)
			throw {"msg":Format("FindElementsByClassName('{}')", className), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Возвращает элемент, найденный по accessibilityId. Для XCUITest это содержимое
	*		атрибута 'accessibility-id'. Для Android 'content-desc'.
	*	Возвращаемый результат:
	*	{"status":0,"value":{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementByAccessibilityId(accessibilityId) {
		temp = {"using":"accessibility id","value":"{}"}
		url := Format("{}session/{}/element",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, accessibilityId))).error && o.error != 500)
			throw {"msg":Format("FindElementByAccessibilityId('{}')", accessibilityId), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Возвращает массив элементов, найденных по accessibilityId. Для XCUITest это содержимое
	*		атрибута 'accessibility-id'. Для Android 'content-desc'.
	*	Возвращаемый результат:
	*	{"status":0,"value":[{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}, ...]
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/	
	FindElementsByAccessibilityId(accessibilityId) {
		temp = {"using":"accessibility id","value":"{}"}
		url := Format("{}session/{}/elements",this._API,this._sessionID)
		if ((o := this._Post(url, Format(temp, accessibilityId))).error && o.error != 500)
			throw {"msg":Format("FindElementsByAccessibilityId('{}')", accessibilityId), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Используется "UiAutomator Api", драйвера для Android - UiAutomator2.
	*		http://appium.io/docs/en/drivers/android-uiautomator2/
	*	Возвращает элемент, найденный по UiSelector, позволяя так же осуществлять прокручивания
	*		элементов средствами 'UiScrollable' в одном запросе.
	*	В качестве селекторов поддерживаются:
	*		UiSelector - 
	*			https://developer.android.com/reference/android/support/test/uiautomator/UiSelector
	*		UiScrollable - 
	*			https://developer.android.com/reference/android/support/test/uiautomator/UiScrollable
	*	Возвращаемый результат:
	*	{"status":0,"value":{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*
	*	Из офф. документации:
	*		| Note: This framework requires Android 4.3 (API level 18) or higher.
	*		| Заметка: Этот фреймворк поддерживает Android версии 4.3 (уровня API 18) и выше.
	*	
	*	Чтобы иметь возможность использовать средства "UiAutomator Api", необходимо её включить
	*		в "capabilities" сессии, установив в поле "automationName", значение "UiAutomator2"
	*		(по умолчанию Appium). Так же, обязательно,"platformName" должна быть установлена как
	*		"Android", указана "platformVersion", "deviceName" и "app".
	*	
	*	Примеры:
	*		- Найти элемент, видимый текст которого = 'Text on element'
	*			driver.FindElementByUiAutomator("new UiSelector().text(""Text on element"")")
	*		- Найти первый прокручиваемый элемент, затем, найти его дочерний элемент с текстовым
	*			полем, содержащим текст 'Tabs'. Элемент 'Tabs' должен быть в поле зрения.
	*			driver.FindElementByUiAutomator("new UiScrollable(new UiSelector().scrollable(true).instance(0)).getChildByText(new UiSelector().className(""android.widget.TextView""), ""Tabs"")")
	*		- Найти элемент по 'resourceId' и прокрутить вниз/вперёд(зависит от ориентации девайса).
	*			driver.FindElementByUiAutomator("new UiScrollable(new UiSelector().resourceId(""com.android.resource:id/id"")).scrollForward(10)")
	*		- Найти потомка 'resourceId' по 'className'.
	*			driver.FindElementByUiAutomator("new UiSelector().resourceId(""com.android.resource:id/id"").childSelector(new UiSelector().className(""android.widget.TextView""))")
	*	Обращение к унаследованным методам в UiSelector - не поддерживается и будет
	*		возвращать пустое значение.
	*/	
	FindElementByUiAutomator(UiSelector) {
		temp := {"using":"-android uiautomator","value":UiSelector}
		url := Format("{}session/{}/element",this._API,this._sessionID)
		if ((o := this._Post(url, JSON.Stringify(temp))).error && o.error != 500)
			throw {"msg":Format("FindElementByUiAutomator('{}')", UiSelector), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	
	/*	Только для Android! Возвращает массив элементов, найденных по UiSelector.
	*	С помощью 'UiAutomator' невозможно запросить коллекцию элементов, формирует которую
	*		не поддерживаемый 'UiCollection'. Будет возвращён массив с одним элементом, если
	*		поиск был удачен.
	*	Возвращаемый результат:
	*	{"status":0,"value":[{"element-6066-11e4-a52e-4f735466cecf":"17","ELEMENT":"17"}, ...]
	*	,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
	*/
	FindElementsByUiAutomator(UiSelector) {
		temp := {"using":"-android uiautomator","value":UiSelector}
		url := Format("{}session/{}/elements",this._API,this._sessionID)
		if ((o := this._Post(url, JSON.Stringify(temp))).error && o.error != 500)
			throw {"msg":Format("FindElementsByUiAutomator('{}')", UiSelector), "error":o.error, "request":o.req}
		Return new this._Element( o.value, this._API, this._sessionID )
	}
		
	/*	Получить активный элемент. Пока не реализован.
	*	http://appium.io/docs/en/commands/element/other/active/index.html
	*
	GetActiveElement() {
		url := Format("{}session/{}/element/active", this._API,this._sessionID)
		if ((o := this._Post( url )).error)
			throw Format("GetActiveElement() завершился ошибкой '{}'`n{}", this.element, o.error, o.req)
		Return new this._Element( o.value, this._API, this._sessionID )
	}
	*/
	
	_Get(url) {
		oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Try {
			oHTTP.Open("GET", url, false)
			oHTTP.Send()
			oHTTP.WaitForResponse()
		} Catch e {
			if (InStr(e.Message, "0x80072F78")		; Сервер вернул недопустимый или нераспознанный ответ
				|| InStr(e.Message, "0x80072EE2")	; Время ожидания операции истекло
				|| InStr(e.Message, "0x80072EFE"))	; Соединение с сервером было неожиданно прервано
				Return {"error": "0x80072F78|0x80072EE2|0x80072EFE"}
			Return {"error": e}
		} Return oHTTP.Status == 200 ? JSON.Parse(oHTTP.ResponseText) : {"error": oHTTP.Status,"req": oHTTP.ResponseText}
	}
	
	_Post(url, sJson := "") {
		oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Try {
			oHTTP.Open("POST", url, false)
			oHTTP.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
			oHTTP.Send(sJson)
			oHTTP.WaitForResponse()
		} Catch e {
			if (InStr(e.Message, "0x80072F78")		; Сервер вернул недопустимый или нераспознанный ответ
				|| InStr(e.Message, "0x80072EE2")	; Время ожидания операции истекло
				|| InStr(e.Message, "0x80072EFE"))	; Соединение с сервером было неожиданно прервано
				Return {"error": "0x80072F78|0x80072EE2|0x80072EFE"}
			Return {"error": e}
		} Return oHTTP.Status == 200 ? JSON.Parse(oHTTP.ResponseText) : {"error": oHTTP.Status,"req": oHTTP.ResponseText}
	}
	
	Class _Element
	{
		__New(o, API, sessionID) {
			if (!o.Length()) {
				this.element := o.ELEMENT, this._API := API, this._sessionID := sessionID
				Return o.element ? this : ""
			} else {
				elements := []
				For k, v in o
					elements.Push(new this(v, API, sessionID))
				Return elements
			}
		}
		
		/*	Имитирует движение пальцем по viewport, начинаясь на выбранном элементе.
		*	xoffset и yoffset - количество пикселей, которые нужно пройти от позиции
		*		элемента(его верхний левый угол), до остановки. Ниболее точен при
		*		значениях speed, около 10.
		*	xoffset:	положительное - пальцем вправо(viewport влево)
		*				отрицательное - влево
		*	yoffset:	положительное - пальцем вниз(viewport вверх)
		*				отрицательное - вверх
		*	speed:		скорость в пикселях в секунду
		*/
		Flick(xoffset := 0, yoffset := -100, speed := 100) {
			temp = {"xoffset":{},"yoffset":{},"element":"{}","speed":{4}}
			url := Format("{}session/{}/touch/flick", this._API,this._sessionID,this.element)
			sJson := Format(temp, xoffset, yoffset, this.element, speed)
			if ((o := __SearchContext._Post(url, sJson)).error)
				throw {"msg":"element.Flick()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Сообщить элементу событие 'клик'.
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		Click() {
			url := Format("{}session/{}/element/{}/click", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Post( url )).error)
				throw {"msg":"element.Click()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Установить строку в editable поле элемента.
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*	Найдено в единственном месте:
		*	https://github.com/appium/appium-base-driver/blob/master/lib/protocol/routes.js#L548
		*/
		SetValue(string) {
			temp := {"value":[string]}
			url := Format("{}session/{}/appium/element/{}/value", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Post(url, JSON.Stringify(temp))).error)
				throw {"msg":Format("element.SetValue('{}')", string), "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Отправить строку которая будет набрана в editable поле элемента.
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		SendKeys(string) {
			temp := {"value":[string]}
			url := Format("{}session/{}/element/{}/value", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Post(url, JSON.Stringify(temp))).error)
				throw {"msg":Format("element.SendKeys('{}')", string), "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Заменить строку в editable поле элемента.
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		ReplaceValue(string) {
			temp := {"value":[string]}
			url := Format("{}session/{}/appium/element/{}/replace_value", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Post(url, JSON.Stringify(temp))).error)
				throw {"msg":Format("element.ReplaceValue('{}')", string), "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Очистить элемент. Как правило - editable.
		*	{"status":0,"value":null,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		Clear() {
			url := Format("{}session/{}/element/{}/clear", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Post( url )).error)
				throw {"msg":"element.Clear()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Сообщить форме Submit()
		*	{"status":0,"value":null,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*	Только для Mac(?) и Windows(10+)
		*		| http://appium.io/docs/en/commands/element/other/submit/index.html
		*/
		Submit() {
			url := Format("{}session/{}/element/{}/submit", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Post( url )).error)
				throw {"msg":"element.Submit()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Получить видимый текст элемента.
		*	{"status":0,"value":"Text from element","sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		GetText() {
			url := Format("{}session/{}/element/{}/text", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.GetText()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Получить имя тега.
		*	{"status":0,"value":"android.widget.EditText","sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		GetTagName() {
			url := Format("{}session/{}/element/{}/name", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.GetTagName()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Позиция элемента после прокручивания View(doc).
		*	{"status":0,"value":{"x":108,"y":53},"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		GetLocationInView() {
			url := Format("{}session/{}/element/{}/location_in_view", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.GetLocationInView()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Позиция элемента относительно верхнего левого угла View.
		*	{"status":0,"value":{"x":108,"y":53},"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		GetLocation() {
			url := Format("{}session/{}/element/{}/location", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.GetLocation()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Длина и ширина элемента
		*	{"status":0,"value":{"width":227,"height":54},"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		GetSize() {
			url := Format("{}session/{}/element/{}/size", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.GetSize()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	GetLocation() и GetSize() - в одном флаконе
		*	{"status":0,"value":{"x":108,"y":53,"width":227,"height":54},"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		GetRect() {
			url := Format("{}session/{}/element/{}/rect", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.GetRect()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	
		*	Вероятно, только для WEB контекста.
		*/
		GetCSSProperty(prop) {
			url := Format("{}session/{}/element/{}/css/{}", this._API,this._sessionID,this.element,prop)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":Format("element.GetCSSProperty('{}')", prop), "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Получить значение атрибута attr. Доступно только при автоматизации через UiAutomator2
		*	{"status":0,"value":"false","sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		GetAttribute(attr := "class") {
			url := Format("{}session/{}/element/{}/attribute/{}", this._API,this._sessionID,this.element,attr)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":Format("element.GetAttribute('{}')", attr), "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Возвращает состояние элемента.
		*	Для selectable элементов вроде radio, checkbox, etc...
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		IsSelected() {
			url := Format("{}session/{}/element/{}/selected", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.IsSelected()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Доступен для взаимодействия?
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		IsEnabled() {
			url := Format("{}session/{}/element/{}/enabled", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.IsEnabled()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Показан?
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		IsDisplayed() {
			url := Format("{}session/{}/element/{}/displayed", this._API,this._sessionID,this.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":"element.IsDisplayed()", "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
		
		/*	Проверить, является ли переданный элемент, тем же самым элементом.
		*		Может быть не реализован, по причине того, что даже при запросе на поиск элемента
		*		по одному и тому же идентификатору, сервер генерирует всегда новый ID элемента.
		*			| https://github.com/appium/java-client/issues/227
		*		
		*	{"status":0,"value":true,"sessionId":"e6f8a520-ea5c-4eec-b7f9-1fd9ab217837"}
		*/
		AreEqual(otherElement) {
			url := Format("{}session/{}/element/{}/equals/{}", this._API,this._sessionID, this.element, otherElement.element)
			if ((o := __SearchContext._Get( url )).error)
				throw {"msg":Format("element.AreEqual('{}')", otherElement.element), "element":this.element, "error":o.error, "request":o.req}
			Return o.value
		}
	}
}
