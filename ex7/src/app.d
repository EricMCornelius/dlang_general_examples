import vibe.appmain;
import vibe.http.client;
import vibe.stream.ssl;

import std.stdio;

class SecureClient {
  HTTPClient client;

  this(string addr, ushort port) {
    auto initializeSSL = function(SSLContext ctx) {
      writefln("Setting up SSL Context");
      ctx.peerValidationMode = SSLPeerValidationMode.trustedCert;
      ctx.useCertificateChainFile("certs/client.crt");
      ctx.usePrivateKeyFile("certs/client.key");
      ctx.useTrustedCertificateFile("certs/ca.crt");
    };

    client = new HTTPClient();
    client.setSSLSetupCallback(initializeSSL);
    client.connect(addr, port, true);
    client.request(
      (scope req) {
        req.method = HTTPMethod.GET;
      },
      (scope res) {
//        writefln("Response: %s", res.bodyReader.readAllUTF8());
      }
    );
  }
}

shared static this()
{
  auto client = new SecureClient("127.0.0.1", 8080);
}
