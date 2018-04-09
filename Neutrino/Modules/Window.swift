import AppKit
import WebKit

class WindowDelegate: NSObject, NSWindowDelegate {

}

class Handler: NSObject, WKScriptMessageHandler {
    var webView: WKWebView
    
    init(_ webView: WKWebView) {
        self.webView = webView
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        do {
            Neutrino.handleMessage(try JSONSerialization.jsonObject(with: (message.body as! String).data(using: .utf8)!, options: []) as! Dictionary, webView)
        } catch {
            print(error)
        }
    }
}

struct WindowOptions {
    var url: String
    var title: String
    init(_ dictionary: [String: Any]) {
        self.url = dictionary["url"] as! String
        self.title = dictionary["title"] as! String
    }
}

struct WindowRequest {
    var index: Int
    init(_ dictionary: [String: Any]) {
        self.index = dictionary["index"] as! Int
    }
}

class Window: NeutrinoModule {
    var map: Dictionary = Dictionary<String, (NeutrinoMessage) -> String>();
    init() {
        map["create"] = create
        map["maximize"] = maximize
        map["close"] = close
    }
    
    func onMessage(_ message: NeutrinoMessage, _ context: JSContext) {
        context.evaluateScript("__NEUTRINO_MESSAGE_HANDLER(\(map[message["method"] as! String]!(message)))")
    }
    
    func onMessage(_ message: NeutrinoMessage, _ context: WKWebView) {
        context.evaluateJavaScript("__NEUTRINO_MESSAGE_HANDLER(\(map[message["method"] as! String]!(message)))")
    }
    
    func create(_ message: NeutrinoMessage) -> String {
        let arguments = WindowOptions(message["arguments"] as! [String : Any])
        
        let newWindow = NSWindow(contentRect: NSMakeRect(0, 0, 200, 200),
                                 styleMask: [.closable,.titled,.miniaturizable,.resizable],
                                 backing: NSWindow.BackingStoreType.buffered,
                                 defer: false)
        
        let newWebView = WKWebView()
        
        newWebView.frame = newWindow.frame
        newWebView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        newWebView.load(URLRequest(url: URL(string: arguments.url)!))
        
        newWebView.configuration.userContentController.add(Handler(newWebView), name: "neutrino")
        newWebView.configuration.userContentController.addUserScript(WKUserScript(source: "window.__NEUTRINO_SEND_MESSAGE = function(json){webkit.messageHandlers.neutrino.postMessage(json);};window.__NEUTRINO_MESSAGE_HANDLER = console.error;", injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true))
        
        newWindow.contentView = newWebView
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.title = arguments.title
        return Response(0, true)
    }
    func maximize(_ message: NeutrinoMessage) -> String {
        app.windows[WindowRequest(message["arguments"] as! [String : Any]).index].zoom(nil)
        return Response(0, true)
    }
    func close(_ message: NeutrinoMessage) -> String {
        app.windows[WindowRequest(message["arguments"] as! [String : Any]).index].close()
        return Response(0, true)
    }
}
