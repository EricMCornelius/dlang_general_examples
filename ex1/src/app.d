import vibe.d;
import vibe.http.server;

void index(HTTPServerRequest req, HTTPServerResponse res)
{
  render!("index.dt")(res);
}

void page(HTTPServerRequest req, HTTPServerResponse res)
{
  string page = req.params["page"];
  std.stdio.writeln(page);
  render!("page.dt", page)(res);
}

shared static this()
{
  setLogLevel(LogLevel.trace);

  auto router = new URLRouter;
  router.get("/", &index);
  router.get("/:page", &page);

  auto settings = new HTTPServerSettings;
  settings.port = 9090;
 
  listenHTTP(settings, router);
}
