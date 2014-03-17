import std.stdio;
import deimos.zmq.zmq;
import std.conv;
import std.string;
import std.array;
import std.range;
import vibe.core.core;

void printerr() {
  auto errno = zmq_errno();
  if (errno != 0) {
    auto msg = to!string(zmq_strerror(errno));
    writeln(msg);
  }
}

class Context {
  shared static void* _ctx;

  shared static this() {
    _ctx = cast(shared void*)zmq_ctx_new();
  }
}

class Loop {

}

class Message {
  zmq_msg_t _msg;

  this() {
    (&_msg).zmq_msg_init();
  }

  this(string data) {
    (&_msg).zmq_msg_init_data(cast(void*)data.ptr, data.length, null, null);
  }

  bool send(void* _socket) {
    return (&_msg).zmq_msg_send(_socket, ZMQ_DONTWAIT) != -1;
  }

  bool recv(void* _socket) {
    return (&_msg).zmq_msg_recv(_socket, ZMQ_DONTWAIT) != -1;
  }

  bool more() {
    return (&_msg).zmq_msg_more() == 1;
  }

  char[] toString() {
    auto data = cast(char*)(&_msg).zmq_msg_data();
    auto size = (&_msg).zmq_msg_size();
    return data[0..size];
  }
}

class SocketBase {
  void* _socket;

  this(int type) {
    _socket = (cast(void*)Context._ctx).zmq_socket(type);
    if (_socket == null)
      printerr();
  }

  void bind(string endpoint) {
    if (_socket.zmq_bind(endpoint.toStringz()) == -1)
      printerr();
  }

  void connect(string endpoint) {
    if (_socket.zmq_connect(endpoint.toStringz()) == -1)
      printerr();
  }

  void send(Message msg) {
    while (!msg.send(_socket))
      yield();
  }

  void send(Message[] messages) {
    foreach (Message msg; messages)
      send(msg);
  }

  Message[] recv() {
    Message[] msgs;

    do {
      auto msg = new Message();
      while (!msg.recv(_socket))
        yield();
      msgs ~= msg;
    } while (msgs[$-1].more());
    return msgs;
  }
}

class Dealer : SocketBase {
  this() {
    super(ZMQ_DEALER);
  }  
}

class Router : SocketBase {
  this() {
    super(ZMQ_ROUTER);
  }
}

shared static this() {
  auto router = new Router();
  auto dealer = new Dealer();

  auto addr = "tcp://127.0.0.1:9999";
  writeln("binding router");
  router.bind(addr);

  writeln("connecting dealer");
  dealer.connect(addr);

  foreach (x; iota(1, 11)) {
    writeln("sending message");

    auto req = new Message("test: %d".format(x));
    dealer.send(req);
  }

  foreach (x; iota(1, 11)) {
    auto msgs = router.recv();
    foreach (m; msgs)
      writeln(m);
  }
}
