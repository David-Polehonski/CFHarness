//  response.cfc, convers/gathers response details and then send the response via it's stream method
component name='response' output='false' {

	public string function getResponse() {
		return this.responseScope.response;
	}

	public string function getStatusCode() {
		return this.responseScope.status.code;
	}

	public Response function init (required struct responseScope) output='false' {
		this.responseScope = arguments.responseScope;
		if (isNull(this.responseScope.response)) {
			this.responseScope.response = "";
		}
		return this;
	}

	public void function stream (required struct responseScope = this.responseScope) output='true' {
		// Create BINARY representation to stream
		if (!IsBinary(responseScope.response)) {
			var binaryResponse = toBinary( toBase64( trim(responseScope.response) ) );
		} else {
			var binaryResponse = responseScope.response;
		}
		if (!isNull(responseScope.status)) {
			cfheader(statuscode=responseScope.status.code, statustext=responseScope.status.text);
		}
		// Test results and mock service responses change from one run to the next.
		cfheader(name="Cache-Control", value="no-store");
		cfcontent(type="#(NOT structKeyExists(responseScope, 'responseType'))? 'text/html' : responseScope['responseType'] #", reset="true", variable="#binaryResponse#");
	}
}
