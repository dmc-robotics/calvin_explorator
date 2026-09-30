import Foundation
import Testing
@testable import CalvinExplorator

struct CogitatorEndpointTests {
    @Test func validEndpointMakesWebSocketURL() {
        let endpoint = CogitatorEndpoint(host: "192.168.1.50", port: 5560)
        #expect(endpoint.url?.absoluteString == "ws://192.168.1.50:5560")
    }

    @Test(arguments: [
        CogitatorEndpoint(host: "", port: 5560),
        CogitatorEndpoint(host: "calvin jetson", port: 5560),
        CogitatorEndpoint(host: "localhost", port: 0),
        CogitatorEndpoint(host: "localhost", port: 70000),
    ])
    func invalidEndpointHasNoURL(endpoint: CogitatorEndpoint) {
        #expect(endpoint.url == nil)
    }

    @Test func savesAndLoads() throws {
        let defaults = try #require(UserDefaults(suiteName: "CogitatorEndpointTests"))
        defaults.removePersistentDomain(forName: "CogitatorEndpointTests")
        #expect(CogitatorEndpoint.load(from: defaults) == .default)

        CogitatorEndpoint(host: "calvin.local", port: 6000).save(to: defaults)
        #expect(CogitatorEndpoint.load(from: defaults) == CogitatorEndpoint(host: "calvin.local", port: 6000))
    }
}
