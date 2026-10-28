component name='log' {

	static {
		file = application['cfharnessLog'];
		types = ['information','warning','error','fatal'];
		application = true;
	}

	public void function init (required string text, required string type = static.types[1]) output='false' {
		static.log(type=arguments.type, logText=arguments.text);
	}

	public static void function log (required string logText, required string logfile = static.file, required string type = static.types[1]) output='false' {
		writeLog(text=arguments.logText, type=arguments.type, application=static.application, file=arguments.logFile);
	}

	public static void function warn (required string logText, required string logfile = static.file, required string type = static.types[2]) output='false' {
		writeLog(text=arguments.logText, type=arguments.type, application=static.application, file=arguments.logFile);
	}

	public static void function error (required string logText, required string logfile = static.file, required string type = static.types[3]) output='false' {
		writeLog(text=arguments.logText, type=arguments.type, application=static.application, file=arguments.logFile);
	}

	public static void function fatal (required string logText, required string logfile = static.file, required string type = static.types[4]) output='false' {
		writeLog(text=arguments.logText, type=arguments.type, application=static.application, file=arguments.logFile);
	}

}
