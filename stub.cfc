component name="stub" accessors="true" {

	property object base;

	public function init () {
		createFunction('init'); // Force override init method.
		return this;
	}

	private void function createFunction(baseMetaName) {
		this[baseMetaName] = function () {
			param name="arguments" default={};

			if (StructKeyExists(this, "on#baseMetaName#")) {
				return this["on#baseMetaName#"](argumentCollection=arguments);
			} else {
				return JavaCast('null', 0);
			}
		};
	}

	private void function createProperty() {
		WriteDump(baseMeta);
	}

	public stub function onFunctionCall(required string functionName, required function callback) {
		if (!StructKeyExists(this, arguments.functionName) OR !IsCustomFunction(this[arguments.functionName])){
			createFunction(arguments.functionName);
		}

		this['on#ARGUMENTS.functionName#'] = callback;

		return this;
	}

}
