import Foundation
import Testing
@testable import CalvinExplorator

/// Drives `CogitatorConnection` with fake sockets and a policy measured in milliseconds
struct CogitatorConnectionTests {
    static let fastPolicy = ReconnectPolicy(
        initialDelay: 0.01,
        maxDelay: 0.01,
        maxAttempts: 3,
        connectTimeout: 0.2,
        livenessTimeout: 0.2,
        watchdogInterval: 0.02,
        minimumStableDuration: 10
    )

    let url = URL(string: "ws://calvin.local:5560")!

    @Test func opensAndForwardsMessages() async {
        let socket = FakeSocket()
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in socket }
        var received: [String] = []
        connection.onMessage = { received.append($0) }

        connection.connect(to: url)
        socket.open()
        socket.deliver("hello")

        #expect(await waitUntil { connection.status == .connected && received == ["hello"] })

        try? await connection.send("command")
        #expect(socket.sentTexts == ["command"])

        connection.disconnect()
        #expect(connection.status == .disconnected)
        #expect(await waitUntil { socket.isClosed })
    }

    @Test func sendThrowsWhenNotConnected() async {
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in FakeSocket() }
        await #expect(throws: CogitatorConnection.SendError.self) {
            try await connection.send("x")
        }
    }

    @Test func goesOfflineAfterRepeatedFailures() async {
        var sockets: [FakeSocket] = []
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in
            let socket = FakeSocket()
            socket.fail()
            sockets.append(socket)
            return socket
        }

        connection.connect(to: url)

        #expect(await waitUntil { connection.status == .offline })
        #expect(sockets.count == Self.fastPolicy.maxAttempts)
        #expect(connection.lastError != nil)
    }

    @Test func connectionsThatDropRightAwayStillGoOffline() async {
        var sockets: [FakeSocket] = []
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in
            let socket = FakeSocket()
            socket.open()
            socket.fail()
            sockets.append(socket)
            return socket
        }

        connection.connect(to: url)

        #expect(await waitUntil { connection.status == .offline })
        #expect(sockets.count == Self.fastPolicy.maxAttempts)
    }

    @Test func stableConnectionResetsTheFailureCount() async {
        var policy = Self.fastPolicy
        policy.minimumStableDuration = 0
        var sockets: [FakeSocket] = []
        let connection = CogitatorConnection(policy: policy) { _ in
            let socket = FakeSocket()
            socket.open()
            socket.fail()
            sockets.append(socket)
            return socket
        }

        connection.connect(to: url)

        // Every drop follows a (zero-length) stable connection, so it never gives up
        #expect(await waitUntil { sockets.count > policy.maxAttempts * 2 })
        #expect(connection.status != .offline)
        connection.disconnect()
    }

    @Test func handshakeTimesOut() async {
        let socket = FakeSocket()
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in socket }

        connection.connect(to: url)

        #expect(await waitUntil { socket.isClosed })
        #expect(await waitUntil { connection.lastError == LinkMonitor.connectTimeoutReason })
        connection.disconnect()
    }

    @Test func deadLinkIsClosed() async {
        let socket = FakeSocket()
        socket.answersPings = false
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in socket }

        connection.connect(to: url)
        socket.open()

        #expect(await waitUntil { connection.status == .connected })
        #expect(await waitUntil { socket.isClosed })
        #expect(await waitUntil { connection.lastError == LinkMonitor.unresponsiveReason })
        connection.disconnect()
    }

    @Test func answeredPingsKeepAQuietLinkOpen() async {
        let socket = FakeSocket()
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in socket }

        connection.connect(to: url)
        socket.open()
        #expect(await waitUntil { connection.status == .connected })

        // Three liveness timeouts with no messages, only pongs
        try? await Task.sleep(for: .seconds(Self.fastPolicy.livenessTimeout * 3))
        #expect(connection.status == .connected)
        #expect(!socket.isClosed)
        connection.disconnect()
    }

    @Test func reconnectingReplacesTheSocket() async {
        var sockets: [FakeSocket] = []
        let connection = CogitatorConnection(policy: Self.fastPolicy) { _ in
            let socket = FakeSocket()
            socket.open()
            sockets.append(socket)
            return socket
        }

        connection.connect(to: url)
        #expect(await waitUntil { connection.status == .connected })

        connection.connect(to: url)
        #expect(await waitUntil { sockets.count == 2 && connection.status == .connected })
        #expect(await waitUntil { sockets[0].isClosed })

        try? await connection.send("to the new socket")
        #expect(sockets[0].sentTexts.isEmpty)
        #expect(sockets[1].sentTexts == ["to the new socket"])
        connection.disconnect()
    }
}
