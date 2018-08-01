component name="Assertion" extends='aCondition' {
	static {
		assertionResult=createObject('cfharness.core.AssertionResult');
	}

	public Assertion function init(required component testContext) output="false" {
		super.init(argumentCollection=arguments);
		return this;
	}

	public any function getEvaluation() output="false" {
		return duplicate( variables.expression );
	}

	public Assertion function assert (required any assertionExpression, required string assertionDescription ) output="false" {
		variables.description = arguments.assertionDescription;
		variables.expression = arguments.assertionExpression;

		variables.assertionType =
			(IsCustomFunction( variables.expression ) || isClosure( variables.expression ))?
				'f' : isValid('boolean', variables.expression)?
				'b' : IsSimpleValue(variables.expression)?
				'v' : IsValid('component', variables.expression)?
				'o' : throw(type='InvalidExpressionType', message='Expression passed to assertion cannot be evaluated')

		variables._ = {
			"description": variables.description,
			"result": false,
			"reasonForFailure": "Not Yet Executed"
		};

		return this;
	}

	public AssertionResult function getResult() output="false" {
		if ( isNull(variables.expressionResult) ) {
			switch(variables.assertionType) {
				case 'f':
					this.returnsTrue();
					break;
				case 'b':
					this.equalsTrue();
					break;
			}
		}

		var result = duplicate( static.assertionResult ).init( result=variables._ );
		return result;
	}

	public Assertion function returnsTrue() output='false' {
		//	For function expressions:
		try {
			variables.tc.beforeAssert(this);

			variables._.result = variables.expression();
			variables._.reasonForFailure = "";

			if (!isValid('boolean', variables._.result)) {
				variables._.result = false;
				variables._.reasonForFailure = 'Method or Closure did not return a boolean value';
			} else if (variables._.result != true) {
				variables._.result = false;
				variables._.reasonForFailure = 'Method or Closure did not return true';
			}
		} catch (any e) {
			variables._.result = false;
			variables._.reasonForFailure = serializeJson( {e.type: e.message, 'detail': e.detail} );
		}
		variables.tc.afterAssert(this);
		return this;
	}

	public Assertion function equalsTrue() output='false' {
		//	For function expressions:
		variables.tc.beforeAssert(this);

		if (variables.expression == true) {
			variables._.result = true;
			variables._.reasonForFailure = "";
		} else {
			variables._.result = false;
			variables._.reasonForFailure = 'Expression or value did not evaluate as true';
		}

		variables.tc.afterAssert(this);
		return this;
	}

	public Assertion function equals(required any value) output='false' {
		//	For function expressions:
		variables.tc.beforeAssert(this);

		if (variables.expression == arguments.value) {
			variables._.result = true;
			variables._.reasonForFailure = "";
		} else {
			variables._.result = false;
			variables._.reasonForFailure = 'Expression or value [#variables.expression#] did not pass equality test';
		}

		variables.tc.afterAssert(this);
		return this;
	}

	public Assertion function matches(required string regex) output='false' {
		//	For function expressions:
		variables.tc.beforeAssert(this);

		if (REFindNoCase(arguments.regex, variables.expression) != 0) {
			variables._.result = true;
			variables._.reasonForFailure = "";
		} else {
			variables._.result = false;
			variables._.reasonForFailure = 'Expression or value [#variables.expression#] did not pass equality test';
		}

		variables.tc.afterAssert(this);
		return this;
	}

	public Assertion function isNull() output='false' {
		//	For function expressions:
		variables.tc.beforeAssert(this);

		if (isNull(variables.expression)) {
			variables._.result = true;
			variables._.reasonForFailure = "";
		} else {
			variables._.result = false;
			variables._.reasonForFailure = 'Expression does not evaluate to null';
		}

		variables.tc.afterAssert(this);
		return this;
	}

	public Assertion function isNotNull() output='false' {
		//	For function expressions:
		variables.tc.beforeAssert(this);

		if (!isNull(variables.expression)) {
			variables._.result = true;
			variables._.reasonForFailure = "";
		} else {
			variables._.result = false;
			variables._.reasonForFailure = 'Expression evaluates to null';
		}

		variables.tc.afterAssert(this);
		return this;
	}

	// public void function throws(required string exceptionType) output='false' {
	// 	//	For function expressions:
	// 	variables.tc.beforeAssert(this);
	//
	// 	if (variables.expression == arguments.value) {
	// 		variables._.result = true;
	// 		variables._.reasonForFailure = "";
	// 	} else {
	// 		variables._.result = false;
	// 		variables._.reasonForFailure = 'Expression or value did not pass equality test';
	// 	}
	//
	// 	variables.tc.afterAssert(this);
	// }
}
