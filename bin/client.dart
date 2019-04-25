import 'dart:io';
import 'package:talk/talk.dart';

main() async {
  var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
    ..broadcastEnabled = true;
  var transport = Transport(socket, 0);
  var available = transport.discover(InternetAddress('255.255.255.255'), 8855);

  await for (var peer in available) {
    print('Found peer via broadcast: ${peer.address.address}:${peer.port}');
  }
}
