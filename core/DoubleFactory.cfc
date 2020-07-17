/**
 - Dummy
 - - objects are passed around but never actually used. Usually they are just used to fill parameter lists.
 
 - Fake
 - - objects actually have working implementations, but usually take some shortcut which makes them not suitable for production.
 
 - Stubs 
 - - provide canned answers to calls made during the test, usually not responding at all to anything outside what's programmed in for the test.
 
 - Spies
 - - are stubs that also record some information based on how they were called. One form of this might be an email service that records how \
     many messages it was sent.
 
 - Mocks
 - - are pre-programmed with expectations which form a specification of the calls they are expected to receive. They can throw an exception if \
     they receive a call they don't expect and are checked during verification to ensure they got all the calls they were expecting.
**/
component name='DoubleFactory' {
	static {
		components = createObject('Java','java.util.HashMap');
	}
	
	public static component function generateDummy (required string componentPath = '') output="false" {
		var newDummy = static.loadComponentPath(argumentCollection=arguments);
		noopComponent(newDummy, getMetaData(newDummy));

		return newDummy;
	}

	private static void function noopComponent (required component newDummy, required struct metaData) output="false" {
		if(!arguments.metaData.keyExists('extends')) {
			var proxyScope = {};
			arguments.newDummy.throwOnCall = function (required string method, required string exception) {
				var exception = arguments.exception;
				proxyScope[arguments.method] = exception;
			}

			arguments.newDummy.noop = function (string functionName) {
				var fxName = arguments.functionName;
				return function () {
					if (proxyScope.keyExists(fxName))
						throw( type='DummyMethodExecutionError', message=proxyScope[fxName]);
				};
			}
		} else {
			noopComponent(arguments.newDummy, arguments.metaData.extends );
		}

		if(!isNull(arguments.metadata.functions)) {
			for (var fx in arguments.metadata.functions) {
				arguments.newDummy[fx.name] = arguments.newDummy.noop(fx.name); // Noop all the functions
			}
		}
	}

	public static component function generateStub (required string componentPath = '') output="true" {
		var newStub = static.loadComponentPath(argumentCollection=arguments);
		stubComponent(newStub, getMetaData(newStub) );

		return newStub;
	}

	private static void function stubComponent (required component newStub, required struct metaData) output="false" {
		if(!arguments.metaData.keyExists('extends')) {
			var proxyScope = {};
			var newStub = arguments.newStub;
			newStub.stubMethodCall = function (required string methodName) {
				var thisFunction = arguments.methodName;
				var thisScope = proxyScope;
				newStub[thisFunction] = function () {
					if (thisScope.keyExists(thisFunction)) {
						return (isCustomFunction(thisScope[thisFunction]) || isClosure(thisScope[thisFunction])) ? thisScope[thisFunction](argumentCollection=arguments): thisScope[thisFunction];
					}
					return JavaCast('null', 0);
				};
			};

			newStub.returnOnCall = function (required string method, required any return) {
				proxyScope[method] = arguments.return;
			};

		} else {
			stubComponent(newStub, arguments.metaData.extends );
		}

		if(!isNull(arguments.metadata.functions)) {
			for (var fx in arguments.metadata.functions) {
				// Stub all the functions
				newStub.stubMethodCall(fx.name);
			}

			if(arguments.metadata.accessors) {
				for (var px in arguments.metadata.properties) {
					// Stub all the accessors
					var setPx = 'set' & px.name;
					var getPx = 'get' & px.name;
					newStub.stubMethodCall(setPx);
					newStub.stubMethodCall(getPx);
				}
			}
		}
	}

	public static component function generateSpy (required string componentPath = '') output="false" {
		var newSpy = static.loadComponentPath(argumentCollection=arguments);
		var metadata = getMetaData(newSpy);

		var proxyScope = {};
		var spyMethodCall = function (required string methodName) {
			var thisFunctionName = arguments.methodName;
			var thisScope = proxyScope;
			return function () {
				thisScope[thisFunctionName]['called'] = true;
				thisScope[thisFunctionName]['calls'].append( arguments );
				if (thisScope[thisFunctionName].keyExists('returns')) {
					return (isCustomFunction(thisScope[thisFunctionName]['returns']) || isClosure(thisScope[thisFunctionName]['returns'])) ? thisScope[thisFunctionName]['returns'](argumentCollection=arguments): thisScope[thisFunctionName]['returns'];
				}
				return JavaCast('null', 0);
			};
		};

		newSpy.returnOnCall = function (required string method, required any return) {
			if (!proxyScope.keyExists(arguments.method)){
				proxyScope[method] = { 'called': false, 'calls': [], 'returns': javacast('null', 0) };
			}
			proxyScope[method]['returns'] = arguments.return;
			newSpy[method] = spyMethodCall(method);

			return newSpy;
		};

		newSpy.wasCalled = function(required string methodName) {
			writeDump(proxyScope);	
			if (proxyScope.keyExists(methodName)){
				return proxyScope[methodName]['called'];
			}
			return false;
		}

		newSpy.wasCalledWith = function(required string methodName, required struct args) {
			if (proxyScope.keyExists(methodName) && proxyScope[methodName]['called']) {
				var lastCall = proxyScope[methodName]['calls'][ arrayLen(proxyScope[methodName]['calls']) ];
				//	Return false if the number of args differs
				if (structCount(lastCall) != structCount(args)) {
					return false;
				}
				//	Now compare the args called and the args to verify against
				for(var argName in lastCall) {
					if(!lastCall.keyExists(argName) || lastCall[argName] != arguments.args[argName]) {
						return false;
					}
				}
				return true;
			}
			return false;
		}

		if(!isNull(metadata.functions)) {
			for (var fx in metadata.functions) {
				// Stub all the functions
				proxyScope[fx.name] = { 'called': false, 'calls': [], 'returns': javacast('null', 0) };
				newSpy[fx.name] = spyMethodCall(fx.name);
			}
		}

		return newSpy;
	}

	public static component function generateMock (required string componentPath = '') output="false" {
		var newMock = static.loadComponentPath(argumentCollection=arguments);
		var metadata = getMetaData(newMock);

		var proxyScope = {};
		var mockMethodCall = function (required struct methodDefinition) {
			var thisFunction = duplicate(arguments.methodDefinition);
			var thisScope = proxyScope;

			return function () {
				thisScope[thisFunction.name]['called'] = true;

				if (thisScope[thisFunction.name].keyExists('verify') && IsCustomFunction(thisScope[thisFunction.name]['verify'])){
					var verified = thisScope[thisFunction.name]['verify'](argumentCollection=arguments);
				} else {
					var verified = false;
				}

				thisScope[thisFunction.name]['calls'].append( {'arguments': arguments, 'verified': verified } );

				if (thisScope[thisFunction.name].keyExists('return')) {
					if (IsSimpleValue(thisScope[thisFunction.name]['return'])) {
						return thisScope[thisFunction.name]['return'];
					}
					if (IsCustomFunction(thisScope[thisFunction.name]['return'])) {
						return thisScope[thisFunction.name]['return'](argumentCollection=arguments);
					}
					return JavaCast('null', 0);
				}
			};
		};

		newMock.whenCalled = function(required string method, required function verify, any return){
			proxyScope[method] = {
				'called': false,
				'calls': [],
				'verify': arguments.verify,
				'return': arguments.keyExists('return')? arguments.return : JavaCast('null', 0)
			};
		};

		newMock.verify = function(required string method) {
			if(proxyScope.keyExists(method)){
				if(proxyScope[method].keyExists('called') && proxyScope[method]['called'] ){
					return proxyScope[method]['calls'][arrayLen(proxyScope[method]['calls'])]['verified'];
				}
				throw(type='MethodNotCalled', message="Method `#method#` was not called before verification");
			}
			throw(type='MethodNotObserved', message="Method `#method#` was not expected to be called");
		};

		if(!isNull(metadata.functions)) {
			for (var fx in metadata.functions) {
				// Stub all the functions
				newMock[fx.name] = mockMethodCall(fx);
			}
		}

		return newMock;
	}

	public static component function generateFake (required string componentPath = '') output="false" {
		var newFake = static.loadComponentPath(argumentCollection=arguments);
		var metadata = getMetaData(newFake);
	
		var proxyScope = {};
		
		newFake.overrideMethod = function (required string methodName) {
			var thisFunction = arguments.methodName;
			var thisScope = proxyScope;

			newFake[thisFunction] = function () {
				if(thisScope.keyExists(thisFunction))
					return thisScope[thisFunction](argumentCollection=arguments);
				return;
			};

			newFake.replaceWith = function (Function implementation) {
				thisScope[thisFunction] = implementation;
				newFake.replaceWith = javaCast('null', 0);
			};
			
			return newFake;
		};

		if(!isNull(metadata.functions)) {
			for (var fx in metadata.functions) {
				newFake.overrideMethod(fx.name);
			}
		}

		return newFake;
	}

	private static component function loadComponentPath(required string componentPath='') {
		if (arguments.componentPath == '') {
			arguments.componentPath = static.generateBlankComponent();
		}

		if (!static.components.containsKey(arguments.componentPath)) {
			static.components.put(arguments.componentPath, createObject('component', arguments.componentPath));
		}

		return duplicate(static.components.get(arguments.componentPath));
	}

	private static string function generateBlankComponent () {
		var initMethod = static.generateMethodSignature('init','component') & "{ return this; }";
		var componentTemplate = "component name='GenericTestDouble' { #initMethod# }";
		var componentPath = static.generateComponent('GenericTestDouble', componentTemplate);

		return componentPath;
	}

	private static string function generateComponent (required string componentName, required string componentTemplate) {
		var componentPath = application.cfharness.system.getScratchDirectory() & '\' & arguments.componentName;

		if (!fileExists(componentPath & '.cfc' )) {
			var fh = fileOpen(componentPath & '.cfc' , 'write' );
			fileWrite(fh, arguments.componentTemplate);
			fileClose(fh);
		}

		return replace(replace( componentPath, expandpath('/cfharness'), 'cfharness'), '\', '.', 'all');
	}

	private static string function generateMethodSignature(required String name, required string returnType = 'void', required string modifier = 'public') {
		return "#arguments.modifier# #arguments.returnType# function #arguments.name# ()";
	}
}
