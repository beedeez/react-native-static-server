@objc(StaticServer)
class StaticServer: NSObject {

  private var webServer: GCDWebServer?
  private var wwwRoot: String?
  private var port: NSNumber = -1
  private var url: String?
  private var keepAlive: Bool = false
  private var localhostOnly: Bool = false

  override init() {
    super.init()
    webServer = GCDWebServer()
  }

  deinit {
    if webServer?.isRunning == true {
      webServer?.stop()
    }
    webServer = nil
  }

  @objc
  func methodQueue() -> DispatchQueue {
    return DispatchQueue(label: "Beedeez Static Server", attributes: [])
  }

  @objc
  func start(
    _ port: String,
    root optRoot: String,
    localOnly: Bool,
    keepAlive: Bool,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    var root: String

    switch optRoot {
    case "DocumentDir":
      root =
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
    case "BundleDir":
      root = Bundle.main.bundlePath
    default:
      if optRoot.hasPrefix("/") {
        root = optRoot
      } else {
        let documentDir =
          NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        root = "\(documentDir)/\(optRoot)"
      }
    }

    self.wwwRoot = root
    self.port = NSNumber(value: Int(port) ?? -1)
    self.keepAlive = keepAlive
    self.localhostOnly = localOnly

    if webServer?.isRunning == true {
      NSLog("StaticServer already running at \(self.url ?? "Unknown")")
      resolve(self.url)
      return
    }

    setupServer()

    var options: [String: Any] = [:]
    options[GCDWebServerOption_Port] = self.port.intValue != -1 ? self.port : 8080

    if self.localhostOnly {
      options[GCDWebServerOption_BindToLocalhost] = true
    }

    if self.keepAlive {
      options[GCDWebServerOption_AutomaticallySuspendInBackground] = false
      options[GCDWebServerOption_ConnectedStateCoalescingInterval] = 2.0
    }

    do {
      try webServer?.start(options: options)
      if let serverURL = webServer?.serverURL {
        self.url =
          "\(serverURL.scheme ?? "http")://\(serverURL.host ?? "localhost"):\(serverURL.port ?? 8080)"
        NSLog("Started StaticServer at URL \(self.url!)")
        resolve(self.url)
      } else {
        reject("server_error", "StaticServer could not start", nil)
      }
    } catch {
      NSLog("Error starting StaticServer: \(error)")
      reject("server_error", "StaticServer could not start", error)
    }
  }

  private func setupServer() {
    guard let directoryPath = self.wwwRoot else { return }

    webServer?.addHandler(
      match: { requestMethod, url, headers, path, query in
        guard requestMethod == "GET" else { return nil }
        guard path.hasPrefix("/") else { return nil }
        return GCDWebServerRequest(
          method: requestMethod, url: url, headers: headers, path: path, query: query)
      },
      process: { request in
        let filePath = directoryPath.appending("/").appending(
          GCDWebServerNormalizePath(request.path.dropFirst()))
        let fileType = try? FileManager.default.attributesOfItem(atPath: filePath)[.type] as? String

        if fileType == FileAttributeType.typeDirectory.rawValue {
          let indexPath = filePath.appending("/index.html")
          if FileManager.default.fileExists(atPath: indexPath) {
            return GCDWebServerFileResponse(file: indexPath)
          } else {
            return GCDWebServerResponse(statusCode: 404)
          }
        } else if fileType == FileAttributeType.typeRegular.rawValue {
          let response = GCDWebServerFileResponse(file: filePath)
          response?.setValue("GET", forAdditionalHeader: "Access-Control-Request-Method")
          response?.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
          response?.setValue(
            "Origin, X-Requested-With, Content-Type, Accept, Cache-Control, Range, Access-Control-Allow-Origin",
            forAdditionalHeader: "Access-Control-Request-Headers")
          return response
        }
        return GCDWebServerResponse(statusCode: 404)
      })
  }

  @objc
  func stop() {
    if webServer?.isRunning == true {
      webServer?.stop()
      NSLog("StaticServer stopped")
    }
  }

  @objc
  func origin(
    _ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    resolve(webServer?.isRunning == true ? self.url : "")
  }

  @objc
  func isRunning(
    _ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    resolve(webServer?.isRunning == true)
  }

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
}