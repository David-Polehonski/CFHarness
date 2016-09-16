component name="stub" accessors="true" {
	public function init(string cfcStub){
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
			if (StructKeyExists(THIS, "on#baseMetaName#")) {
				var fx = this["on#baseMetaName#"]();
				return fx;
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
