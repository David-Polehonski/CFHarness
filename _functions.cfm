<!---
||	Assert: takes a string representation/ explanation of the test, then the test function is the second parameter which 
||	will record the result of the test against the string
||	--->
<cffunction name="assert" returntype="void">
	<cfargument name="assertionString" type="string" required="yes"/>
	<cfargument name="assertionResult" type="boolean" />
		
	<cfparam name="REQUEST.TESTS['#REQUEST.testName#']" default="#arrayNew(1)#" />
	<cfparam name="REQUEST.RESULTS['#REQUEST.testName#']" default="#arrayNew(1)#" />
		
	<cfset arrayAppend(REQUEST.TESTS['#REQUEST.testName#'],assertionString)>
	<cfset arrayAppend(REQUEST.RESULTS['#REQUEST.testName#'],(assertionResult)?'Passed':'Failed')>
	
	<cfreturn />
</cffunction>

<cffunction name="getResults" returntype="void" >
    <cfargument name="test" required="true" />
    
    <cfset REQUEST.RESULTS[test.testName] = arrayNew(1) />
    
    <cfloop collection="#test.tests#" item="t">
        <cfset arrayAppend(REQUEST.RESULTS[test.testName], new TestResult(t, test.results[t])) />
    </cfloop>
</cffunction>
                
<cffunction name="stream" returntype="void">
    <cfargument name="requestScope" required="true" />
    
    
    <!--- Create BINARY representation to stream --->
    <cfset binaryResponse = toBinary(toBase64(trim(requestScope.response))) />
    <!--- Add cache control headers --->
    <cfheader name="Cache-Control" value="max-age=120" />
    <cfheader name="Etag" value="#hash(binaryResponse, 'MD5')#" />
    
    <cfcontent type="#(NOT structKeyExists(REQUEST, 'responseType'))? 'text/html' : REQUEST['responseType'] #" reset="true" variable="#binaryResponse#"/>
    
</cffunction>