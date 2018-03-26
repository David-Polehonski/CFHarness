component name="testBaseTest" extends="cfharness.core.BaseTest" {

	this.testname="BaseTest component";

	public void function testBaseTest () order=1 description="Base Test makes assertions available, and facilitates tests" {
		try {
			assert(true, "Assertion accepts a boolean expression as a valid assertion");
		} catch (any e) {
			WriteDump(label='Assertion Method has thrown an exception'); abort;
		}
	}

}
