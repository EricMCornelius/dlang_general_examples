import std.stdio;
import deimos.zmq.zmq;
import std.conv;
import std.string;
import std.array;
import std.range;

void printerr() {
  auto errno = zmq_errno();
  if (errno != 0) {
    auto msg = to!string(zmq_strerror(errno));
    writeln(msg);
  }
}

void printMsg(void* socket) {
  zmq_msg_t repVal;
  auto rep = &repVal;

  do {
    rep.zmq_msg_init();
    if (rep.zmq_msg_recv(socket, 0) == -1)
      printerr();
    else {
      auto data = cast(char*)rep.zmq_msg_data();
      auto size = rep.zmq_msg_size();
      char[] tmp = data[0..size];
      writeln(tmp);
    }
  } while(rep.zmq_msg_more() != 0);
}

int main(string[] args) {
  auto ctx = zmq_ctx_new();
  auto router = ctx.zmq_socket(ZMQ_ROUTER);
  if (router == null)
    printerr();
  auto dealer = ctx.zmq_socket(ZMQ_DEALER);
  if (dealer == null)
    printerr();

  zmq_msg_t reqVal;
  auto req = &reqVal;
  auto str = "test";
  req.zmq_msg_init_data(cast(void*)str.ptr, str.length, null, null);
  printerr();

  auto addr = "tcp://127.0.0.1:9999".toStringz();
  writeln("binding router");
  if (router.zmq_bind(addr) == -1)
    printerr();

  writeln("connecting dealer");
  if (dealer.zmq_connect(addr) == -1)
    printerr();

  writeln("sending message");
  if (req.zmq_msg_send(dealer, ZMQ_DONTWAIT) == -1)
    printerr();

  writeln("receiving message");
  zmq_pollitem_t[] poll_items = [{ router, 0, ZMQ_POLLIN, 0 }];
  auto count = zmq_poll(poll_items.ptr, to!int(poll_items.length), 1000);

  for (auto idx = 0; idx < count; ++idx) {
    auto item = poll_items[idx];
    if (item.revents & ZMQ_POLLIN)
      printMsg(item.socket);
  }

  return 0;
}
