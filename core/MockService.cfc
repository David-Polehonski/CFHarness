component name='MockService' accessors=true {

	static {
		services = {};
	}

	property component strategy;

	public MockService function init () output='false' {
		if (isNull(application.cfharness.mockService)) {
			application.cfharness.mockService = this;
		}
		return this;
	}

	public static void function registerServiceHandler (required string serviceUrl, required string componentPath) output='false' {
		if (fileExists(expandpath('/testroot/' & LCase( arguments.componentPath ) & '.cfc'))) {
			try {
				cfharness.core.Log::log("Adding #arguments.componentPath# for #arguments.serviceUrl#");
				static.services[arguments.serviceUrl] = createObject('component', 'testroot.#arguments.componentPath#');
			} catch (any e) {
				cfharness.core.Log::warn("Failed to Instantiate #arguments.componentPath# for #arguments.serviceUrl#: #e.message#");
			}
		} else {
			cfharness.core.Log::log("Not Adding #expandpath('/testroot/' & LCase( arguments.componentPath ) & '.cfc')# for #arguments.serviceUrl#");
		}
	}

	public static void function discardServiceHandler (required string serviceUrl) output='false' {
		cfharness.core.Log::log("Discarding handler for #arguments.serviceUrl#");
		if (StructKeyExists(static.services, arguments.serviceUrl)) {
			StructDelete(static.services, serviceUrl);
		}
	}

	public static any function getServiceHandler (required string serviceUrl) output='false' {
		cfharness.core.Log::log("Attempting to resolve handler for #arguments.serviceUrl#");
		if (StructKeyExists(static.services, arguments.serviceUrl)) {
			return duplicate( static.services[arguments.serviceUrl] );
		}

		var registeredUrls = static.services.keyArray();

		for (var urlExpression in registeredUrls) {
			if (reFindNoCase(urlExpression, arguments.serviceUrl, 0, false) > 0) {
				return duplicate( static.services[urlExpression] );
			}
		}
		cfharness.core.Log::warn("Failed to Find Service handler for #arguments.serviceUrl#");
	}

	public static void function clearServiceHandlers () output='false' {
		cfharness.core.Log::log("Clearing all service handlers");
		static.services.clear();
	}

	//remote struct function {functionName} (required string param) method='httpMethod' route='/path/{@param}' output=false returnFormat='plain'
	public Response function request (required string serviceUrl) output=false returnFormat='plain' {
		var methodArgs = {};
		//	Pick a Strategy, and delegate.
		try {
			//	Instantiate the Strategy component; and extract the available routes from the metadata
			this.setStrategy( static.getServiceHandler(arguments.serviceUrl) );
			if (isNull(this.getStrategy())) {
				return this.respond(
					contentBody="Available Services: #arrayToList(static.services.keyArray())#",
					contentType='text/plain',
					status='404'
				);
			}

			var meta = getComponentMetaData( this.getStrategy() );
			var routes = {};

			for (var i = 1; i <= arrayLen(meta.functions); i++) {
				if (StructKeyExists(meta.functions[i], "route") && meta.functions[i]["access"] IS 'remote') {
					if (!structKeyExists(routes, meta.functions[i]["route"])) {
						routes[ meta.functions[i]["route"] ] = {};
					}
					routes[ meta.functions[i]["route"] ][ meta.functions[i]["method"] ] = meta.functions[i]["name"];
				}
			}

			if (structKeyExists(arguments, 'serviceUrl')) {
				// Now see if the desired Strategy has a valid route handler:
				var variableDef = "{\@([a-zA-Z_\$][0-9a-zA-Z_\$]*)?\}";
				var valueDef = "([a-zA-Z_\$][0-9a-zA-Z_\$\-\.]*)";
				for (r in routes) {
					// Use a regex to convert the route into a regex for inserting values.
					route = reReplace(r, variableDef, valueDef, 'all');

					if (reFindNoCase('^' & route & '\/?$' , arguments["serviceUrl"], 0, false) gt 0 and routes[r].keyExists(cgi.request_method) ) {
						//	IF you find an applicable route.
						var action = routes[r][cgi.request_method];
						var args = {'names': reMatchNoCase(variableDef, r), 'values': []};


						var values = reFindNoCase('^' & route & '\/?$' , arguments["serviceUrl"], 1, true);
						//	Skip the first value, as it is the whole match
						for (var v=2; v <= arrayLen(values["len"]); v++) {
							arrayAppend(args["values"], mid(arguments["serviceUrl"], values["pos"][v], values["len"][v]));
						}

						if (arrayLen(args["names"]) != arrayLen(args["values"])) {
							throw('invalid parameter counts; #arrayToList(args["names"],',')#|#arrayToList(args["value"],',')#');
						}


						var parameters = arrayReduce(args["names"], function(result, item, index){
							result[REReplace(item, '\{\@([a-zA-Z_\$][0-9a-zA-Z_\$]*)\}', '\1')] = args["values"][index];
							return result;
							}, StructNew());

						parameters.headers = static.getRequestHeaders();
						if (listFind('PUT|POST', cgi.request_method, '|') gt 0) {
							parameters.body = static.getRequestBody();
						}

						StructAppend(parameters, FORM, true);
						StructAppend(parameters, URL, true);

						try {



							return this.respond(argumentCollection=this.getStrategy()[action](argumentCollection=parameters));
						} catch (any e) {
							cfharness.core.Log::error( 'Exception in MockService; #e.message#' );
							return this.respond(
								contentBody=e.message,
								contentType='text/plain',
								status='500'
							);
						}
					}
				}
			}

		} catch (any e) {
			cfheader(name='content-type', value='text/html');
			WriteOutput(e.message); abort;
			return respond(status='500');
		}
		return respond(status='404');
	}

	public component function respond (required string contentBody = '', required string contentType = 'text/plain', required string status='200') output=false {
		switch(arguments.status) {
			case '200':
				return new cfharness.core.Response( {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 200,
						'text': 'OK'
					}
				});
				break;
			case '401':
				return new cfharness.core.Response( {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 401,
						'text': 'NOT AUTHORIZED'
					}
				});
			case '404':
				return new cfharness.core.Response( {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 404,
						'text': 'NOT FOUND'
					}
				});
			case '500':
				return new cfharness.core.Response( {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 500,
						'text': 'SERVER ERROR'
					}
				});
				break;
		}
	}

	//	Private methods
	private static struct function getRequestHeaders () output=false {
		var data = structFind(getHTTPRequestData(), 'headers');
		return data;
	}

	private static string function getRequestBody () output=false {
		var data = toString( structFind(getHttpRequestData(), 'content' ) );
		return data;
	}

}
