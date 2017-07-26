component name="stub" accessors="true" initmethod="_init" {
	public function _init(string cfcStub){
		if (StructKeyExists(arguments, "cfcStub")) {
			var baseObj = createObject('component', '#cfcStub#');

			for(var i in baseObj) {
				if (IsCustomFunction(baseObj[i])){
					createFunction(GetMetaData(baseObj[i]).name);
				} else {
					createProperty(GetMetaData(baseObj[i]));
				}
			}

			//VARIABLES.baseObj = baseObj;
		}
		return THIS;
	}

	private void function createFunction(baseMetaName) {

		THIS[baseMetaName] = function () {
			param name="arguments" default={};
			if (StructKeyExists(THIS, "on#baseMetaName#")) {
				return this["on#baseMetaName#"](argumentCollection=arguments);
			} else {
				//	Could replace with defaults later?
				return JavaCast('null', 0);
			}
		}
	}
	private void function createProperty() {
		WriteDump(baseMeta);
	}

	public stub function onFunctionCall(required string functionName, required function callback) {
		if (!StructKeyExists(this, arguments.functionName) OR !IsCustomFunction(this[arguments.functionName])){
			createFunction(arguments.functionName);
		}
		THIS['on#ARGUMENTS.functionName#'] = callback;
		return THIS;
	}

}
