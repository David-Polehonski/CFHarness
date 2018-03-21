component implements='iTestDouble' displayname='aTestDouble' {

	property type="component" name="component";

	public component function init (required string componentPath) output="false" {
		variables.component = createObject('component', componentPath);
		variables.metadata = getMetaData(	variables.component );

		variables.functions = arrayReduce(variables.metadata.functions, (acc, fx) => {
			acc[fx.name] = fx;
			return acc
		}, {} );

		variables.properties = arrayReduce(variables.metadata.properties, (acc, p) => {
			acc[p.name] = p;
			return acc
		}, {} );

		variables.calls = [];
		variables.instance = {};

		variables.component.when = function () { return this.when(argumentCollection=arguments); }; //	Add when listener

		return variables.component;
	}

	public component function when(required string methodOrPropertyName) output="false" {
		if (variables.functions.keyExists( methodOrPropertyName )) {
			variables.current = {'type': 'method', 'name': methodOrPropertyName};
			return this;
		}
		if (variables.properties.keyExists( methodOrPropertyName )) {
			variables.current = {'type': 'property', 'name': methodOrPropertyName};
			return this;
		}
		variables.current = {'type': '', 'name': methodOrPropertyName};
		return this;
	}

	public component function isCalled( required any return ) output="false" {
		var functionName = variables.current['name'];
		var returnValue = arguments.return;

		if (IsSimpleValue(arguments.return)) {
			variables.component[functionName] = function () {
				this.onFunctionCall(functionName, duplicate(arguments), returnValue);
				return returnValue;
			};
		} else if (IsCustomFunction(returnValue)) {
			variables.component[functionName] = function () {
				try {
					var returnValue = returnValue(argumentCollection=arguments);
				} catch (any e) {
					returnValue = e.message;
				} finally {
					this.onFunctionCall(functionName, duplicate(arguments), returnValue);
					return returnValue;
				}
			};
		}

		variables.current = JavaCast('null', 0);

		return variables.component;
	}

	public component function isSet() output="false" {}
	public component function isGot() output="false" {}

	private void function onFunctionCall (required string functionName, required struct arguments, required any result ) {
		variables.calls.append( {'function': functionName, 'arguments': arguments, 'result': result} );
	}

}
