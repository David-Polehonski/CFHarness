
<cffunction name="getResults" returntype="void" >
    <cfargument name="test" required="true" />

	<cfif arrayLen(test.tests) GT 0 >
		<cfset var results = test.getResults() />

	    <cfset REQUEST.RESULTS[test.testName] = arrayNew(1) />


		<cfloop array="#test.tests#" item="t">
			<cfset arrayAppend(REQUEST.RESULTS[test.testName], new TestResult(t, results[t])) />
	    </cfloop>
	</cfif>

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
