<!---
||	Filename:	application.cfc
||	Function:	Application file for test harness
||	Author:		David Polehonski
||	Created:	19/08/2013
||
||	CHANGELOG:
||	--->
<cfcomponent displayname="CF Harness Test Suite" output="true">
	<cfscript>
		this.name = "CF Harness Test Suite";
		this.applicationTimeout = createTimeSpan(0, 0, 15, 0);

		this.clientManagement = true;
		this.clientStorage = "cookie";

		this.sessionManagement = true;
		this.sessionTimeout = createTimeSpan(0, 0, 30, 0);

		this.setClientCookies = true;
		this.setDomainCookies = false;

		this.mappings['/cfharness'] = getDirectoryFromPath( getCurrentTemplatePath() ) ;
		this.mappings['/testroot'] = expandPath('./');

		include "settings.cfm";

		//	Test hook for application start
		public void function onTestApplicationStart () output='false' { }
		public boolean function onApplicationStart () output='false' {
			try {

				application['cfharnessLog'] = "TestSuite";
				application['cfharness'] = {};
				application['cfharness']['requestCount'] = 1; // How many requests in a particular application life cycle.

				cfharness.core.Log::log('Starting CFHarness Application');
				new core.system();

				onTestApplicationStart();
			} catch (any E) {
				cfharness.core.Log::fatal('Could not start CFHarness Application');
				abort;
			}
			return true;
		}

		public void function onTestApplicationEnd () output='false' { }
		public boolean function OnApplicationEnd (required struct ApplicationScope = structNew()) output='false' {
			try {
				onTestApplicationEnd( ApplicationScope );
			} catch (any e) {
				cfharness.core.Log::fatal('Could not tidy up CFHarness Application');
			}
			return true;
		}

		public void function OnSessionStart () output='false' { }
		public void function OnSessionEnd (required struct SessionScope, required struct ApplicationScope = structNew()) output='false' { }
	</cfscript>

	<cffunction name="OnRequestStart" access="public" returntype="boolean" output="true" hint="Fires at first part of page processing.">
		<cfargument name="TargetPage" type="string" required="true"/>

		<cfif !application.keyExists('cfharness') >
			<cfabort />
		</cfif>

		<cfif url.keyExists('reboot') >
			<cfset application['cfharness']['system'].reset() />
		</cfif>

		<cftry>
			<cfset application['cfharness']['requestCount'] += 1 />
			<cfset variables.rc = application['cfharness']['system'].getRequest() />
			<cfcatch>
				<cfset throw(message='Error setting up request', detail=cfcatch.message) />
			</cfcatch>
		</cftry>

		<cfif arguments.TargetPage CONTAINS "run.cfm">
			<cfset variables.rc.setEndpoint( 'testRunner' ) />
			<cfset var testPath = ListQualify(CGI.path_info, '' , '/') />
			<cfif testPath IS NOT "">
				<cfif FileExists(Expandpath('/testroot/#testPath#.cfc')) >
					<cfset test = createObject('component', 'testroot.#testPath#').init() />
				<cfelse>
					<cfset THIS.onMissingTemplate(ListLast(testPath, '/')) />
				</cfif>
			<cfelse>
				<!---
				||	RUN ALL TESTS
				||	--->
				<cfdirectory action="list" name="tests" directory="/testroot">
				<cfset var pattern = "^([\w\._-]+)test.cfc" />
				<cfloop query="tests">
					<cfif (REFindNoCase(pattern,tests.name) IS NOT 0) AND (fileExists(expandPath('/testroot') & '/' & tests.name)) >
						<cfset test = createObject('component', 'testroot.' & replace(tests.name, '.cfc', '')).init() />
					</cfif>
				</cfloop>
			</cfif>
		<cfelseif arguments.TargetPage CONTAINS "remote.cfm">
			<cfset variables.rc.setEndpoint( 'MockService' ) />
			<cfreturn true />
		<cfelse>
			<cftry>
				<cfset THIS.onMissingTemplate(ARGUMENTS.TargetPage) />
				<cfcatch>
					<cflocation url='run.cfm' addToken="false" />
				</cfcatch>
			</cftry>
		</cfif>

		<cfreturn true />
	</cffunction>

	<cffunction name="OnRequest" access="public" returntype="void" output="true" hint="Fires after pre page processing is complete.">
		<cfargument name="TargetPage" type="string" required="true" />

		<cflog file="#application['cfharnessLog']#" application="yes" text="Starting 'OnRequest'" />
		<cfif variables.rc.getEndpoint() is "MockService" >
			<!---Its a proxy test, attempt resolve the call --->
			<cfset cfharness.core.Log::log("MockService API endpoint") />
			<cfset mockService = new cfharness.core.MockService() />
			<cfset var response = mockService.request( cgi.path_info ) />
			<cfset response.stream() />
			<cfreturn />
		</cfif>

		<cfif NOT structKeyExists(REQUEST, "response")>
			<cflog file="#APPLICATION['cfharnessLog']#" application="yes" text="Run all Tests." />

			<cfscript>
				variables.rc.run();
				variables.rc.finalize();
			</cfscript>

			<cflog file="#APPLICATION['cfharnessLog']#" application="yes" text="Test Suite run: Total: #REQUEST.passed + REQUEST.failed#, #REQUEST.passed# passes, #REQUEST.failed# failures." />

			<cfset var headers = GetHttpRequestData().headers />

			<cfif StructKeyExists(headers, "accept") >
				<cfset variables.rc.setResponseType(listFirst(headers["accept"], ',')) />
				<cflog file="#APPLICATION['cfharnessLog']#" application="yes" text="Test Suite Info: Producing results #variables.rc.getResponseType()#." />
			</cfif>

			<cflog file="#APPLICATION['cfharnessLog']#" application="yes" text="Building Results" />

			<cfsavecontent variable="response">
				<cfinclude template="_results.cfm" />
			</cfsavecontent>
			<cfset variables.rc.setResponse( response ) />
		</cfif>

		<cfreturn />
	</cffunction>

	<cffunction name="OnRequestEnd" access="public" returntype="void" output="true" hint="Fires after the page processing is complete.">
		<cfargument name="TargetPage" type="string" required="true" />
		<cfset cfharness.core.Log::log("Streaming Request Response. #request.keyExists('response')#") />
		<cfset response = variables.rc.getResponse() />
		<cfset response.stream() />
		<cfreturn />
	</cffunction>

	<cffunction name="onMissingTemplate" access="public" returntype="boolean" output="true" hint="I execute if the requested template does not exist.">
		<cfargument name="TargetPage" type="string" required="true" hint="I am the requested script name (but I do not exist on the physical file system)."/>
		<cfswitch expression="#listLast(TargetPage,'/')#">
			<cfcase value="css.cfm">
					<cfsavecontent variable="cssResponse">
						<cfinclude template="_assets/normalize.css" />
						<cfinclude template="_assets/_defaults.css" />
					</cfsavecontent>
					<!--- Now minify if possible! --->
					<cfset cssResponse = cssResponse.replaceAll("(?s)/\*.+?\*/", "") />
					<cfset cssResponse = cssResponse.replaceAll("[\r\n\t]", " ") />
					<cfset cssResponse = cssResponse.replaceAll(" +", " ") />
					<cfset variables.rc.setResponseType("text/css") />
					<cfset variables.rc.setResponse(cssResponse) />
			</cfcase>
			<cfcase value="icon.cfm">
				<cfset variables.rc.setResponseType("image/png") />
				<cfset variables.rc.setResponse(toBinary(imageRead('/cfharness/_assets/cf-harness-icon.png'))) />
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Invalid Test definition" detail="#ARGUMENTS.TargetPage# is an invalid test definition, file not found [#ARGUMENTS.TargetPage#.cfc]" />
			</cfdefaultcase>
		</cfswitch>
		<cfreturn true />
	</cffunction>

	<cffunction  name="onAbort" access="public" returntype="void" output="true" >
		<cfargument name="targetPage" type="any" required="true" />

		<cfif !application.keyExists('cfharness') ><cfreturn /></cfif>

		<cfif !isNull(variables.rc.getCurrentTest()) >
			<cfset variables.rc.getCurrentTest().tearDown() />
			<cfset variables.rc.finalize() />
		</cfif>
	</cffunction>

	<cffunction name="OnError" access="public" returntype="void" output="true" hint="Fires when an exception occures that is not caught by a try/catch.">
		<cfargument name="Exception" type="any" required="true" />
		<cfargument name="EventName" type="string" required="false" default="" />

		<cfif !application.keyExists('cfharness') >
			<cfdump var="#Exception#"/>
			<cfabort />
		</cfif>
		<cflog file="#application['cfharnessLog']#" application="yes" text="Error: #Exception.message#" />

		<cfset var assertion = "Test failed ">
		<cftry>
			<cfif isDefined('Exception.message')>
				<cfset assertion &= Exception.message >
			<cfelse>
				<cfset assertion &= 'unexpectedly'>
			</cfif>

			<cfset testContext = variables.rc.getCurrentTest() />

			<cfif isDefined('Exception.detail') AND Exception.detail IS NOT "" >
				<cfset testContext.setError(Exception.detail)/>
			<cfelseif isDefined('Exception.tagContext') and arrayLen(Exception.tagContext) GTE 1 >
				<cfset e = Exception.tagContext[1] />
				<cfset testContext.setError("#e.template#:#e.line# <br/> #e.codePrintHTML#")/>
			</cfif>

			<cfset testContext.setCurrentTest( 'Application Exception' ) />
			<cfset testContext.assert(false, assertion) />

			<!--- <cfset variables.rc.finalize() /> --->

			<cfset THIS.onRequest('error.cfm') />
			<cfset THIS.onRequestEnd('error.cfm') />

			<cfcatch>
				<cfdump label="Initial Exception: #arguments.eventName#" var="#exception#" abort="false" format='classic'/>
				<cfdump label="Error in exception handler" var="#cfcatch#" abort="false" format='classic'/>
			</cfcatch>
		</cftry>
		<cfreturn />
	</cffunction>

</cfcomponent>
