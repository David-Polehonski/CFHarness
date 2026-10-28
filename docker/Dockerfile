#	Lucee 6 container for CFHarness's own suite, with this repository as the webroot.
#
#	The suite calls the mock service endpoints that CFHarness serves from this same container, over
#	HTTPS as code under test does. So Tomcat serves HTTPS on 8282 with a self-signed certificate
#	added to the JVM truststore, which is also the truststore Lucee uses.
FROM lucee/lucee:6.2.8.20

RUN keytool="$JAVA_HOME/bin/keytool" \
	&& "$keytool" -genkeypair -alias localhost -keyalg RSA -keysize 2048 -validity 3650 \
		-dname "CN=localhost" -ext "SAN=dns:localhost,ip:127.0.0.1" \
		-keystore "$CATALINA_HOME/conf/localhost.p12" -storetype PKCS12 -storepass changeit \
	&& "$keytool" -exportcert -alias localhost -keystore "$CATALINA_HOME/conf/localhost.p12" \
		-storepass changeit -file /tmp/localhost.crt \
	&& "$keytool" -importcert -noprompt -alias cfharness-localhost -file /tmp/localhost.crt \
		-cacerts -storepass changeit \
	&& rm /tmp/localhost.crt

COPY https-connector.xml /tmp/https-connector.xml
RUN awk '/^[[:space:]]*<Engine name=/ && !/jvmRoute/ { system("cat /tmp/https-connector.xml") } { print }' \
		"$CATALINA_HOME/conf/server.xml" > /tmp/server.xml \
	&& grep -q 'port="8282"' /tmp/server.xml \
	&& mv /tmp/server.xml "$CATALINA_HOME/conf/server.xml" \
	&& rm /tmp/https-connector.xml

#	The source is mounted, so Lucee must recompile templates when they change; its default only
#	checks them once.
RUN config=/opt/lucee/server/lucee-server/context/.CFConfig.json \
	&& sed -i '0,/^  "version": "5.0",/s//&\n  "inspectTemplate": "always",/' "$config" \
	&& grep -q '^  "inspectTemplate": "always"' "$config"

#	CFHarness takes the test name and the mocked service URL as path info after run.cfm and
#	remote.cfm, which Tomcat only routes to Lucee for paths mapped explicitly.
RUN sed -i 's#<url-pattern>/index.cfm/\*</url-pattern>#&\n        <url-pattern>/_test/run.cfm/*</url-pattern>\n        <url-pattern>/_test/remote.cfm/*</url-pattern>#' \
		"$CATALINA_HOME/conf/web.xml" \
	&& grep -q '/_test/remote.cfm/\*' "$CATALINA_HOME/conf/web.xml"

EXPOSE 8282
