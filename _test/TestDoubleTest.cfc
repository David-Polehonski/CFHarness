component name="testDoubleTest" extends="cfharness.core.BaseTest" {

	this.testname="TestDouble";

	public void function testStaticDoubleFactory () order=1 description="Instatiation and Configuration of Test Doubles" {
		
		var newBlankDummy = cfharness.core.DoubleFactory::generateDummy();
		assert(!isNull(newBlankDummy), 'DoubleFactory generates a new dummy without error with no base CFC');

		var newDoubleDummy = cfharness.core.DoubleFactory::generateDummy('resources.dummy');
		assert(!isNull(newDoubleDummy), 'Generic Test Double Instatiates without error with a valid component path');
		assert(isNull(newDoubleDummy.aStringMethod()), 'Methods are `no-op`-ed as dummy should have no implementation');

		newDoubleDummy.throwOnCall('aMethod', 'Do Not Execute me');

		assert(function () {
			try {
				newDoubleDummy.aMethod();
			} catch (DummyMethodExecutionError e) {
				return true;
			}
			setError('throwOnCall did not register an exception when the method `aMethod` was called');
			return false;
		}, 'Method can be Configured to throw an exception if called when they ought not to be');

		var newBlankStub = cfharness.core.DoubleFactory::generateStub();
		assert(!isNull(newBlankStub), 'DoubleFactory generates a new stub without error with no base CFC');

		var newDoubleStub = cfharness.core.DoubleFactory::generateStub('resources.dummy');
		assert(!isNull(newDoubleStub), 'Stub Double Instatiates without error with a valid component path');

		newDoubleStub.returnOnCall(method='aStringMethod', return='Test Value');
		assert(newDoubleStub.aStringMethod() == 'Test Value', 'Method can be Configured to return hard-coded values');
		
		var newDoubleStubExtended = cfharness.core.DoubleFactory::generateStub('resources.dummyExtension');
		newDoubleStubExtended.returnOnCall(method='aPackageMethod', return='Test Value');
		assert(newDoubleStubExtended.aPackageMethod() == 'Test Value', 'Package Method can be overwritten.');

		var newDoubleSpy = cfharness.core.DoubleFactory::generateSpy('resources.dummy');
		assert(!isNull(newDoubleSpy), 'Spy Test Double Instatiates without error with a valid component path');

		assert(!newDoubleSpy.wasCalled('aMethod'), 'Method invocation can be verified beforehand');
		newDoubleSpy.aMethod();
		assert(newDoubleSpy.wasCalled('aMethod'), 'Method invocation can be verified');

		assert(!newDoubleSpy.wasCalledWith('aMethod',{'a': 5, 'b': 'hi'}), 'Method invocation with arguments fails before a valid call');
		newDoubleSpy.aMethod(a=5, b='hi');
		assert(newDoubleSpy.wasCalledWith('aMethod',{'a': 5, 'b': 'hi'}), 'Method invocation with arguments can be verified');

		var newDoubleMock = cfharness.core.DoubleFactory::generateMock('resources.dummy');
		assert(!isNull(newDoubleMock), 'Mock Test Double Instatiates without error with a valid component path');

		assert(function(){
			try {
				newDoubleMock.verify('aMethod');
			} catch (MethodNotObserved e) {
				return true;
			}
		}, 'Mock object throws MethodNotObserved if verified before adding verification function');

		newDoubleMock.whenCalled(method='aMethod', verify=function(x){ return isNumeric(x) }, return='' );

		newDoubleMock.aMethod(x=9);
		assert(newDoubleMock.verify('aMethod'), 'Mock object verified the last call to `aMethod` passed the tests');
	}
}
