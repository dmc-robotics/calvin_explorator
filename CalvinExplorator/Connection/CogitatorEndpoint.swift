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
        guard isValidHost,
              Self.validPorts.contains(port),
              let url = URL(string: "ws://\(host):\(port)"),
              url.port == port,
              url.path().isEmpty
        else { return nil }
        return url
    }

    /// A hostname or IPv4 address (letters, digits, dots, hyphens), or an IPv6 address in brackets.
    /// Rules out anything that would change the URL's meaning, like `/`, `@`, `?` or a scheme
    private var isValidHost: Bool {
        host.wholeMatch(of: /[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?/) != nil
            || host.wholeMatch(of: /\[[0-9A-Fa-f:.]+\]/) != nil
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
