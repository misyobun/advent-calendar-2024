import UIKit
@preconcurrency import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
    var webView: WKWebView!

    var isFollowed = false
    override func viewDidLoad() {
        super.viewDidLoad()

        // WebViewの設定
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // JavaScriptコードを注入
        let jsCode = """
        window.followToggleExample = {
          follow: (publicCalendarId) => {
            return new Promise((resolve, reject) => {
              window.__resolveFollowToggleCalendar = resolve;
              window.__rejectFollowToggleCalendar = reject;
              window.webkit.messageHandlers.follow.postMessage(publicCalendarId);
            });
          },
          isFollowing: (options = {}) => {
            return window.webkit.messageHandlers.isFollowing.postMessage(options);
          }
        };
        """
        let userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(userScript)

        // iOS -> JS のメッセージハンドラーを追加
        contentController.add(self, name: "follow")
        contentController.addScriptMessageHandler(LeakAvoidingScriptMessageHandlerWithReply(self), contentWorld: .page, name: "isFollowing")
        config.userContentController = contentController

        // JS側のConsole.logを受ける
        config.userContentController.add(self, name: "logging")

        // override console.log
        let _override = WKUserScript(source: "var console = { log: function(msg){window.webkit.messageHandlers.logging.postMessage(msg) }};", injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(_override)
        webView = WKWebView(frame: view.bounds, configuration: config)
        view.addSubview(webView)

        // Webページをロード
        if let url = URL(string: "http://localhost:3000/") {
            webView.load(URLRequest(url: url))
        }
    }

    // JSからのメッセージを受信
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "follow", let sampleID = message.body as? String {
            print("フォロー要求を受信: \(sampleID)")
            Task {
                do {
                    // フォロー/アンフォロー処理を実行
                    try await handleFollowToggle()
                    await sendJavaScriptMessage("window.__resolveFollowToggleCalendar()")
                } catch {
                    await sendJavaScriptMessage("window.__rejectFollowToggleCalendar()")
                }
            }
        } else if message.name == "logging" {
            print("WebView: \(message.body) ")
        }
    }

    private func handleFollowToggle() async throws {
        // 本来はフォロー・アンフォローのAPIと通信するが、今回はsleepする
        try await Task.sleep(nanoseconds: 1_000_000_000)
        // 今回は例のためトグル対応
        isFollowed = !isFollowed
    }

    // JavaScriptメッセージ送信を簡略化
    private func sendJavaScriptMessage(_ script: String) async {
        await MainActor.run {
            self.webView.evaluateJavaScript(script) { _, error in
                if let error {
                    print("JavaScript評価エラー: \(error)")
                }
            }
        }
    }
}

extension ViewController: WKScriptMessageHandlerWithReply {
    func userContentController(_ userContentController: WKUserContentController, didReceive scriptMessage: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        if scriptMessage.name == "isFollowing" {
            print("フォロ状態　\(isFollowed)")
            replyHandler(isFollowed, nil)
        } else {
            replyHandler(nil, "Invalid message")
        }
    }
}

final class LeakAvoidingScriptMessageHandlerWithReply: NSObject, WKScriptMessageHandlerWithReply {

    weak var actualMessageHandlerWithReply: WKScriptMessageHandlerWithReply?

    init(_ actualMessageHandlerWithReply: WKScriptMessageHandlerWithReply) {
        self.actualMessageHandlerWithReply = actualMessageHandlerWithReply
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping @MainActor @Sendable (Any?, String?) -> Void) {
        actualMessageHandlerWithReply?.userContentController(userContentController, didReceive: message, replyHandler: replyHandler)
    }

}
