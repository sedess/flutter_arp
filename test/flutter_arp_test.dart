import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_arp/flutter_arp.dart';
import 'package:flutter_arp/flutter_arp_platform_interface.dart';
import 'package:flutter_arp/flutter_arp_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterArpPlatform
    with MockPlatformInterfaceMixin
    implements FlutterArpPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterArpPlatform initialPlatform = FlutterArpPlatform.instance;

  test('$MethodChannelFlutterArp is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterArp>());
  });

  test('getPlatformVersion', () async {
    FlutterArp flutterArpPlugin = FlutterArp();
    MockFlutterArpPlatform fakePlatform = MockFlutterArpPlatform();
    FlutterArpPlatform.instance = fakePlatform;

    expect(await flutterArpPlugin.getPlatformVersion(), '42');
  });
}
