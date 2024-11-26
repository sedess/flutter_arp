// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'package:flutter/foundation.dart';
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

typedef _GetArpTableFunc = Pointer<_ArpEntry> Function(Pointer<Int32>);
typedef _GetArpTable = Pointer<_ArpEntry> Function(Pointer<Int32>);

final class _ArpEntry extends Struct {
  @Array(4)
  external Array<Int8> ip;

  @Array(6)
  external Array<Int8> mac;
}

abstract class ArpLibrary {

  static Future<ArpTable> getArpTable() async {
    if (Platform.isWindows) return _windowsImplementation();
    if (Platform.isMacOS) return await _macImplementation();
    throw UnimplementedError();
  }

  static ArpTable _windowsImplementation() {
    final lib = DynamicLibrary.open('arp_library.dll');
    final getArpTableFunc = lib.lookup<NativeFunction<_GetArpTableFunc>>('getArpTable').asFunction<_GetArpTable>();

    final countPtr = calloc<Int32>();
    final entriesPtr = getArpTableFunc(countPtr);
    final count = countPtr.value;

    final arpTable = ArpTable();

    for (int i = 0; i < count; i++) {
      try {

        final entry = (entriesPtr + i).ref;

        // Convierte el Array<Int8> a List<int> y luego a String
        final ipList = List.generate(4, (index) => entry.ip[index]);
        final macList = List.generate(6, (index) => entry.mac[index]);

        final ip = _formatIp(ipList);
        final mac = _formatMac(macList);
        // print('IP Address: $ip, MAC Address: $mac');

        arpTable._addEntry(ip, mac);
      } catch (e, stack) {
        debugPrint('Failed to parse arp entry due to: $e');
        debugPrint('Stack trace: $stack');
      }

    }

    calloc.free(countPtr);

    return arpTable;
  }

  static String _formatIp(List<int> bytes) {
    // Filtrar solo los primeros 4 bytes para la dirección IP
    return bytes.take(4).map((b) => (b & 0xFF).toString()).join('.');
  }

  static String _formatMac(List<int> bytes) {
    // Filtrar solo los primeros 6 bytes para la dirección MAC
    return bytes.take(6).map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }

  static Future<ArpTable> _macImplementation() async {
    // Asegúrate de que este nombre coincida con el nombre en tu AppDelegate.swift
    const platform = MethodChannel('flutter_arp');
    final arpData = await platform.invokeMethod('getArpTable');
    
    final arpTable = ArpTable();
    
    for (var entry in arpData) {
      try {
        final rawIp = entry['ip'];
        final rawMac = entry['mac'];

        if (rawIp is! List || rawIp.isEmpty) continue;
        if (rawMac is! List || rawMac.isEmpty) continue;

        List<int> ipBytes = List.generate(4, (index) => rawIp[index]);
        List<int> macBytes = List.generate(6, (index) => rawMac[index]);
        // Uint8List ipBytes = entry['ip']; // Uint8List para IP
        // Uint8List macBytes = entry['mac']; // Uint8List para MAC

        // Convertir los bytes a un formato legible, si lo necesitas:
        // String ipAddress = ipBytes.join('.');
        // String macAddress = macBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        String ipAddress = _formatIp(ipBytes);
        String macAddress = _formatMac(macBytes);

        // print('IP Address: $ipAddress, MAC Address: $macAddress');

        arpTable._addEntry(ipAddress, macAddress);

      } catch (e, stack) {
        debugPrint('Failed to parse arp entry due to: $e');
        debugPrint('Stack trace: $stack');
      }
    }

    return arpTable;
  }
}

class ArpTable {
  final Map<String, ArpTableEntry> byMacMap = {};
  final Map<String, ArpTableEntry> byIpMap = {};
  final List<ArpTableEntry> entriesList = [];

  void _addEntry(String ipAddress, String macAddress) {
    final entry = ArpTableEntry(ipAddress, macAddress);
    byIpMap[ipAddress] = entry;
    byMacMap[macAddress] = entry;
    entriesList.add(entry);
  }

}

class ArpTableEntry {
  final String ipAddress;
  final String macAddress;

  ArpTableEntry(this.ipAddress, this.macAddress);
}

