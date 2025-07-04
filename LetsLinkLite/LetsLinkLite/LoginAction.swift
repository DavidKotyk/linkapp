import WebKit

/// BrowserAction that logs into Facebook mobile via JS injection
struct LoginAction: BrowserAction {
    let name = "Login"
    let email: String
    let password: String

    func run(on webView: WKWebView, completion: @escaping (Result<Any?, Error>) -> Void) {
        let js = """
        (() => {
          document.querySelector('input[name=\\"email\\"]').value = '
            + "\(email)" + "';
          document.querySelector('input[name=\\"pass\\"]').value = '
            + "\(password)" + "';
          document.querySelector('button[name=\\"login\\"]').click();
          return true;
        })();
        """
        webView.evaluateJavaScript(js) { (res, err) in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(res))
            }
        }
    }
}