import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

class NearbyService {
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  Future<void> startAdvertising(String userName) async {
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {
          debugPrint('Received payload: ${payload.bytes}');
          });
        },
        onConnectionResult: (id, status) {
          debugPrint('Connection result: $status');
        },
        onDisconnected: (id) {
          debugPrint('Disconnected: $id');
        },
      );
      debugPrint('Advertising started');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> startDiscovery(String userName) async {
    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          debugPrint('Found device: $name');
          Nearby().requestConnection(userName, id, onConnectionInitiated: (id, info) {
            Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {
              debugPrint('Received payload: ${payload.bytes}');
            });
          }, onConnectionResult: (String endpointId, Status status) {  }, onDisconnected: (String endpointId) {  });
        },
        onEndpointLost: (id) {
          debugPrint('Lost endpoint: $id');
        },
      );
      debugPrint('Discovery started');
    } catch (e) {
      debugPrint('Discovery error: $e');
    }
  }
}
