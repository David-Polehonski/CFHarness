component name='TestServiceHandler' {

	remote struct function simpleTest (required struct headers, required string name) method='GET' route='/testing/{@name}' output=false returnFormat='plain' {
		//	Check Authorization header, then return the example json response
		return {
			'contentBody': serializeJson({ 'response': arguments.name }),
			'contentType': 'application/json',
			'status': 200
		};
	}

	remote struct function simpleExceptionTest (required struct headers) method='GET' route='/explode/' output=false returnFormat='plain' {
		//	Check Authorization header, then return the example json response
		throw(type='AbitraryExplosionError', message="Boom!");
	}
}
