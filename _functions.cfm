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