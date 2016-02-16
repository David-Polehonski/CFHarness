<cfoutput>
	<html>
		<head>
			<link href="css.cfm" rel="stylesheet" type="text/css" media="all">
			<link rel="icon"
			      type="image/png"
			      href="icon.cfm" />
		</head>
		<body>
            <cfloop collection="#REQUEST.results#" item="testName">

            <h1>
				Results #(testName != '')? 'for ' & testName & ' test' : ''#:
			</h1>
			<ul>

				<cfloop array="#REQUEST.results[testName]#" item="i">
                    <li>
                        #i.getTest()# :
                        <span class="#i.getResult()#">
                            #i.getResult()# <cfif i.getResult() IS "Failed"> : #i.getReason()#</cfif>
                        </span>
                    </li>
				</cfloop>
			</ul>
			</cfloop>
			<footer>
				<h6>Test suite complete</h6>
				<p><em>Total: #REQUEST.passed + REQUEST.failed#</em>, <span class="passed">#REQUEST.passed# passes</span>, <span class="failed">#REQUEST.failed# failures</span>.</p>
			</footer>
		</body>
	</html>
</cfoutput>
