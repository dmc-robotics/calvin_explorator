import Foundation

/// Host and port of cogitator's WebSocket gateway
struct CogitatorEndpoint: Equatable {
    static let defaultHost = "localhost"
    static let defaultPort = 5560
    static let validPorts = 1...65535
    static let `default` = CogitatorEndpoint(host: defaultHost, port: defaultPort)

    private enum DefaultsKey {
        static let host = "cogitatorHost"
        static let port = "cogitatorPort"
    }

    var host: String
    var port: Int

    /// The gateway's `ws://` URL, or nil when host and port don't form a usable address
    var url: URL? {
        guard !host.isEmpty,
              !host.contains(where: \.isWhitespace),
              Self.validPorts.contains(port),
              let url = URL(string: "ws://\(host):\(port)"),
              url.host() != nil
        else { return nil }
        return url
    }

    var displayName: String { "\(host):\(port)" }

    /// The saved endpoint, or the default when nothing valid is saved
    static func load(from defaults: UserDefaults = .standard) -> CogitatorEndpoint {
        guard let host = defaults.string(forKey: DefaultsKey.host),
              defaults.object(forKey: DefaultsKey.port) != nil
        else { return .default }
        let saved = CogitatorEndpoint(host: host, port: defaults.integer(forKey: DefaultsKey.port))
        return saved.url == nil ? .default : saved
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(host, forKey: DefaultsKey.host)
        defaults.set(port, forKey: DefaultsKey.port)
    }
}
