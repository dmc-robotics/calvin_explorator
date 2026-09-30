import Foundation
import Testing
@testable import CalvinExplorator

struct AppModelTests {
    let tofMessage = #"{"topic":"sensor.tof","data":{"front":1000}}"#

    @Test func batchesMessagesUntilFlush() {
        let testDefaults = TestDefaults()
        let model = AppModel(defaults: testDefaults.defaults)

        model.receive(tofMessage)
        #expect(model.messageLog.entries.isEmpty)
        #expect(!model.telemetry.tofFront.hasData)

        model.flushPendingMessages()
        #expect(model.messageLog.entries.map(\.text) == [tofMessage])
        #expect(model.telemetry.tofFront.hasData)
    }

    @Test func flushesOnItsOwn() async {
        let testDefaults = TestDefaults()
        let model = AppModel(defaults: testDefaults.defaults)

        model.receive(tofMessage)

        #expect(await waitUntil { model.messageLog.entries.count == 1 })
    }

    @Test func dropsOldestWhenTheBacklogIsFull() {
        let testDefaults = TestDefaults()
        let model = AppModel(defaults: testDefaults.defaults)

        for index in 0..<(AppModel.maxPendingMessages + 5) {
            model.receive("\(index)")
        }
        model.flushPendingMessages()

        #expect(model.droppedMessageCount == 5)
        #expect(model.messageLog.entries.count == AppModel.maxPendingMessages)
        #expect(model.messageLog.entries.first?.text == "5")
    }

    @Test func sendWhileDisconnectedIsLoggedAsFailed() async {
        let testDefaults = TestDefaults()
        let model = AppModel(defaults: testDefaults.defaults)
        model.receive(tofMessage)

        let sent = await model.send(topic: "command.test", data: ["value": 1])

        #expect(!sent)
        // Pending messages are logged first, then the failed send
        #expect(model.messageLog.entries.map(\.direction) == [.received, .sendFailed])
    }

    @Test func remembersSelectedPage() {
        let testDefaults = TestDefaults()
        AppModel(defaults: testDefaults.defaults).selectedPage = .logger
        #expect(AppModel(defaults: testDefaults.defaults).selectedPage == .logger)
    }

    @Test func connectSavesTheEndpoint() {
        let testDefaults = TestDefaults()
        let model = AppModel(defaults: testDefaults.defaults)
        let endpoint = CogitatorEndpoint(host: "127.0.0.1", port: 9)

        model.connect(to: endpoint)
        model.connection.disconnect()

        #expect(model.endpoint == endpoint)
        #expect(CogitatorEndpoint.load(from: testDefaults.defaults) == endpoint)
    }
}
