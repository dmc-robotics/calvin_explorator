import Foundation
import Testing
@testable import CalvinExplorator

struct CogitatorEndpointTests {
    @Test(arguments: [
        ("192.168.1.50", "ws://192.168.1.50:5560"),
        ("calvin.local", "ws://calvin.local:5560"),
        ("jetson-01", "ws://jetson-01:5560"),
        ("[::1]", "ws://[::1]:5560"),
    ])
    func validEndpointMakesWebSocketURL(host: String, expected: String) {
        #expect(CogitatorEndpoint(host: host, port: 5560).url?.absoluteString == expected)
    }

    @Test(arguments: [
        CogitatorEndpoint(host: "", port: 5560),
        CogitatorEndpoint(host: "calvin jetson", port: 5560),
        CogitatorEndpoint(host: "robot/x", port: 5560),
        CogitatorEndpoint(host: "ws://robot", port: 5560),
        CogitatorEndpoint(host: "user@robot", port: 5560),
        CogitatorEndpoint(host: "robot?x", port: 5560),
        CogitatorEndpoint(host: "fe80::1", port: 5560),
        CogitatorEndpoint(host: "localhost", port: 0),
        CogitatorEndpoint(host: "localhost", port: 70000),
    ])
    func invalidEndpointHasNoURL(endpoint: CogitatorEndpoint) {
        #expect(endpoint.url == nil)
    }

    @Test func savesAndLoads() {
        let testDefaults = TestDefaults()
        #expect(CogitatorEndpoint.load(from: testDefaults.defaults) == .default)

        CogitatorEndpoint(host: "calvin.local", port: 6000).save(to: testDefaults.defaults)
        #expect(CogitatorEndpoint.load(from: testDefaults.defaults) == CogitatorEndpoint(host: "calvin.local", port: 6000))
    }

    @Test func invalidSavedEndpointFallsBackToDefault() {
        let testDefaults = TestDefaults()
        CogitatorEndpoint(host: "robot/x", port: 6000).save(to: testDefaults.defaults)
        #expect(CogitatorEndpoint.load(from: testDefaults.defaults) == .default)
    }
}
