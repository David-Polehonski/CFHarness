<cfoutput>
	<html>
		<head>
			<link href="_assets/_defaults.css" rel="stylesheet" type="text/css" media="all">
		</head>
		<body>
			<cfloop collection="#REQUEST.results#" item="testName">
			<h1>
				Results #(testName != '')? 'for ' & testName & ' test' : ''#: 
			</h1>
			<ul>
				<cfset i = 1>
				<cfloop array="#REQUEST.results[testName]#" index="result">
					<li>
						#REQUEST.TESTS[testName][i++]# : <span class="#result#">#result#</span>
					</li>
					<cfset REQUEST[result]++ >
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