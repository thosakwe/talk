import 'dart:io';
import 'transport.dart';

class Peer {
  final Transport transport;
  final InternetAddress address;
  final int port;

  Peer(this.transport, this.address, this.port);
}