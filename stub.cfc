component name="stub" accessors="true" {
	public function init(cfcStub){
		var baseObj = createObject('component', '#cfcStub#');

		for(var i in baseObj) {
			if (IsCustomFunction(baseObj[i])){
				createFunction(GetMetaData(baseObj[i]));
			} else {
				createProperty(GetMetaData(baseObj[i]));
			}
		}

		VARIABLES.baseObj = baseObj;
		return THIS;
	}

	private void function createFunction(baseMeta) {

		THIS[baseMeta.name] = function () {
			if (StructKeyExists(THIS, "on#baseMeta.name#")) {
				var fx = this["on#baseMeta.name#"]();
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
		THIS['on#ARGUMENTS.functionName#'] = callback;
		return THIS;
	}

}
