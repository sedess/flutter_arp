import Cocoa
import FlutterMacOS

public class FlutterArpPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_arp", binaryMessenger: registrar.messenger)
    let instance = FlutterArpPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "getArpTable":
      // Lógica para obtener la tabla ARP
      let arpEntries = getArpTable()
      result(arpEntries)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  struct ArpEntry {
        let ip: [UInt8] // Cambié el tipo de String a [UInt8]
        let mac: [UInt8] // Cambié el tipo de String a [UInt8]
    }

  func getArpTable() -> [ArpEntry] {
      var entries = [ArpEntry]()
      
      let mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_FLAGS, RTF_LLINFO]
      var len: size_t = 0
      
      if sysctl(UnsafeMutablePointer(mutating: mib), UInt32(mib.count), nil, &len, nil, 0) < 0 {
          perror("sysctl")
          return []
      }
      
      let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
      defer { buffer.deallocate() }
      
      if sysctl(UnsafeMutablePointer(mutating: mib), UInt32(mib.count), buffer, &len, nil, 0) < 0 {
          perror("sysctl")
          return []
      }
      
      var next = buffer
      let end = buffer.advanced(by: len)
      
      while next < end {
          let rtMsghdr = next.withMemoryRebound(to: rt_msghdr.self, capacity: 1) { $0.pointee }
          let sockaddr_in = next.advanced(by: MemoryLayout<rt_msghdr>.size).withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
          let sockaddr_dl = next.advanced(by: MemoryLayout<rt_msghdr>.size + MemoryLayout<sockaddr_in>.size).withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { $0.pointee }
          
          // Obtener dirección IP en bytes
          let ipAddress: [UInt8] = [
              UInt8(sockaddr_in.sin_addr.s_addr & 0xff),
              UInt8((sockaddr_in.sin_addr.s_addr >> 8) & 0xff),
              UInt8((sockaddr_in.sin_addr.s_addr >> 16) & 0xff),
              UInt8((sockaddr_in.sin_addr.s_addr >> 24) & 0xff)
          ]
          
          // Obtener dirección MAC en bytes
          let macAddress: [UInt8] = (0..<Int(sockaddr_dl.sdl_alen)).map {
              return UInt8(sockaddr_dl.sdl_data[Int(sockaddr_dl.sdl_nlen) + $0])
          }
          
          entries.append(ArpEntry(ip: ipAddress, mac: macAddress))
          
          next = next.advanced(by: Int(rtMsghdr.rtm_msglen))
      }
      
      return entries
  }
}