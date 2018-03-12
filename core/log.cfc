component name='log' {
	variables.file= application['cfharnessLog'];
	variables.types = ['information','warning','error','fatal'];
	variables.application = true;

	public void function init (required string text, required string type = variables.types[1]) output='false'{
		this.log(type=arguments.type, logText=arguments.text);
	}

	public void function log (required string logfile = variables.file, required string type = variables.types[1], required string logText) output='false' {
		writeLog(text=arguments.logText, type=arguments.type, application=variables.application, file=arguments.logFile);
	}
}
