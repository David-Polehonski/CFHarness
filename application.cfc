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
	<cfset THIS.clientStorage = "registry" >	
	
	<!---
	||	 Name of the data source from which the query retrieves data. 
	||	--->
	<cfset THIS.datasource = "" >
	
	<cfset THIS.mappings = {
		"/root"=(expandPath("/") & "/orders"), 
		"/models"=(expandPath("/") & "/orders/_models"),
		"/testroot"=(expandPath("/") & "/orders/_tests")} >
	
	<cfset THIS.sessionManagement = true >
	<cfset THIS.sessionTimeout = createTimeSpan(0, 0, 30, 0) >
	
	<cfset THIS.setClientCookies = true >
	<cfset THIS.setDomainCookies = false >
	
	<cfset THIS.ormenabled = true >
	<cfset THIS.ormsettings = {cfclocation = ["/orders/_models"]} >
	  	
	<cffunction name="OnApplicationStart" access="public" returntype="boolean" output="false" hint="Fires when the application is first created.">
		<cfset ORMReload() >
     	<cfreturn true />
    </cffunction>
    
	<cffunction name="OnApplicationEnd" access="public" returntype="void" output="false" hint="Fires when the application is terminated.">
    	<cfargument name="ApplicationScope" type="struct" required="false" default="#StructNew()#" />
		
		<cflog text="Application Ended" application="yes" />
		
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
		
		<cfparam name="REQUEST.RESULTS" default="#structNew()#" />
		<cfparam name="REQUEST.TESTS" default="#structNew()#" />
		<cfparam name="REQUEST.testName" default="" />
		
		<cfinclude template="_functions.cfm" />
		
		<cfif TargetPage CONTAINS "index.cfm">
			<!---
			||	RUN ALL TESTS
			||	--->
			<cfdirectory action="list" name="tests" directory="/testroot">
			<cfset var pattern = "^test_([\w\._-]*).cfm">
			<cfloop query="tests">
				<cfif (REFindNoCase(pattern,tests.name) IS NOT 0) AND (fileExists(expandPath('/testroot') & '/' & tests.name)) >
					<cfinclude template="/testroot/#tests.name#"/>
				</cfif>	
			</cfloop>
			
		<cfelse>	
			<cfset var test = listLast(TargetPage,'/')>
			
			<cfif fileExists(expandPath('/testroot') & '/' & test)>
				<cfinclude template="/testroot/#test#" />
			<cfelse>
				<cfset assert("Test Definition '#test#' Exists",false)>
			</cfif>
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
				
		<cfsavecontent variable="REQUEST.response">				
			<cfinclude template="_results.cfm" />
		</cfsavecontent>
		
     	<cfreturn />
    </cffunction>
    
	
	<cffunction name="OnRequestEnd" access="public" returntype="void" output="true" hint="Fires after the page processing is complete.">
		<cfargument name="TargetPage" type="string" required="true" />
				
		<cflog file="TestSuite" application="yes" text="Test Suite run: Total: #REQUEST.passed + REQUEST.failed#, #REQUEST.passed# passes, #REQUEST.failed# failures." />
		<cfcontent type="text/html" reset="yes"><cfoutput>#REQUEST.RESPONSE#</cfoutput>
     	<cfreturn />
    </cffunction>
     
	<!---
	||	These are special 'Aspect' Orientated functions and should only be implemented if neccesary.
	||	---> 
	
   	<!---
	<cffunction name="onMissingTemplate" access="public" returntype="boolean" output="true" hint="I execute if the requested template does not exist.">
		<cfargument name="script" type="string" required="true" hint="I am the requested script name (but I do not exist on the physical file system)."/>	
		<cfreturn true/>
	</cffunction>
	--->
	
	
	<cffunction name="OnError" access="public" returntype="void" output="true" hint="Fires when an exception occures that is not caught by a try/catch.">
   		<cfargument name="Exception" type="any" required="true" />
     	<cfargument name="EventName" type="string" required="false" default="" />
			<cfset var assertion = "Test failed ">
			
			<cfif isDefined('Exception.message')>
				<cfset assertion &= "'" & Exception.message & "'">
				<cfif isDefined('Exception.tagContext')>
					<cfset assertion &= "<br/>" & Exception.tagContext[1].codePrintHTML & "">
				</cfif>
			<cfelse>
				<cfset assertion &= 'unexpectedly'>
			</cfif>
			
			<cfset assertion &= "test status">
			
			 
			<cfset assert(assertion,false)>
			<cfinclude template="_results.cfm" />
			
		<cfreturn />
    </cffunction>
	
</cfcomponent>
