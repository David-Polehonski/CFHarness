component name='DoubleFactory' {
	static {
		components = createObject('Java','java.util.HashMap');
	}

	public static component function generateDummy (required string componentPath = '') output="false" {
		var newDummy = static.loadComponentPath(argumentCollection=arguments);
		var metadata = getMetaData(newDummy);

		newDummy.throwOnCall = function (required string method, required string exception) {
			var exception = arguments.exception;
			newDummy[arguments.method] = function () { throw( type='DummyMethodExecutionError', message=exception) };
		}

		if(!isNull(metadata.functions)) {
			for (var fx in metadata.functions) {
				newDummy[fx.name] = function () {}; // Noop all the functions
			}
		}

		return newDummy;
	}

	public static component function generateStub (required string componentPath = '') output="false" {
		var newStub = static.loadComponentPath(argumentCollection=arguments);
		var metadata = getMetaData(newStub);

		var proxyScope = {};
		var stubMethodCall = function (required struct methodDefinition) {
			var thisFunction = duplicate(arguments.methodDefinition);
			var thisScope = proxyScope;
			return function () {
				if (thisScope.keyExists(thisFunction.name)) {
					return thisScope[thisFunction.name];
				}
				return JavaCast('null', 0);
			};
		};

		newStub.returnOnCall = function (required string method, required any return) {
			proxyScope[method] = arguments.return;
		};

		if(!isNull(metadata.functions)) {
			for (var fx in metadata.functions) {
				// Stub all the functions
				newStub[fx.name] = stubMethodCall(fx);
			}
		}

		return newStub;
	}

	public static component function generateSpy (required string componentPath = '') output="false" {
		var newSpy = static.loadComponentPath(argumentCollection=arguments);
		var metadata = getMetaData(newSpy);

		var proxyScope = {};
		var spyMethodCall = function (required struct methodDefinition) {
			var thisFunction = duplicate(arguments.methodDefinition);
			var thisScope = proxyScope;
			return function () {
				thisScope[thisFunction.name]['called'] = true;
				thisScope[thisFunction.name]['calls'].append( arguments );
				return JavaCast('null', 0);
			};
		};

		newSpy.wasCalled = function(required string methodName) {
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
				proxyScope[fx.name] = { 'called': false, 'calls': [] };
				newSpy[fx.name] = spyMethodCall(fx);
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
						return thisScope[thisFunction.name]['return']();
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

	// public static component function generateFake (required string componentPath = '') output="false" {
	// 	var newFake = static.loadComponentPath(argumentCollection=arguments);
	// 	var metadata = getMetaData(newFake);
	//
	// 	var proxyScope = {};
	//
	// 	return newFake;
	// }

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
		var componentTemplate = "component name='BlankDouble' { public component function init () { return this; } }";
		var componentPath = static.generateComponent('BlankDouble', componentTemplate);

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

}
