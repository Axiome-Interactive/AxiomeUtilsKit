import Foundation
import XCTest
@testable import AxiomeUtilsKit

final class RequestManagerConcurrencyTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await configureRequestManagerForMocking()
        await TestURLProtocol.setHandler(nil)
    }

    override func tearDown() async throws {
        await TestURLProtocol.setHandler(nil)
        try await super.tearDown()
    }

    func testCancelCancelsInFlightRequest() async throws {
        await TestURLProtocol.setHandler { request in
            try await Task.sleep(for: .seconds(5))

            guard let url = request.url,
                  let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                  ) else {
                throw URLError(.badServerResponse)
            }

            return (response, Data("ok".utf8))
        }

        let request = TestRequest(path: "/slow")
        let inFlightTask: Task<NetworkResponse, Error> = Task {
            try await RequestManager.shared.request(request)
        }

        try await waitUntilRegisteredTask(for: request.description)
        await request.cancel()

        do {
            _ = try await inFlightTask.value
            XCTFail("Expected a cancellation error.")
        } catch {
            let nsError = error as NSError
            let isCancelled = error is CancellationError
                || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled)
            XCTAssertTrue(isCancelled, "Expected cancellation error, got \(error).")
        }

        let inFlightAfterCancellation = await RequestManager.shared.tasks[request.description]
        XCTAssertNil(inFlightAfterCancellation)
    }

    func testRequestRetriesAfter401WhenAuthenticationRefreshes() async throws {
        let auth = RefreshableAuthentication(initialToken: "expired-token")
        let requestCounter = RequestCounter()

        await TestURLProtocol.setHandler { request in
            await requestCounter.increment()

            let authorizationHeader = request.value(forHTTPHeaderField: "Authorization")
            let statusCode = authorizationHeader == "Bearer valid-token" ? 200 : 401

            guard let url = request.url,
                  let response = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                  ) else {
                throw URLError(.badServerResponse)
            }

            return (response, Data("ok".utf8))
        }

        let request = TestRequest(path: "/retry", authentification: auth)
        let response = try await RequestManager.shared.request(request)
        let refreshCount = await auth.refreshCount
        let sentRequests = await requestCounter.value

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(String(data: try XCTUnwrap(response.data), encoding: .utf8), "ok")
        XCTAssertEqual(refreshCount, 1)
        XCTAssertEqual(sentRequests, 2)
    }

    private func configureRequestManagerForMocking() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TestURLProtocol.self]
        await RequestManager.shared.setRequestConfiguration(configuration)
    }

    private func waitUntilRegisteredTask(for description: String, timeout: Duration = .seconds(2)) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if await RequestManager.shared.tasks[description] != nil {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }

        XCTFail("Timed out waiting for request task registration.")
    }
}

private struct TestRequest: RequestProtocol {
    let scheme: String = "https"
    let host: String = "example.com"
    let path: String
    let method: RequestMethod = .get
    let authentification: AuthentificationProtocol?

    init(path: String, authentification: AuthentificationProtocol? = nil) {
        self.path = path
        self.authentification = authentification
    }
}

private actor RefreshableAuthentication: @preconcurrency AuthentificationRefreshableProtocol {
    private var token: String
    private(set) var refreshCount: Int = 0

    init(initialToken: String) {
        self.token = initialToken
    }

    var headers: Headers {
        get async { ["Authorization": "Bearer \(token)"] }
    }

    nonisolated var urlQueryItems: [URLQueryItem] { [] }

    var isValid: Bool {
        get async { token == "valid-token" }
    }

    nonisolated func refresh(from request: URLRequest?) async throws {
        await markRefreshed()
    }

    private func markRefreshed() {
        token = "valid-token"
        refreshCount += 1
    }
}

private actor RequestCounter {
    private(set) var value: Int = 0

    func increment() {
        value += 1
    }
}

private actor TestURLProtocolHandlerStore {
    typealias Handler = @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)

    private var currentHandler: Handler?

    func set(_ handler: Handler?) {
        currentHandler = handler
    }

    func get() -> Handler? {
        currentHandler
    }
}

private final class TestURLProtocol: URLProtocol, @unchecked Sendable {
    private static let handlerStore = TestURLProtocolHandlerStore()
    private var runningTask: Task<Void, Never>?

    static func setHandler(_ handler: TestURLProtocolHandlerStore.Handler?) async {
        await handlerStore.set(handler)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        runningTask = Task {
            guard let handler = await Self.handlerStore.get() else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }

            do {
                let (response, data) = try await handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch is CancellationError {
                client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {
        runningTask?.cancel()
        runningTask = nil
    }
}
