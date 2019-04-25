import 'dart:convert';
import 'dart:io';
import 'package:talk/talk.dart';

main() async {
  var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8855);
  var transport = Transport(socket, 0);

  await for (var frame in transport) {
    if (frame is DiscoveryFrame) {
      var peer = transport.accept(frame);
      print('Accepted peer! ${peer.address.address}:${peer.port}');
    }
  }
}
