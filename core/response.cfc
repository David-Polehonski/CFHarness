//  response.cfc, convers/gathers response details and then send the response via it's stream method
component name='response' output='false' {

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
		// Add cache control headers
		if (!isNull(responseScope.status)) {
			cfheader(statuscode=responseScope.status.code, statustext=responseScope.status.text);
		}
		cfheader(name="Cache-Control", value="max-age=120");
		cfheader(name="Etag", value="#hash(binaryResponse, 'MD5')#");
		cfcontent(type="#(NOT structKeyExists(responseScope, 'responseType'))? 'text/html' : responseScope['responseType'] #", reset="true", variable="#binaryResponse#");
	}
}
