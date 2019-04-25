import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:buffer/buffer.dart';

abstract class Method {
  static const int discovery = 0,
      discoveryAck = 1,
      ack = 2,
      smallData = 3,
      streamStart = 4,
      streamData = 5,
      streamFinish = 6;
}

class FrameHeader {
  // An 8-bit unsigned byte.
  final int protocolMajorVersion;

  // An 8-bit unsigned byte.
  final int method;

  // A simple checksum (just a XOR)
  final int checksum;

  const FrameHeader(this.protocolMajorVersion, this.method, this.checksum);

  FrameHeader.auto(this.protocolMajorVersion, this.method)
      : checksum = protocolMajorVersion ^ method;

  int get length => 3;

  bool get isValid => checksum == (protocolMajorVersion ^ method);

  void write(ByteData byteData, {int offset = 0}) {
    byteData.setUint8(offset, protocolMajorVersion);
    byteData.setUint8(offset + 1, method);
    byteData.setUint8(offset + 2, checksum);
  }
}

abstract class Frame {
  FrameHeader get header;

  int get length;

  void write(ByteData byteData, {int offset = 0});
}

abstract class FrameReader<T extends Frame> {
  FutureOr<T> read(Datagram dg, FrameHeader header, ByteDataReader reader);
}
