import vibe.d;
import vibe.core.args;
import vibe.core.file;
import vibe.stream.zlib;

import std.stdio;

void compress(InputStream input, OutputStream output) {
  auto compressor = new GzipOutputStream(output);
  compressor.write(input);
  compressor.finalize();
}

shared static this() {
  setLogLevel(LogLevel.trace);

  string inputFile = readRequiredOption!string("input", "Input File");
  string outputFile = readRequiredOption!string("output", "Output File");

  runTask({
    auto input = openFile(inputFile);
    scope(exit) input.close();

    auto output = openFile(outputFile ~ ".gz", FileMode.createTrunc);
    scope(exit) output.close();
  
    writeln("compressing input...");
    compress(input, output);
  
    writeln("done compressing input...");
  });

  writeln("done");
}
