import AppKit
import WebKit

class WindowDelegate: NSObject, NSWindowDelegate {

}

class Handler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Neutrino.handleMessage(message.body as! String)
    }
}

class Window: NeutrinoModule {
    
    var map: Dictionary = Dictionary<String, (NeutrinoMessage) -> Void>()
    
    init() {
        map["create"] = create
        map["maximize"] = maximize
        map["close"] = close
    }
    
    func onMessage(_ message: NeutrinoMessage) {
        map[message.method]!(message)
    }
    
    func create(_ message: NeutrinoMessage) {
        let newWindow = NSWindow(contentRect: NSMakeRect(0, 0, 200, 200),
                                 styleMask: [.closable,.titled,.miniaturizable,.resizable],
                                 backing: NSWindow.BackingStoreType.buffered,
                                 defer: false)
        
        let newWebView = WKWebView()
        
        newWebView.frame = newWindow.frame
        newWebView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        newWebView.load(URLRequest(url: URL(string: message.arguments[1].string!)!))
        newWebView.configuration.userContentController.add(Handler(), name: "neutrino")
        newWebView.configuration.userContentController.addUserScript(WKUserScript(source: "window.__NEUTRINO_SEND_MESSAGE = function(json){webkit.messageHandlers.neutrino.postMessage(json);};window.__NEUTRINO_MESSAGE_HANDLER = console.error;", injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true))
        
        newWindow.contentView = newWebView
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.title = message.arguments[0].string!
    }
    func maximize(_ message: NeutrinoMessage) {
        app.windows[message.arguments[0].number!].zoom(nil)
    }
    func close(_ message: NeutrinoMessage) {
        app.windows[message.arguments[0].number!].close()
    }
}
