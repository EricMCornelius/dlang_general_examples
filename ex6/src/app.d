import vibe.appmain;
import vibe.http.server;
import vibe.stream.ssl;

import std.stdio;

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
  writefln("handling request");
  res.writeBody(cast(ubyte[])"Hello, World!", "text/plain");
}

shared static this()
{
  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["127.0.0.1"];
  settings.sslContext = createSSLContext(SSLContextKind.server);
  settings.sslContext.peerValidationMode = SSLPeerValidationMode.trustedCert;
  settings.sslContext.useCertificateChainFile("certs/server.crt");
  settings.sslContext.usePrivateKeyFile("certs/server.key");
  settings.sslContext.useTrustedCertificateFile("certs/client.crt");
  settings.sslContext.useTrustedCertificateFile("certs/ca.crt");

  listenHTTP(settings, &handleRequest);
}
