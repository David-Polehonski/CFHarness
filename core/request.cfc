component name='request' accessors='true' output='true' {

	property name="endpoint" type="string";

	public Request function init() output='false' {
		cflock( name='cfharnessCoreRequestInit', timeout='5' ) {
			variables.instance = request; // internal reference to request scope, managed by this object.
			if (isNull(variables.instance.self)){
				variables.instance.self = this;

				variables.instance.tests = createObject('java', 'java.util.HashMap'); // Want to preserve the order of execution
				variables.instance.results = createObject('java', 'java.util.HashMap'); // Want to preserve the order of execution

				variables.instance.passed = 0;
				variables.instance.failed = 0;

				variables.instance.context = {};
				variables.instance.context.testCount = 0;

				variables.instance.context.previousTests = JavaCast('null', 0);
				variables.instance.context.currentTest = new cfharness.BaseTest('Application Initialization');
			}
		}
		return this;
	}

	public boolean function queueTest(required component testObject) output='false' {
		variables.instance.tests.put(arguments.testObject.getTestName(), arguments.testObject);
		return true;
	}

	public any function getCurrentTest() {
		return (!isNull(variables.instance.context.currentTest)) ? variables.instance.context.currentTest : javacast('null', 0);
	}

	public void function setCurrentTest(required component testObject) {
		if (isNull(variables.instance.context.previousTests)) {
			variables.instance.context.previousTests = arrayNew();
			variables.instance.context.previousTests.resize( variables.instance.tests.size() );
		}

		variables.instance.context.previousTests[++variables.instance.context.testCount] = variables.instance.context.currentTest;
		variables.instance.context.currentTest = arguments.testObject;
	}

	public void function run() output='false' {
		for (var key in variables.instance.tests) {
			variables.instance.tests[key].run();
			this.addResult( variables.instance.tests[key] );
		}
	}

	public void function addResult(required component testObject) output='true' {

		var test = arguments.testObject;
		var tests = arguments.testObject.getTests();
		var results = arguments.testObject.getResults();


		if (tests.count() GT 0) {

			var resultSet = structNew('linked');

			for(var setName in tests) {

				resultSet[setName] = arrayNew();
				resultSet[setName].resize(tests[setName].len());

				var n = 1;
				for(var testName in tests[setName]){
					resultSet[setName][n++] = new cfharness.TestResult(testName, results[setName][testName]);

					switch (resultSet[setName][n-1].getResult()) {
					case "Passed":
						variables.instance.passed += 1;
						break;
					case "Failed":
						variables.instance.failed += 1;
						break;
					}

				}

				variables.instance.results.put(test.getTestName(), resultSet);
			}
		}
	}

	public void function finalize() {
		variables.instance.context.previousTests[++variables.instance.context.testCount] = variables.instance.context.currentTest;
		variables.instance.context.currentTest = JavaCast('null', 0);
	}

	public string function getResponseType() output='false' {
		if (isNull(variables.instance.responseType)) {
			variables.instance.responseType = 'text/html';
		}
		return variables.instance.responseType;
	}

	public void function setResponseType(required string newResponseType) output='false' {
		variables.instance.responseType = arguments.newResponseType;
	}

	public Response function getResponse() output='false' {
		var responseScope = {};

		responseScope.response = variables.instance.response;
		responseScope.responseType = getResponseType();
		return new cfharness.core.Response(  responseScope );
	}

	public void function setResponse(required any newResponse) output='false' {
		variables.instance.response = arguments.newResponse;
	}
}
