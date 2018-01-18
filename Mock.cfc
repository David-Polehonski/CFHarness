component name="mock" accessors="false" {

	property object base;
	property array callStack;

	public function init (string cfcStub) {
		if (StructKeyExists(arguments, "cfcStub")) {

			variables.baseObject = createObject('component', '#cfcStub#');
			variables.callStack = [];

			for(var i in variables.baseObject) {
				if (IsCustomFunction(variables.baseObject[i])){
					createFunction(GetMetaData(variables.baseObject[i]).name, variables.baseObject[i]);
				} else {
					createProperty(GetMetaData(variables.baseObject[i]));
				}
			}

			variables.baseObject.onFunctionCall = function (required string functionName, required function callback) {
				if (!StructKeyExists(this, arguments.functionName) OR !IsCustomFunction(this[arguments.functionName])){
					createFunction(arguments.functionName);
				}
				this['on#ARGUMENTS.functionName#'] = callback;
			};

			var MockScope = {};
			variables.baseObject.setProperty = function (required string propertyName, required any propertyValue) {
				MockScope[arguments.propertyName] = arguments.propertyValue;
			};
			variables.baseObject.getProperty = function (required string propertyName) {
				if (MockScope.keyExists(arguments.propertyName)) {
					return MockScope[arguments.propertyName];
				}
				return JavaCast('null', 0);
			};

		} else {
			createFunction('init'); // Force override init method.
		}
		return variables.baseObject;
	}

	private void function createFunction(baseMetaName) {
		variables.baseObject[baseMetaName] = function () {
			param name="arguments" default={};
			arrayAppend(variables.callStack, {'#baseMetaName#': duplicate( arguments )});
			if (StructKeyExists(this, "on#baseMetaName#")) {
				return this["on#baseMetaName#"](argumentCollection=arguments);
			} else {
				return JavaCast('null', 0);
			}
		};
	}

}
