component extends='cfharness.core.aTestDouble' name='GenericTestDouble' {

	property type="component" name="component";

	public component function init (required string componentPath = '') output="false" {
		if (arguments.componentPath == '') {
			arguments.componentPath = this.generateBlankComponent();
		}
		return super.init( argumentCollection = arguments );
	}

	private string function generateBlankComponent () {
		var componentTemplate = "component name='GenericTestDouble' { public component function init () { return this; } }";
		var componentPath = application.cfharness.system.getScratchDirectory() & '\GenericTestDouble';

		if (!fileExists(componentPath & '.cfc' )) {
			var fh = fileOpen(componentPath & '.cfc' , 'write' );
			fileWrite(fh, componentTemplate);
			fileClose(fh);
		}

		return replace(replace( componentPath, expandpath('/cfharness'), 'cfharness'), '\', '.', 'all');
	}
}
