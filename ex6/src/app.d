import vibe.appmain;
import vibe.http.server;
import vibe.stream.ssl;
import vibe.core.file;
import vibe.core.stream;

import std.stdio;

class StdoutStream : OutputStream {
  this() { }

  void finalize() {
    flush();
  }

  void flush() {
    stdout.flush();
  }

  void write(in ubyte[] bytes) {
    stdout.rawWrite(bytes);
  }

  void write(InputStream str, ulong nbytes = 0) {
    if (nbytes != 0) {
      ubyte[] buf = new ubyte[nbytes];
      str.read(buf);
      stdout.rawWrite(buf);
    }
    else {
      while (str.dataAvailableForRead) {
        ubyte[] buf = new ubyte[str.leastSize];
        str.read(buf);
        stdout.rawWrite(buf);
      }
    }
  }
}

class StdinStream : InputStream {
  ubyte buf[16];
  ubyte[] slice;

  this() { }

  void finalize() { }

  bool empty() {
    return !stdin.isOpen || stdin.eof();
  }

  ulong leastSize() {
    if (slice.length > 0) return slice.length;
    if (empty()) return 0;

    slice = stdin.rawRead(buf);
    return slice.length;
  }

  bool dataAvailableForRead() {
    return leastSize() > 0;
  }

  const(ubyte)[] peek() {
    leastSize();
    return slice;
  }

  void read(ubyte[] dst) {
    dst[0 .. $] = slice[0 .. dst.length];
    slice = slice[dst.length .. $];
  }
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
  //auto output = openFile("output.log", FileMode.append);
  //scope(exit) output.close();
  auto output = new StdoutStream;

  output.write(req.bodyReader);
  output.finalize();

  res.writeBody(cast(ubyte[])"Hello, World!", "text/plain");
}

shared static this()
{
  auto input = new StdinStream();
  auto output = new StdoutStream();
  output.write(input);

  auto settings = new HTTPServerSettings;
  settings.options -= HTTPServerOption.parseJsonBody;
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
