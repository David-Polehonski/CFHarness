component name="testAssertion" extends="cfharness.core.BaseTest" {

	this.testname="Assertion component";

	public void function testAssertionComponent () order=1 description="instantiation and parameter validation" {
		try {
			assert(true, 'Assertion accepts boolean expression');
			assert(!false, 'Assertion accepts simple boolean negation');

			assert('Some Value', 'Assertion accepts simple values for comparison').equals('Some Value');

			assert(function() { return true; }, 'Assertion evaluates closures as boolean tests');
			//assert(function() { throw(type='ExpectedException'); }, 'Assertion accepts simple boolean negation').throws( 'ExpectedException' );

		} catch (any e) {
			WriteDump(label='Assertion Method has thrown an exception', var=e); abort;
		}
	}

}
