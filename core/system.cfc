/*
	cfharness.system component is a singleton container for system interations i.e;
	writing to or from the file system.
*/
component name='system' output='false' {

	property name='errorCodePrefix';
	property name='scratchDirectory';

	public system function init (required string scratchDirectoryPath=getDirectoryFromPath( getCurrentTemplatePath() ) & '_scratch') output='false' {

		variables.errorCodePrefix = '5';

		if (!application.keyExists('cfharness')) {
				throw( new testException(
					message='Cannot instantiate cfharness.system object outside of a cfharness application context',
					detail='Key `cfharness` was not found in the application scope when the system object was instantiated',
					errorCode=variables.errorCodePrefix & '1'
				) );
		}

		if (application.keyExists('cfharness') && !application['cfharness'].containsKey('system')) {
			//	set default scratch directory
			this.setScratchDirectory(arguments.scratchDirectoryPath);
			application['cfharness']['system'] = this;
		}

		return application['cfharness']['system'];
	}

	public string function getScratchDirectory () output='false' {
		return variables.scratchDirectory;
	}

	public void function setScratchDirectory (required string newscratchDirectory ) output='false' {
		this.deleteScratchDirectory();

		variables.scratchDirectory = arguments.newscratchDirectory;

		this.createScratchDirectory();
	}

	public void function createScratchDirectory () output='false' {
		if (!isNull( variables.scratchDirectory ) && !directoryExists( variables.scratchDirectory )) {
			directoryCreate( variables.scratchDirectory );
		}
	}

	public void function deleteScratchDirectory () output='false' {
		if (!isNull( variables.scratchDirectory ) && directoryExists( variables.scratchDirectory )) {
			directoryDelete( variables.scratchDirectory, true);
		}
	}

	public Request function getRequest () output='true' {
		if (isNull(variables.requestInstance)) {
			variables.requestInstance = createObject('component', 'cfharness.core.request');
		}

		return duplicate(variables.requestInstance).init();
	}

	public void function reset () output='false' {
		applicationStop();
		location( url='run.cfm', addToken='false', statusCode='303' );
	}
}
