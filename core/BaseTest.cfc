/*@BaseTest.cfc

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

	public component function run() output=true {

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
				assert(false, "An unexpected error was thrown in #fx# :: #e.message#");
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

	public Assertion function assert (required any assertion, required string description) output="false" {
		if (!variables.tests.keyExists(getCurrentTest())){
			variables.tests[getCurrentTest()] = [];
			variables.results[getCurrentTest()] = structNew('linked');
		}

		var assertion = new cfharness.core.Assertion(this);

		variables.tests[getCurrentTest()].append(description);
		variables.results[getCurrentTest()][description]= assertion.assert(arguments.assertion, arguments.description).getResult(); // Returns a reference to the result data, so if we modify the assertion the new result is used.

		return assertion;
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
