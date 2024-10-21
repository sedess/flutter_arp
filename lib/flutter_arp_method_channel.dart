import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_arp_platform_interface.dart';

/// An implementation of [FlutterArpPlatform] that uses method channels.
class MethodChannelFlutterArp extends FlutterArpPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_arp');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
