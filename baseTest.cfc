/*@base-test.cfc
    Copyright Ouse Creative Ltd 2015
    Author David Polehonski <david@ousecreative.co.uk>

#   Base component for creating unit tests.

*/
component name="baseTest" output=false accessors=true {

	property string error;
	property struct results;
	property struct tests;

	property string testName;

    public any function init (required string testName=THIS.testName) output="false" {

		THIS.setTestName(ARGUMENTS.testName);

        REQUEST.TESTS[THIS.getTestName()] = THIS; // Store reference into request.

		VARIABLES.tests = structNew('linked');
		VARIABLES.results = structNew('linked');
		VARIABLES.setup();

        return THIS;
    }

	public component function run() output="false" {

		application.cfharness.setCurrentTest(THIS);

		var testArray = [];

		for (var name in THIS) {
			//	Store all test names.
			if (arrayLen(REMatchNoCase('^test([a-z0-9_]+)', name))) {
				if (IsCustomFunction(THIS[name]) OR isClosure(THIS[name])) {
					testArray.append(name);
				}
			}
		}
		//	Sort the array using the custom 'order' function attribute.
		arraySort(testArray, function (a, b){
			var firstItem = GetMetaData(THIS[a]);
			var secondItem = GetMetaData(THIS[b]);


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

		//if (testArray.len() gt 0) { WriteDump(testArray); abort; }

		for (var fx in testArray) {
			setCurrentTest(fx);
			VARIABLES.proxy = THIS[fx];

			try {
				VARIABLES.proxy();
			} catch (e) {
				//	WriteDump(e); abort;
				THIS.setError(e.message);
				if (e.detail IS NOT ""){
					THIS.setError(e.detail);
				}
				assert(false, "An unexpected error thrown in #name#");
			}
			VARIABLES.proxy = JavaCast('null', 0);
		}
		return THIS;
	}

    private void function setup () output="false" {
        /* Call any setup */
        THIS.onSetup();
        return;
    }

    private struct function tearDown () output="false" {
        /* Call any tearDowns */
        THIS.onTearDown();
        return;
    }

    private struct function createResult(required boolean result) output="false" {
        var r = structNew();
		var result = ARGUMENTS.result;

		r['isPassed'] = function () { return result; };
		r['result'] = ARGUMENTS.result? 'Passed' : 'Failed';

        if (NOT ARGUMENTS.result) {
            r['reason'] = THIS.getError();
        }

        return r;
    }

    public boolean function assert (required any assertion, required string description) output="false" {
		if (!VARIABLES.tests.keyExists(getCurrentTest())){
			VARIABLES.tests[getCurrentTest()] = [];
			VARIABLES.results[getCurrentTest()] = structNew('linked');
		}
		VARIABLES.tests[getCurrentTest()].append(description);

        THIS.beforeAssert(argumentCollection = ARGUMENTS);

		if (IsValid('boolean', ARGUMENTS.assertion)){
			if(NOT ARGUMENTS.assertion AND THIS.getError() IS '') {
				THIS.setError("Assertion returned false");
			}

			VARIABLES.results[getCurrentTest()][description] = createResult(ARGUMENTS.assertion)

		} else if (IsCustomFunction(ARGUMENTS.assertion) OR isClosure(ARGUMENTS.assertion)){

			try {
				proxy = ARGUMENTS.assertion;
				VARIABLES.results[getCurrentTest()][description] = createResult(proxy());
				proxy = JavaCast('null', 0);
	        } catch (e) {
				this.setError(e.message);
	            VARIABLES.results[getCurrentTest()][description] = createResult(false);
	        }
		}

        THIS.afterAssert(argumentCollection = VARIABLES.results[getCurrentTest()][description]);
		THIS.setError('');
        return VARIABLES.results[getCurrentTest()][description].isPassed();
    }

	public void function setCurrentTest(required string testMethod) output=false {
		VARIABLES.currentTestMethod = ARGUMENTS.testMethod;
	}

	public string function getCurrentTest() output=false {
		return VARIABLES.currentTestMethod;
	}

	/* Events for overriding */
    public void function onSetup (){ return; }
    public void function beforeAssert (){ return; }
    public void function afterAssert (){ return; }
    public void function onTearDown (){ return; }

}
