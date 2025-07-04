import Foundation
import WebKit

/// Manages loading and saving of cookies for WKWebView
class CookieManager {
    /// Load cookies from bundled JSON file into given cookie store
    static func load(fromBundleFile name: String, into store: WKHTTPCookieStore) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let rawArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            rawArray?.forEach { dict in
                var props = [HTTPCookiePropertyKey: Any]()
                dict.forEach { key, value in
                    props[HTTPCookiePropertyKey(key)] = value
                }
                if let cookie = HTTPCookie(properties: props) {
                    store.setCookie(cookie)
                }
            }
        } catch {
            print("CookieManager load error: \(error)")
        }
    }
    /// Save current cookies from store to JSON at given URL
    static func save(from store: WKHTTPCookieStore, to url: URL) {
        store.getAllCookies { cookies in
            let array = cookies.compactMap { $0.properties }
            do {
                let data = try JSONSerialization.data(withJSONObject: array)
                try data.write(to: url)
            } catch {
                print("CookieManager save error: \(error)")
            }
        }
    }
}