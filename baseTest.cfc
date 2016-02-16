/*@base-test.cfc
    Copyright Ouse Creative Ltd 2015
    Author David Polehonski <david@ousecreative.co.uk>

#   Base component for creating unit tests.

*/
component name="baseTest" output="false" accessors=true {

	property string error;
	property struct results;

    public any function init (required string testName=THIS.testName) output="false" {
		THIS.testName = ARGUMENTS.testName;
        THIS.tests = arrayNew(1);

        REQUEST.TESTS[THIS.testName] = THIS; // Store reference into request.

        VARIABLES.setup();

        return THIS;
    }

	public void function run() output="false" {

		application.cfharness.setCurrentTest(THIS);

		var testArray = [];

		for (var name in THIS) {

			if (arrayLen(REMatchNoCase('^test[a-z0-9_]+', name))) {
				if (IsCustomFunction(THIS[name]) OR isClosure(THIS[name])) {
					ArrayAppend(testArray, name);
				}
			}
		}

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

		for (var fx in testArray) {
			VARIABLES.proxy = THIS[fx];
			try {
				VARIABLES.proxy();
			} catch (e) {
				THIS.setError(e.message);
				assert(false, "An unexpected error thrown in #name#");
			}
			VARIABLES.proxy = JavaCast('null', 0);
		}

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

        r['result'] = ARGUMENTS.result? 'Passed' : 'Failed';

        if (NOT ARGUMENTS.result) {
            r['reason'] = THIS.getError();
        }

        return r;
    }

    public void function assert (required any assertion, required string description) output="false" {
		arrayAppend(THIS.tests, description);

        THIS.beforeAssert(argumentCollection = ARGUMENTS);

		if (IsValid('boolean', ARGUMENTS.assertion)){
			if(NOT ARGUMENTS.assertion AND THIS.getError() IS '') {
				THIS.setError("Assertion returned false");
			}

			VARIABLES.results[description] = createResult(ARGUMENTS.assertion)

		} else if (IsCustomFunction(ARGUMENTS.assertion) OR isClosure(ARGUMENTS.assertion)){

			try {
				proxy = ARGUMENTS.assertion;
				VARIABLES.results[description] = createResult(proxy());
				proxy = JavaCast('null', 0);
	        } catch (e) {
				this.setError(e.message);
	            VARIABLES.results[description] = createResult(false);
	        }
		}

        THIS.afterAssert(argumentCollection = VARIABLES.results[description]);
		THIS.setError('');
        return;
    }

	/* Events for overriding */
    public void function onSetup (){ return; }
    public void function beforeAssert (){ return; }
    public void function afterAssert (){ return; }
    public void function onTearDown (){ return; }

}
