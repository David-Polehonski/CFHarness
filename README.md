# CFHarness

CFHarness is a unit test framework for CFML on Lucee 6. It runs test components, builds test doubles, and serves mock HTTP services, so code that calls an external API can be tested without it.

## Run a suite

Open `run.cfm` in your tests folder in a browser for an HTML report, or run the suite from a shell:

```sh
cfharness/run-suite.sh https://localhost:8282/tests/run.cfm
cfharness/run-suite.sh https://localhost:8282/tests/run.cfm BasketTest
```

`run-suite.sh` prints each failed assertion and a summary line. It exits 0 when every assertion passes, 1 when any fails, and 2 when the suite could not run or ran no assertions. It needs bash and curl.

To run CFHarness's own suite in a Lucee 6 container, which needs Docker:

```sh
./run-tests.sh                  # all tests, on https://localhost:8181
./run-tests.sh MockServiceTest  # one test component
./run-tests.sh --down           # stop the container afterwards
```

Set `CFHARNESS_PORT` to use another port. The container mounts this folder and recompiles templates when they change, so reruns pick up edits.

## Set up a project

Add CFHarness to your tests folder, for example as a git submodule at `tests/cfharness`. Then create `tests/Application.cfc`, extending CFHarness's application:

```cfc
component extends='cfharness.core' {
	this.mappings['/sut'] = getDirectoryFromPath(getCurrentTemplatePath()) & '../';

	function onTestApplicationStart() {
		//	Runs once when the test application starts.
	}
}
```

`run.cfm` and `remote.cfm` do not exist as files; the application answers requests for them. The test name and the mocked service path follow them as path info, as in `run.cfm/BasketTest`, so the server must route `tests/run.cfm/*` and `tests/remote.cfm/*` to Lucee. On Lucee's Tomcat, that means adding both patterns to the CFML servlet mapping in `web.xml`.

If the code under test calls the mock services over HTTPS, the server's JVM must trust the server's own certificate. `docker/Dockerfile` shows both settings.

## Write tests

A test component is a file in the tests folder whose name ends in `Test.cfc` and which extends `cfharness.core.BaseTest`. Each function whose name starts with `test` runs, in the order its `order` attribute gives.

```cfc
component extends='cfharness.core.BaseTest' {
	this.testname = 'Basket';

	public void function onSetup() {
		variables.basket = new sut.Basket();
	}

	public void function testTotal() order=1 description='Totals the item prices' {
		basket.add(price=10);
		basket.add(price=5);

		assert(basket.total() == 15, 'The total is the sum of the prices').because('the total was #basket.total()#');
		assert(basket.currency(), 'Prices are in pounds').equals('GBP');
	}

	public void function onTearDown() {
		basket.empty();
	}
}
```

`assert(expression, description)` takes a boolean, or a closure that returns one. To test a simple value instead, pass the value and chain a check onto it: `equals(value)`, `isGreaterThan(value)` or `matches(regex)`. Add `because(reason)` to say why a failed assertion failed; the report shows it in place of the generic reason.

An error thrown by a test function, by setup or teardown, or while loading a test component is reported as a failed assertion naming the error and the line that threw it. The rest of the suite still runs. Do not `abort` in a test, because that ends the run without results.

## Test doubles

`cfharness.core.DoubleFactory` builds doubles of a component:

```cfc
var prices = cfharness.core.DoubleFactory::generateStub('sut.PriceService');
prices.returnOnCall('priceFor', function (sku) { return 10; });
```

- `generateDummy(path)` replaces every method with one that does nothing. `throwOnCall(method, message)` makes a method throw if it is called.
- `generateStub(path)` returns fixed values, or the result of a closure, from `returnOnCall(method, return)`.
- `generateSpy(path)` records calls, for `wasCalled(method)` and `wasCalledWith(method, arguments)`.
- `generateMock(path)` takes expectations with `whenCalled(method, verify, return)` and checks them with `verify(method)`.

## Mock services

Register a handler component, by its path in the tests folder, for a regular expression matching service paths:

```cfc
cfharness.core.MockService::registerServiceHandler('/services/data/(.*)', 'resources.AccountHandler');
```

Point the code under test at `https://localhost:<port>/tests/remote.cfm`. A request to `remote.cfm/services/data/account/42` then goes to the handler function whose `method` and `route` match:

```cfc
component {
	remote struct function getAccount(required struct headers, required string id) method='GET' route='/services/data/account/{@id}' {
		return {
			'contentBody': serializeJSON({ 'Id': arguments.id }),
			'contentType': 'application/json',
			'status': 200
		};
	}
}
```

Route variables such as `{@id}` become arguments, along with the request headers, the body for PUT, POST and PATCH, and any form and URL fields. A handler can return status 200, 204, 400, 401, 404 or 500. A handler that throws produces a 500 with the error message, and a path with no handler produces a 404.

To check the calls the code under test made, observe a path before the calls and retrieve them afterwards:

```cfc
var observerId = cfharness.core.MockService::observe('/services/data/(.*)');
// ...exercise the code under test...
var calls = cfharness.core.MockService::retreiveCalls(observerId);
```

Each call records the service path, method, URL, query string, headers, body, parameters and response. Call `clearServiceHandlers()` and `clearObservers()` in `onTearDown()` so tests do not affect each other.

## Troubleshooting

CFHarness logs to the `TestSuite` log in Lucee's logs folder, including each handler it registers or fails to register and each mock service call it routes.
