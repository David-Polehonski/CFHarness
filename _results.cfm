<cfoutput>
	<html>
		<head>
			<link href="css.cfm" rel="stylesheet" type="text/css" media="all">
			<link rel="icon"
						type="image/png"
						href="icon.cfm" />
		</head>
		<body>
			<section class="test-results__container">
				<cfloop collection="#REQUEST.results#" item="testName">
					<h1>
						Results #(testName != '')? 'for ' & testName & ' test' : ''#:
					</h1>
					<ul>
						<cfloop collection="#REQUEST.results[testName]#" index="setName" item="testSet">
							<li>
								<cfif structKeyExists(REQUEST.tests[testName], setName) >
									<cfset d = GetMetaData(REQUEST.tests[testName][setName]) />
									<cfif StructKeyExists(d, "description") >
										#d.description#
									<cfelse>
										#setName#
									</cfif>
								<cfelse>
									#setName#
								</cfif>
								<ul>
									<cfloop array="#testSet#" item="i">
										<li>
											#i.getTest()# :
											<span class="#i.getResult()#">
												#i.getResult()#
												<cfif i.getResult() IS "Failed">
													<cfif isJson(i.getReason())>
														#WriteDump(var=deserializeJson(i.getReason()), label='Reason')#
													<cfelseif isValid('string', i.getReason()) >
														: #i.getReason()#
													</cfif>
												</cfif>
											</span>
										</li>
									</cfloop>
								</ul>
							</li>
						</cfloop>
					</ul>
				</cfloop>
			</section>
			<footer>
				<h6>Test suite complete</h6>
				<p><em>Total: #REQUEST.passed + REQUEST.failed#</em>, <span class="passed">#REQUEST.passed# passes</span>, <span class="failed">#REQUEST.failed# failures</span>.</p>
			</footer>
		</body>
	</html>
</cfoutput>
