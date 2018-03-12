component name="TestResult" output="false" {
	public TestResult function init (required string description, required struct r) {

		variables.test = description;
		variables.result = r.result;

		if (structKeyExists(r, 'reason')) {
			variables.reason = r.reason;
		} else{
			variables.reason = "";
		}

		return this;
	}

	public string function getTest() {
		return variables.test;
	}

	public string function getResult() {
		return variables.result;
	}

	public string function getReason() {
		return variables.reason;
	}

}
