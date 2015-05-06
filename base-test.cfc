/*@base-test.cfc
    Copyright Ouse Creative Ltd 2015
    Author David Polehonski <david@ousecreative.co.uk>

#   Base component for creating unit tests.

*/
component name="baseTest" output="false" {

    public any function init (required string testName) output="false" {
        THIS.testName = ARGUMENTS.testName;
        THIS.tests = structNew();
        THIS.results = structNew();
        
        REQUEST.TESTS[THIS.testName] = THIS; // Store reference into request.

        VARIABLES.setup();

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
        THIS.getResults();      
        return;
    }
    
    private struct function createResult(required boolean result, string reason) output="false" {
        var r = structNew();
        
        r['result'] = ARGUMENTS.result? 'Passed' : 'Failed';
        
        if (NOT ARGUMENTS.result) {
            r['reason'] = (structKeyExists(ARGUMENTS, "reason"))? ARGUMENTS.reason : '';
        }
        
        return r;
    }

    public void function assert (required string assertionString, required function assertion) output="false" {
        THIS.beforeAssert(argumentCollection = ARGUMENTS);
        
        THIS.tests[assertionString] = ARGUMENTS.assertion;
        try {
            THIS.results[assertionString] = createResult(argumentCollection = THIS.tests[assertionString]());
        } catch (e) {
            THIS.results[assertionString] = createResult(false, e.message);
        }
        
        THIS.afterAssert(argumentCollection = THIS.results[assertionString]);
        return;
    }
    
	/* Events for overriding */
    public void function onSetup (){ return; }
    public void function beforeAssert (){ return; }
    public void function afterAssert (){ return; }
    public void function onTearDown (){ return; }
    
}