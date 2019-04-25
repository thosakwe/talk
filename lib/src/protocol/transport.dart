import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:buffer/buffer.dart';
import 'client.dart';
import 'discovery.dart';
import 'frame.dart';

class Transport extends Stream<Frame>
    implements StreamConsumer<RawSocketEvent> {
  final RawDatagramSocket socket;
  final int protocolMajorVersion;
  final _readers = <int, FrameReader>{};
  final StreamController<Frame> _stream = StreamController();
  var _discoveryListeners = <_DiscoveryListener>[];

  static final Random _rnd = Random.secure();

  Transport(this.socket, this.protocolMajorVersion) {
    _readers[Method.discovery] = DiscoveryFrameReader();
    _readers[Method.discoveryAck] = DiscoveryAckFrameReader();
    socket.pipe(this);
  }

  @override
  StreamSubscription<Frame> listen(void Function(Frame event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _stream.stream.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  @override
  Future<void> addStream(Stream<RawSocketEvent> stream) async {
    await for (var _ in stream) {
      var dg = socket.receive();
      if (dg != null) {
        // Try to parse the frame.
        //
        // Read the header first, and then pass it off to a
        // specialized reader.
        var reader = ByteDataReader()..add(dg.data);
        await reader.readAhead(3);
        var header = FrameHeader(
            reader.readUint8(), reader.readUint8(), reader.readUint8());

        if (!header.isValid) {
          print('Invalid header');
        } else if (!_readers.containsKey(header.method)) {
          print('Invalid method ${header.method}');
        } else {
          var subReader = _readers[header.method];
          var frame = await subReader.read(dg, header, reader);
          _stream.add(frame);

          if (frame is DiscoveryAckFrame) {
            // Complete any discovery listeners.
            for (var listener in _discoveryListeners) {
              if (!listener.ctrl.isClosed && listener.hash == frame.hash) {
                listener.ctrl.add(Peer(this, dg.address, dg.port));
              }
            }
          }
        }
      }
    }
  }

  @override
  Future<void> close() async {
    await _stream.close();
    for (var listener in _discoveryListeners) await listener.ctrl.close();
  }

  void send(Frame frame, InternetAddress address, int port) {
    var byteData = ByteData(frame.length);
    frame.write(byteData);
    socket.send(Uint8List.view(byteData.buffer), address, port);
  }

  Stream<Peer> discover(InternetAddress address, int port) {
    var a = _rnd.nextInt(256), b = _rnd.nextInt(256), hash = a ^ b;
    var frame =
        DiscoveryFrame(protocolMajorVersion, a, b, socket.address, socket.port);
    var listener = _DiscoveryListener(a, b, hash);
    _discoveryListeners.add(listener);
    send(frame, address, port);
    return listener.ctrl.stream;
  }

  Peer accept(DiscoveryFrame incoming) {
    var frame = DiscoveryAckFrame.auto(
        protocolMajorVersion,
        incoming.hashInput0,
        incoming.hashInput1,
        incoming.address,
        incoming.port);
    send(frame, incoming.address, incoming.port);
    return Peer(this, incoming.address, incoming.port);
  }
}

class _DiscoveryListener {
  final StreamController<Peer> ctrl = StreamController();
  final int hashInput0, hashInput1, hash;

  _DiscoveryListener(this.hashInput0, this.hashInput1, this.hash);
}
