component name="AssertionResult" {

	public AssertionResult function init (required struct result) output="false" {
		variables.result = arguments.result; // This is a reference to the internal data of the parent Assertion.
		return this;
	}

	public string function getDescription() {
		return variables.result.description;
	}

	public string function hasPassed() {
		return variables.result.result;
	}

	public string function hasFailed() {
		return !variables.result.result;
	}

	public string function getReasonForFailure() {
		return variables.result.reasonForFailure;
	}

}
