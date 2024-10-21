import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_arp_method_channel.dart';

abstract class FlutterArpPlatform extends PlatformInterface {
  /// Constructs a FlutterArpPlatform.
  FlutterArpPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterArpPlatform _instance = MethodChannelFlutterArp();

  /// The default instance of [FlutterArpPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterArp].
  static FlutterArpPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterArpPlatform] when
  /// they register themselves.
  static set instance(FlutterArpPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
