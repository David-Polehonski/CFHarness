/*@base-test.cfc
    Copyright Ouse Creative Ltd 2015
    Author David Polehonski <david@ousecreative.co.uk>

#   Base component for creating unit tests.

*/
component name="BaseTest" output=false accessors=true {

	property string error;
	property struct results;
	property struct tests;

	property string testName;

	public any function init (required string testName=this.testName) output="false" {

		this.setTestName(arguments.testName);

		variables.tests = structNew('linked');
		variables.results = structNew('linked');
		variables.rc = application.cfharness.system.getRequest();
		variables.rc.queueTest(this);

		return this;
	}

	public component function run() output=false {

		variables.rc.setCurrentTest(this);

		try {
			this.setup();
		} catch (any Ex) {
			//	Capture failures as failed tests.
			assert(false, "An unexpected error was thrown in setup, #Ex.message#");
			return this;
		}

		var testArray = [];

		for (var name in this) {
			//	Store all test names.
			if (arrayLen(REMatchNoCase('^test([a-z0-9_]+)', name))) {
				if (IsCustomFunction(this[name]) OR isClosure(this[name])) {
					testArray.append(name);
				}
			}
		}
		//	Sort the array using the custom 'order' function attribute.
		arraySort(testArray, function (a, b){
			var firstItem = GetMetaData(this[a]);
			var secondItem = GetMetaData(this[b]);


			StructAppend(firstItem, {'order' = 100}, false);
			StructAppend(secondItem, {'order' = 100}, false);

			if(int(firstItem.order) GT int(secondItem.order)){
				return 1;
			}else if (int(firstItem.order) LT int(secondItem.order)){
				return -1;
			} else {
				return 0;
			}
		});

		for (var fx in testArray) {
			setCurrentTest(fx);
			this.proxy = this[fx];
			try {
				this.proxy();
			} catch (e) {
				this.setError(e.message);
				if (e.detail IS NOT ""){
					this.setError(e.detail);
				}
				assert(false, "An unexpected error was thrown in #fx#");
			}
		}

		try {
			this.tearDown();
		} catch (any Ex) {
			assert(false, "An unexpected error was thrown during tearDown, #Ex.message#");
			return this;
		}

		return this;
	}

	public void function setup () output="false" {
		/* Call any setup */
		this.onSetup();
		return;
	}

	public void function tearDown () output="false" {
		/* Call any tearDowns */
		this.onTearDown();
		return;
	}

	private struct function createResult(required boolean result) output="false" {
		var r = structnew();
		var result = arguments.result;

		r['isPassed'] = function () { return result; };
		r['result'] = arguments.result? 'Passed' : 'Failed';

		if (NOT arguments.result) {
			r['reason'] = this.getError();
		}

		return r;
	}

	public boolean function assert (required any assertion, required string description) output="false" {
		if (!variables.tests.keyExists(getCurrentTest())){
			variables.tests[getCurrentTest()] = [];
			variables.results[getCurrentTest()] = structNew('linked');
		}

		variables.tests[getCurrentTest()].append(description);

		this.beforeAssert(argumentCollection = arguments);

		if (IsValid('boolean', arguments.assertion)){
			if(NOT arguments.assertion AND this.getError() IS '') {
				this.setError("Assertion returned false");
			}

			variables.results[getCurrentTest()][description] = createResult(arguments.assertion);

			} else if (IsCustomFunction(ARGUMENTS.assertion) OR isClosure(ARGUMENTS.assertion)){

			try {
				proxy = arguments.assertion;
				variables.results[getCurrentTest()][description] = createResult(proxy());
				proxy = JavaCast('null', 0);
			} catch (e) {
				this.setError(e.message);

				if(e.detail IS NOT '') {
					this.setError(e.detail);
				}

				variables.results[getCurrentTest()][description] = createResult(false);
			}
		}

		this.afterAssert(argumentCollection = variables.results[getCurrentTest()][description]);
		this.setError('');

		return variables.results[getCurrentTest()][description].isPassed();
	}

	public void function setCurrentTest(required string testMethod) output=false {
		variables.currentTestMethod = arguments.testMethod;
	}

	public string function getCurrentTest() output=false {
		return variables.currentTestMethod;
	}

	/* Events for overriding */
	public void function onSetup (){ return; }
	public void function beforeAssert (){ return; }
	public void function afterAssert (){ return; }
	public void function onTearDown (){ return; }

}
