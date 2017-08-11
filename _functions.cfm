<cffunction name="stream" returntype="void">
	<cfargument name="requestScope" required="true" />
	<!--- Create BINARY representation to stream --->
	<cfif !IsBinary(requestScope.response)>
		<cfset binaryResponse = toBinary(toBase64(trim(requestScope.response))) />
	<cfelse>
		<cfset binaryResponse = requestScope.response/>
	</cfif>

	<!--- Add cache control headers --->
	<cfheader name="Cache-Control" value="max-age=120" />
	<cfheader name="Etag" value="#hash(binaryResponse, 'MD5')#" />
	<cfcontent type="#(NOT structKeyExists(REQUEST, 'responseType'))? 'text/html' : REQUEST['responseType'] #" reset="true" variable="#binaryResponse#"/>
</cffunction>
