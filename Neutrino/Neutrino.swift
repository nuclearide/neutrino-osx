import Foundation
import JavaScriptCore
import WebKit

class NeutrinoModule {
    var map: Dictionary<String, (NeutrinoMessage) -> String> = Dictionary()
    func onMessage(_ message: NeutrinoMessage, _ context: JSContext) {
        context.evaluateScript("window.__NEUTRINO_MESSAGE_HANDLER(\(map[message["method"] as! String]!(message)))")
    }
    
    func onMessage(_ message: NeutrinoMessage, _ context: WKWebView) {
        context.evaluateJavaScript("__NEUTRINO_MESSAGE_HANDLER(\(map[message["method"] as! String]!(message)))")
    }
}

var map: [String: NeutrinoModule] = [
    "App": App(),
    "FileSystem": FileSystem(),
    "Window": Window(),
    "Menu": Menu()
]

func Response (_ seq: Int, _ data: Any) -> String {
    do {
        return String(data: try JSONSerialization.data(withJSONObject: [seq, data], options: []), encoding: .utf8)!
    } catch {
        print(error)
    }
    return "{}"
}

typealias NeutrinoMessage = Dictionary<String, Any>

class Neutrino {
    class func handleMessage(_ message: NeutrinoMessage, _ context: JSContext) {
        if(map[message["module"] as! String] != nil) {
            map[message["module"] as! String]?.onMessage(message, context)
        } else {
            print("Module Not Found: "+(message["module"] as! String))
        }
    }
    class func handleMessage(_ message: NeutrinoMessage, _ context: WKWebView) {
        if(map[message["module"] as! String] != nil) {
            map[message["module"] as! String]?.onMessage(message, context)
        } else {
            print("Module Not Found: "+(message["module"] as! String))
        }
    }
}
