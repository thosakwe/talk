import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'frame.dart';

class DiscoveryFrame extends Frame {
  final FrameHeader header;
  final InternetAddress address;
  final int port;

  final int hashInput0;

  final int hashInput1;

  DiscoveryFrame(int protocolMajorVersion, this.hashInput0, this.hashInput1,
      this.address, this.port)
      : header = FrameHeader.auto(protocolMajorVersion, Method.discovery);

  DiscoveryFrame.fromHeader(
      this.header, this.hashInput0, this.hashInput1, this.address, this.port);

  @override
  int get length => header.length + 2;

  @override
  void write(ByteData byteData, {int offset = 0}) {
    header.write(byteData, offset: offset);
    byteData.setUint8(header.length + offset, hashInput0);
    byteData.setUint8(header.length + offset + 1, hashInput1);
  }
}

class DiscoveryAckFrame extends Frame {
  final FrameHeader header;
  final InternetAddress address;
  final int port;

  final int hash;

  DiscoveryAckFrame(
      int protocolMajorVersion, this.hash, this.address, this.port)
      : header = FrameHeader.auto(protocolMajorVersion, Method.discoveryAck);

  DiscoveryAckFrame.fromHeader(this.header, this.hash, this.address, this.port);

  factory DiscoveryAckFrame.auto(int protocolMajorVersion, int hashInput0,
      int hashInput1, InternetAddress address, int port) {
    return DiscoveryAckFrame(
        protocolMajorVersion, hashInput0 ^ hashInput1, address, port);
  }

  @override
  int get length => header.length + 1;

  @override
  void write(ByteData byteData, {int offset = 0}) {
    header.write(byteData, offset: offset);
    byteData.setUint8(header.length + offset, hash);
  }
}

class DiscoveryFrameReader extends FrameReader<DiscoveryFrame> {
  @override
  Future<DiscoveryFrame> read(
      Datagram dg, FrameHeader header, ByteDataReader reader) async {
    await reader.readAhead(2);
    return DiscoveryFrame.fromHeader(
        header, reader.readUint8(), reader.readUint8(), dg.address, dg.port);
  }
}

class DiscoveryAckFrameReader extends FrameReader<DiscoveryAckFrame> {
  @override
  Future<DiscoveryAckFrame> read(
      Datagram dg, FrameHeader header, ByteDataReader reader) async {
    await reader.readAhead(1);
    return DiscoveryAckFrame.fromHeader(
        header, reader.readUint8(), dg.address, dg.port);
  }
}
