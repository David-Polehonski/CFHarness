component name='MockService' accessors=true {

	public MockService function init () output='false' {
		if (isNull(application.cfharness.mockService)) {
			application.cfharness.mockService = this;

			this.services = {};
			this.observers = {};
		}
		
		return application.cfharness.mockService;
	}

	public static void function registerServiceHandler (required string serviceUrl, required string componentPath) output='false' {
		if (fileExists(expandpath('/testroot/' & LCase( replace(arguments.componentPath, '.', '/', 'all') ) & '.cfc'))) {
			try {
				var instance = new MockService();
				cfharness.core.Log::log("Adding #arguments.componentPath# for #arguments.serviceUrl#");
				instance.services[arguments.serviceUrl] = createObject('component', 'testroot.#arguments.componentPath#');
			} catch (any e) {
				cfharness.core.Log::warn("Failed to Instantiate #arguments.componentPath# for #arguments.serviceUrl#: #e.message#");
			}
		} else {
			cfharness.core.Log::log("Not Adding #expandpath('/testroot/' & LCase( arguments.componentPath ) & '.cfc')# for #arguments.serviceUrl#");
		}
	}

	public static void function discardServiceHandler (required string serviceUrl) output='false' {
		var instance = new MockService();
		if (StructKeyExists(instance.services, arguments.serviceUrl)) {
			cfharness.core.Log::log("Discarding handler for #arguments.serviceUrl#");
			StructDelete(instance.services, serviceUrl);
		}
	}

	public static any function getServiceHandler (required string serviceUrl) output='false' {
		cfharness.core.Log::log("Attempting to resolve handler for #arguments.serviceUrl#");
		var instance = new MockService();
		if (StructKeyExists(instance.services, arguments.serviceUrl)) {
			return duplicate( instance.services[arguments.serviceUrl] );
		}

		var registeredUrls = instance.services.keyArray();

		for (var urlExpression in registeredUrls) {
			if (reFindNoCase(urlExpression, arguments.serviceUrl, 0, false) > 0) {
				return duplicate( instance.services[urlExpression] );
			}
		}
		cfharness.core.Log::warn("Failed to Find Service handler for #arguments.serviceUrl#");
	}

	public static void function clearServiceHandlers () output='false' {
		cfharness.core.Log::log("Clearing all service handlers");
		var instance = new MockService();
		instance.services.clear();
	}

	public static string function observe (required string serviceUrl) output='false' {
		cfharness.core.Log::log("Begin Observing '#arguments.serviceUrl#' at #dateTimeFormat(now(), 'yyyy-mm-ddTHH:nn:ss:L')#");
		var instance = new MockService();
		var observerId = hash( arguments.serviceUrl & dateTimeFormat(now(), 'yyyy-mm-ddTHH:nn:ss:L') & RandRange(0, 255), 'MD5');
		instance.observers[ observerId ] = { 'url': arguments.serviceUrl, 'calls': [] };
		return observerId;
	}

	public static array function retrieveCalls (required string observerId) output='false' {
		cfharness.core.Log::log("Retrieving calls for '#arguments.observerId#'");
		var instance = new MockService();
		if (instance.observers.keyExists(arguments.observerId)) {
			return duplicate( instance.observers[arguments.observerId]['calls'] );
		} else {
			throw(type='InvalidObserverId', message="The ObserverId '#arguments.observerId#' is not valid");
		}
	}

	public static void function disregard (required string observerId) output='false' {
		cfharness.core.Log::log("Disregard calls for '#arguments.observerId#'");
		var instance = new MockService();
		if (instance.observers.keyExists(arguments.observerId)) {
			structDelete(instance.observers, arguments.observerId);
		}
	}

	public static void function clearObservers () output='false' {
		cfharness.core.Log::log("Clearing all observers");
		var instance = new MockService();
		instance.observers.clear();
	}

	//remote struct function {functionName} (required string param) method='httpMethod' route='/path/{@param}' output=false returnFormat='plain'
	public Response function request (
		required string serviceUrl,
		required string requestMethod=cgi.request_method,
		required string requestUrl=cgi.request_uri,
		required struct requestHeaders=static.getRequestHeaders(),
		required string requestBody=static.getRequestBody(),
		) output=false returnFormat='plain' {
		
		var methodArgs = {};
		//	Pick a Strategy, and delegate.
		try {
			//	Instantiate the Strategy component; and extract the available routes from the metadata
			request.strategy = static.getServiceHandler(arguments.serviceUrl);
			var requestCall = {
				'serviceUrl': arguments.serviceUrl,
				'method': arguments.requestMethod,
				'url': arguments.requestUrl,
				'querystring': structReduce(url, (a,k,v)=>{ return (len(a) === 0 ? '?' : (a & '&')) & URLEncodedFormat(k) & '=' & URLEncodedFormat(v) }, ''),
				'headers': arguments.requestHeaders,
				'body': arguments.requestBody
			};

			if (isNull(request.strategy)) {
				return this.respond(
					call=requestCall,
					contentBody="Available Services: #arrayToList(this.services.keyArray())#",
					contentType='text/plain',
					status='404'
				);
			}

			var meta = getComponentMetaData( request.strategy );
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
					if (reFindNoCase('^' & route & '\/?$' , arguments["serviceUrl"], 0, false) gt 0 and routes[r].keyExists(arguments.requestMethod) ) {
						//	IF you find an applicable route.
						var action = routes[r][arguments.requestMethod];
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

						parameters.headers = arguments.requestHeaders;
						if (listFind('PUT|POST', arguments.requestMethod, '|') gt 0) {
							parameters.body = arguments.requestBody;
						}

						StructAppend(parameters, FORM, true);
						StructAppend(parameters, URL, true);

						requestCall.parameters = parameters;

						try {
							var responseStruct = request.strategy[action](argumentCollection=parameters);
							responseStruct.call = requestCall;
							return this.respond(argumentCollection=responseStruct);
						} catch (any e) {
							cfharness.core.Log::error( 'Exception in MockService; #e.message#' );
							return this.respond(
								call=requestCall,
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
			cfharness.core.Log::log('Failed::#e.message#');
			return respond( argumentCollection = {'call': requestCall, contentBody='', contentType='text/plain', status: '500'} );
		}
		return respond( argumentCollection = {'call': requestCall, contentBody='', contentType='text/plain', status: '404'} );
	}

	public component function respond (required struct call, required string contentBody = '', required string contentType = 'text/plain', required string status='200') output=false {
		var responseStruct = {};
		switch(arguments.status) {
			case '200':
				responseStruct = {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 200,
						'text': 'OK'
					}
				}
				break;
			case '400':
				responseStruct = {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 400,
						'text': 'BAD REQUEST'
					}
				}
				break;
			case '401':
				responseStruct = {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 401,
						'text': 'NOT AUTHORIZED'
					}
				}
				break;
			case '404':
				responseStruct = {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 404,
						'text': 'NOT FOUND'
					}
				}
				break;
			case '500':
				responseStruct = {
					'response': arguments.contentBody,
					'responseType': arguments.contentType,
					'status': {
						'code': 500,
						'text': 'SERVER ERROR'
					}
				}
				break;
		}
		arguments.call.responseData = responseStruct;
		this.record( arguments.call );
		return new cfharness.core.Response( responseStruct );
	}

	private void function record (required struct call) output="false" {
		
		for( var observerId in this.observers ) {
			var observer = this.observers[observerId];
			cfharness.core.Log::log( "Record? #observer.url# == #call.serviceUrl#; #reFindNoCase(observer.url, call.serviceUrl, 0, false) != 0# " )
			if ( observer.url == call.serviceUrl or reFindNoCase(observer.url, call.serviceUrl, 0, false) > 0) {
				observer.calls.append( call );
			}
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
