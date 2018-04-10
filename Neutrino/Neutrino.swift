import Foundation
import JavaScriptCore
import WebKit

protocol NeutrinoModule {
    var map: Dictionary<String, (NeutrinoMessage) -> String> {get set}
    func onMessage(_ message: Dictionary<String, Any>, _ context: JSContext)
    func onMessage(_ message: Dictionary<String, Any>, _ context: WKWebView)
}

var map: [String: NeutrinoModule] = [
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
        let method = NSSelectorFromString(message["method"] as! String)
        if(map[message["module"] as! String] != nil) {
            map[message["module"] as! String]?.onMessage(message, context)
        } else {
            print("Module Not Found: "+(message["module"] as! String))
        }
    }
    class func handleMessage(_ message: NeutrinoMessage, _ context: WKWebView) {
        let method = NSSelectorFromString(message["method"] as! String)
        if(map[message["module"] as! String] != nil) {
            map[message["module"] as! String]?.onMessage(message, context)
        } else {
            print("Module Not Found: "+(message["module"] as! String))
        }
    }
}
