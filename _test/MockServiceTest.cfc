component name="testMockService" extends="cfharness.core.BaseTest" {

	this.testname="MockService";

	public void function testMockService_registerThenClear () order=1 description="Mock Service allows registration, and removal of service handlers" {
		cfharness.core.MockService::registerServiceHandler('/testing/(.*)?', 'resources.TestServiceHandler');
		var handlerTest_1 = cfharness.core.MockService::getServiceHandler('/testing/');
		var handlerTest_2 = cfharness.core.MockService::getServiceHandler('/testing/string');
		var handlerTest_3 = cfharness.core.MockService::getServiceHandler('/testing/string/paths');

		assert(!isNull(handlerTest_1), 'Mock service located test handler for `/testing/`');
		assert(!isNull(handlerTest_2), 'Mock service located test handler for `/testing/string`');
		assert(!isNull(handlerTest_3), 'Mock service located test handler for `/testing/string/paths`');

		cfharness.core.MockService::discardServiceHandler('/testing/(.*)?');
		var handlerTest_4 = cfharness.core.MockService::getServiceHandler('/testing/');

		assert(isNull(handlerTest_4), 'Mock service returns null after discardServiceHandler is called for `/testing/`');

		cfharness.core.MockService::registerServiceHandler('/testing/(.*)?', 'resources.TestServiceHandler');
		var handlerTest_5 = cfharness.core.MockService::getServiceHandler('/testing/');

		cfharness.core.MockService::clearServiceHandlers();
		var handlerTest_6 = cfharness.core.MockService::getServiceHandler('/testing/');

		assert(!isNull(handlerTest_5) && isNull(handlerTest_6), 'Mock service returns null after clearServiceHandlers is called');
	}

	public void function testMockService_invokeServiceHandler () order=2 description="Mock Services invokes Service handlers and handles responses" {
		cfhttp(method="get" url="http://localhost:8181/_test/remote.cfm/testing/this", result="failedResponse");
		// WriteOutput(failedResponse.fileContent); abort;
		assert(failedResponse.status_code == 404, 'MockService responds 404 when no service handler exists');

		cfharness.core.MockService::registerServiceHandler('/testing/(.*)', 'resources.TestServiceHandler');
		cfharness.core.MockService::registerServiceHandler('/explode/', 'resources.TestServiceHandler');

		cfhttp(method="get" url="http://localhost:8181/_test/remote.cfm/testing/this", result="response");

		assert(isJSON(response.fileContent), 'MockService invoked TestServiceHandler to respond to http request');
		if (isJSON(response.fileContent)) {
			var data = deserializeJSON(response.fileContent);
		}
		assert(!isNull(data) && data.response == 'this', 'TestServiceHandler received parameters parsed from the URL');

		cfhttp(method="get" url="http://localhost:8181/_test/remote.cfm/explode/", result="exceptionalResponse");
		assert(!isNull(exceptionalResponse) && exceptionalResponse.status_code == 500, 'Mock service return 500 when service handler throws an exception.');
		assert(!isNull(exceptionalResponse.fileContent) && exceptionalResponse.fileContent == 'Boom!', 'Mock service returns error message in fileContent');

		cfharness.core.MockService::discardServiceHandler('/testing/(.*)');
	}

	public void function testMockService_inspectServiceCalls () order=3 description="Mock Services allows inspection of calls" {
		cfharness.core.MockService::registerServiceHandler('/testing/(.*)', 'resources.TestServiceHandler');
		cfharness.core.MockService::registerServiceHandler('/explode/', 'resources.TestServiceHandler');

		var observerId = cfharness.core.MockService::observe('/testing/(.*)');
		assert(len(observerId) == 32, 'MockService return MD5 hash key for retrieving observations');

		cfhttp(method="get" url="http://localhost:8181/_test/remote.cfm/testing/this", result="firstResponse");

		var observervations = cfharness.core.MockService::retreiveCalls(observerId);
		assert(arrayLen(observervations) == 1, 'MockService return an array of service calls for inspection');
		assert(observervations[1]['serviceUrl'] == '/testing/this', 'Service Url should be the `/testing/this`');

		assert(observervations[1]['parameters'].keyExists('name'), 'Observations contain passed parameters');
		assert(observervations[1]['responseData']['response'] == firstResponse.fileContent, 'Observations contains correct response data');

		cfharness.core.MockService::disregard(observerId);

		assert(function () {
			try {
				cfharness.core.MockService::retreiveCalls(observerId)
			} catch (InvalidObserverId e) {
				return true;
			}
			return false;
		}, 'Once disregarded `retreiveCalls` throws and InvalidObserverId exception.');
	}

	public void function onTearDown() {
		cfharness.core.MockService::clearServiceHandlers();
		cfharness.core.MockService::clearObservers();
	}
}
