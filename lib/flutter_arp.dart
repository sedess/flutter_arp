// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'flutter_arp_platform_interface.dart';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

class FlutterArp {
  Future<String?> getPlatformVersion() {
    return FlutterArpPlatform.instance.getPlatformVersion();
  }
}

typedef _GetArpTableFunc = Pointer<ArpEntry> Function(Pointer<Int32>);
typedef _GetArpTable = Pointer<ArpEntry> Function(Pointer<Int32>);

final class ArpEntry extends Struct {
  @Array(4)
  external Array<Int8> ip;

  @Array(6)
  external Array<Int8> mac;
}

class ArpLibrary {
  ArpLibrary();

  void getArpTable() {
    if (Platform.isWindows) _windowsImplementation();
    if (Platform.isMacOS) _macImplementation();
  }

  void _windowsImplementation() {
    final lib = DynamicLibrary.open('arp_library.dll');
    final getArpTableFunc = lib.lookup<NativeFunction<_GetArpTableFunc>>('getArpTable').asFunction<_GetArpTable>();

    final countPtr = calloc<Int32>();
    final entriesPtr = getArpTableFunc(countPtr);
    final count = countPtr.value;

    for (int i = 0; i < count; i++) {
      final entry = (entriesPtr + i).ref;

      // Convierte el Array<Int8> a List<int> y luego a String
      final ipList = List.generate(4, (index) => entry.ip[index]);
      final macList = List.generate(6, (index) => entry.mac[index]);

      final ip = formatIp(ipList);
      final mac = formatMac(macList);

      print('IP Address: $ip, MAC Address: $mac');
    }

    calloc.free(countPtr);
  }

  String formatIp(List<int> bytes) {
    // Filtrar solo los primeros 4 bytes para la dirección IP
    return bytes.take(4).map((b) => (b & 0xFF).toString()).join('.');
  }

  String formatMac(List<int> bytes) {
    // Filtrar solo los primeros 6 bytes para la dirección MAC
    return bytes.take(6).map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()).join('-');
  }

  void _macImplementation() async {
    // Asegúrate de que este nombre coincida con el nombre en tu AppDelegate.swift
    const platform = MethodChannel('com.example.app/arp');
    final arpData = await platform.invokeMethod('getArpTable');
    for (var entry in arpData) {
      Uint8List ipBytes = entry['ip']; // Uint8List para IP
      Uint8List macBytes = entry['mac']; // Uint8List para MAC

      // Convertir los bytes a un formato legible, si lo necesitas:
      String ipAddress = ipBytes.join('.');
      String macAddress = macBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

      print('IP Address: $ipAddress, MAC Address: $macAddress');
    }
  }
}