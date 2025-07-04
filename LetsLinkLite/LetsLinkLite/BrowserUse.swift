import Foundation
import WebKit

// MARK: - Configuration
/// Configuration for launching or connecting to a browser instance
struct BrowserConfig {
    /// Use headless or headed mode
    var headless: Bool = false
    /// Path to Chrome/Chromium executable (unused on iOS)
    var executablePath: String?
    /// Additional browser arguments
    var extraArgs: [String] = []
}

/// Configuration for a browser context (cookie persistence, isolation)
struct BrowserContextConfig {
    /// Optional path to a local JSON file storing HTTPCookie data
    var cookiesFile: String?
}

// MARK: - Controller
/// Protocol for a single atomic browser action
protocol BrowserAction {
    var name: String { get }
    func run(on webView: WKWebView, completion: @escaping (Result<Any?, Error>) -> Void)
}

/// Registry holding named BrowserAction instances
class Controller {
    static let shared = Controller()
    private var actions = [String: BrowserAction]()
    private init() {}
    /// Register a new action under its `name`
    func register(_ action: BrowserAction) {
        actions[action.name] = action
    }
    /// Perform an action by name
    func perform(_ name: String, on webView: WKWebView, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let action = actions[name] else {
            completion(.failure(NSError(domain: "Controller", code: 0, userInfo: [NSLocalizedDescriptionKey: "Action not found: \(name)"])))
            return
        }
        action.run(on: webView, completion: completion)
    }
}

// MARK: - Agent
/// Orchestrates a sequence of BrowserActions against a WKWebView
class Agent {
    let plan: [String]
    let webView: WKWebView
    init(plan: [String], webView: WKWebView) {
        self.plan = plan
        self.webView = webView
    }
    /// Execute the plan in order
    func run(completion: @escaping (Result<Any?, Error>) -> Void) {
        runNext(index: 0, lastResult: nil, completion: completion)
    }
    private func runNext(index: Int, lastResult: Any?, completion: @escaping (Result<Any?, Error>) -> Void) {
        if index >= plan.count {
            completion(.success(lastResult))
            return
        }
        let name = plan[index]
        Controller.shared.perform(name, on: webView) { result in
            switch result {
            case .success(let res): self.runNext(index: index+1, lastResult: res, completion: completion)
            case .failure(let err): completion(.failure(err))
            }
        }
    }
}

// MARK: - Persistence
/// Load and save cookies via WKHTTPCookieStore
class CookieStore {
    static func load(from file: String, into store: WKHTTPCookieStore) {
        guard
            let url = Bundle.main.url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let raw = try? JSONSerialization.jsonObject(with: data) as? [[String:Any]]
        else { return }
        raw.forEach { dict in
            var props = [HTTPCookiePropertyKey:Any]()
            dict.forEach { key, val in props[HTTPCookiePropertyKey(key)] = val }
            if let cookie = HTTPCookie(properties: props) {
                store.setCookie(cookie)
            }
        }
    }
    static func save(from store: WKHTTPCookieStore, to url: URL) {
        store.getAllCookies { cookies in
            let array = cookies.compactMap { $0.properties }
            if let data = try? JSONSerialization.data(withJSONObject: array) {
                try? data.write(to: url)
            }
        }
    }
}