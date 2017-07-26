<!---
||	Filename:	application.cfc
||	Function:	Application file for test harness
||	Author:		David Polehonski
||	Created:	19/08/2013
||
||	CHANGELOG:
||	--->
<cfcomponent displayname="OC Test Harness" output="false">
	<cfset THIS.name = "Test Suite Application" >
	<cfset THIS.applicationTimeout = createTimeSpan(0, 0, 0, 5) >

	<cfset THIS.clientManagement = true >
	<cfset THIS.clientStorage = "cookie" >

	<!---
	||	 Name of the data source from which the query retrieves data.
	||	--->

	<cfset THIS.sessionManagement = true >
	<cfset THIS.sessionTimeout = createTimeSpan(0, 0, 30, 0) >

	<cfset THIS.setClientCookies = true >
	<cfset THIS.setDomainCookies = false >

	<cffunction name="OnApplicationStart" access="public" returntype="boolean" output="false" hint="Fires when the application is first created.">

		<cfset APPLICATION['cfharness'] = VARIABLES />
		<cfset APPLICATION['cfharnessLog'] = "TestSuite" />

     	<cfreturn true />
    </cffunction>

	<cffunction name="OnApplicationEnd" access="public" returntype="void" output="false" hint="Fires when the application is terminated.">
    	<cfargument name="ApplicationScope" type="struct" required="false" default="#StructNew()#" />
     	<cfreturn />
    </cffunction>

    <cffunction name="OnSessionStart" access="public" returntype="void" output="false" hint="Fires when the session is first created.">
    	<cfreturn />
    </cffunction>

    <cffunction name="OnSessionEnd" access="public"  returntype="void" output="false" hint="Fires when the session is terminated.">
    	<cfargument name="SessionScope" type="struct" required="true" />
   		<cfargument name="ApplicationScope" type="struct" required="false" />
     	<cfreturn />
    </cffunction>

	<cffunction name="OnRequestStart" access="public" returntype="boolean" output="true" hint="Fires at first part of page processing.">
   		<cfargument name="TargetPage" type="string" required="true"/>

		<cfset setupRequest() />

		<cfif arguments.TargetPage CONTAINS "run.cfm">
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
		<cfelse>
			<cftry>
				<cfset THIS.onMissingTemplate(ARGUMENTS.TargetPage) />
				<cfcatch>
					<cflocation url='run.cfm' addToken="false" />
					<cfabort />
				</cfcatch>
			</cftry>
		</cfif>
    	<cfreturn true />
    </cffunction>

	<!---
	||	This function should only be overwritten if needed.
	||	--->

    <cffunction name="OnRequest" access="public" returntype="void" output="true" hint="Fires after pre page processing is complete.">
    	<cfargument name="TargetPage" type="string" required="true" />

        <cfparam name="REQUEST.passed" default="0" >
        <cfparam name="REQUEST.failed" default="0" >

		<cfinclude template="_functions.cfm" />
        <cfif NOT structKeyExists(REQUEST, "response")>

            <cfscript>
				for (test in REQUEST['tests']) {
					setResults(REQUEST.TESTS[test].run());
                }
            </cfscript>


			<cfset var headers = GetHttpRequestData().headers />
			<cfif StructKeyExists(headers, "accepts") >
				<cfset REQUEST.responseType = headers["accepts"] />
				<cflog file="#APPLICATION['cfharnessLog']#" application="yes" text="Test Suite Info: Producing results #REQUEST.responseType#." />
			</cfif>

            <cfsavecontent variable="REQUEST.response">
                <cfinclude template="_results.cfm" />
            </cfsavecontent>

        </cfif>

     	<cfreturn />
    </cffunction>

	<!--- <cffunction name="onCfcRequest" access="public" returntype="void" output="true" hint="Api Requests are passed through here">
		<cfargument name="cfcName" type="string" required="true" />
		<cfargument name="methodName" type="string" required="true" />
		<cfargument name="args" type="struct" required="true" />

		<Cfdump var="HELLO" abort="true" />

	</cffunction> --->

	<cffunction name="OnRequestEnd" access="public" returntype="void" output="true" hint="Fires after the page processing is complete.">
		<cfargument name="TargetPage" type="string" required="true" />
		<cfinclude template="_functions.cfm" />

		<cflog file="#APPLICATION['cfharnessLog']#" application="yes" text="Test Suite run: Total: #REQUEST.passed + REQUEST.failed#, #REQUEST.passed# passes, #REQUEST.failed# failures." />
        <cfset stream(REQUEST) />
		<cfreturn />
    </cffunction>


	<cffunction name="onMissingTemplate" access="public" returntype="boolean" output="true" hint="I execute if the requested template does not exist.">
		<cfargument name="TargetPage" type="string" required="true" hint="I am the requested script name (but I do not exist on the physical file system)."/>
            <cfswitch expression="#listLast(TargetPage,'/')#">
                <cfcase value="css.cfm">
                    <cfsavecontent variable="REQUEST.response">
                        <cfinclude template="_assets/_defaults.css" />
                        <cfdirectory action="list" name="css" directory="/testroot" filter="*.css" >
                        <cfloop query="css">
                            <cfinclude template="/testroot/#css.name#"/>
                        </cfloop>
                    </cfsavecontent>
                    <!--- Now minify if possible! --->
                    <cfset REQUEST.response = REQUEST.response.replaceAll("(?s)/\*.+?\*/", "") />
                    <cfset REQUEST.response = REQUEST.response.replaceAll("[\r\n\t]", " ") />
                    <cfset REQUEST.response = REQUEST.response.replaceAll(" +", " ") />
                    <cfset REQUEST.responseType  = "text/css" />
                </cfcase>
				<cfcase value="icon.cfm">
					<cfset REQUEST.response = toBinary(imageRead('_assets/cf-harness-icon.png')) />
                    <cfset REQUEST.responseType  = "image/png" />
                </cfcase>
                <cfdefaultcase>
                    <cfthrow message="Invalid Test definition" detail="#ARGUMENTS.TargetPage# is an invalid test definition, file not found [#ARGUMENTS.TargetPage#.cfc]" />
                </cfdefaultcase>
            </cfswitch>
        <cfreturn true/>
	</cffunction>



	<cffunction name="OnError" access="public" returntype="void" output="true" hint="Fires when an exception occures that is not caught by a try/catch.">
   		<cfargument name="Exception" type="any" required="true" />
     	<cfargument name="EventName" type="string" required="false" default="" />
			<cfset var assertion = "Test failed ">

			<cftry>
				<cfif isDefined('Exception.message')>
					<cfset assertion &= Exception.message >
				<cfelse>
					<cfset assertion &= 'unexpectedly'>
				</cfif>

				<cfset testContext = getCurrentTest() />

				<cfif isDefined('Exception.detail') AND Exception.detail IS NOT "" >
					<cfset testContext.setError(Exception.detail)/>
				<cfelseif isDefined('Exception.tagContext') and arrayLen(Exception.tagContext) GTE 1 >
					<cfset e = Exception.tagContext[1] />
					<cfset testContext.setError("#e.template#:#e.line# <br/> #e.codePrintHTML#")/>
				</cfif>

				<cfset testContext.setCurrentTest('Application Exception') />
				<cfset testContext.assert(false, assertion) />

				<cfset THIS.onRequest('error.cfm') />
				<cfset THIS.onRequestEnd('error.cfm') />

				<cfcatch>
					<cfdump label="Initial Exception: #arguments.eventName#" var="#exception#" abort="false"/>
					<cfdump label="Error in exception handler" var="#cfcatch#" abort="true"/>
				</cfcatch>
			</cftry>
		<cfreturn />
    </cffunction>

	<cfscript>
		public void function setCurrentTest(testObject) {
			arrayAppend(REQUEST.context.previousTests, REQUEST.context.currentTest);
			REQUEST.context.currentTest = testObject;
			return;
		}

		public component function getCurrentTest() {
			return REQUEST.context.currentTest
		}

		private void function setupRequest() {
			REQUEST.tests = structNew('linked');
			REQUEST.results = structNew('linked');
			REQUEST.passed = 0;
			REQUEST.failed = 0;

			REQUEST.context = {
				"previousTests" = arrayNew(1),
				"currentTest" = new BaseTest('Application Initialization')
			};
		}

		private void function setResults(required component test) output=false {
			var results = test.getResults();

			if (test.getTests().count() GT 0) {

				REQUEST.RESULTS[test.getTestName()] = structNew('linked');

				for(var set in test.getTests()) {
					REQUEST.RESULTS[test.getTestName()][set] = [];
					for(t in test.getTests()[set]){
						REQUEST.RESULTS[test.getTestName()][set].append(new TestResult(t, results[set][t]));
					}
			    }
			}
		}
	</cfscript>

</cfcomponent>
