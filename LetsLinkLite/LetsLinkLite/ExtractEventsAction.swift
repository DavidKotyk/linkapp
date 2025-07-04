import WebKit

/// BrowserAction that extracts event titles from Facebook mobile events page
struct ExtractEventsAction: BrowserAction {
    let name = "ExtractEvents"

    func run(on webView: WKWebView, completion: @escaping (Result<Any?, Error>) -> Void) {
        let js = """
        (() => {
          const anchors = Array.from(document.querySelectorAll('a[href*="/events/"]'));
          const seen = new Set();
          const out = [];
          anchors.forEach(a => {
            const t = (a.textContent || '').trim();
            if (t && !seen.has(t)) { seen.add(t); out.push(t); }
          });
          return JSON.stringify(out);
        })();
        """
        // Delay to allow dynamic content load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            webView.evaluateJavaScript(js) { (res, err) in
                if let err = err {
                    completion(.failure(err))
                } else {
                    completion(.success(res))
                }
            }
        }
    }
}