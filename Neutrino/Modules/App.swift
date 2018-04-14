import AppKit
import JavaScriptCore
import WebKit

class App: NeutrinoModule {
    override init() {
        super.init()
        map["quit"] = quit
        map["broadcast"] = broadcast
    }
    
    func quit(_ message: NeutrinoMessage) -> String {
        NSApp.terminate(nil)
        return Response(0, true)
    }
    
    func broadcast(_ message: NeutrinoMessage) -> String {
        let newMessage = message["arguments"] as Any
        do {
            _ = jsc?.evaluateScript("window.__NEUTRINO_BROADCAST_HANDLER(\(String(data: try JSONSerialization.data(withJSONObject: newMessage, options: []), encoding: .utf8)!))");
            NSApplication.shared.windows.forEach { (window) in
                do {
                    if(type(of: window) == NSWindow.self) {
                        let webview = window.contentView as! WKWebView
                        webview.evaluateJavaScript("__NEUTRINO_BROADCAST_HANDLER(\(String(data: try JSONSerialization.data(withJSONObject: newMessage, options: []), encoding: .utf8)!))", completionHandler: nil)
                    }
                } catch {
                    print(error)
                }
            }
        } catch {
            print(error)
        }
        return Response(0, true);
    }
}
