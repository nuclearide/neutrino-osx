import Foundation
import JavaScriptCore
import WebKit

struct MenuItem {
    var label: String
    var id: Int
    var submenu: Array<Any>?
    init(_ item: Any) {
        let menuItem = item as! Dictionary<String, Any>
        label = menuItem["label"] as! String
        id = menuItem["id"] as! Int
        submenu = menuItem["submenu"] as? Array<Any> ?? nil
    }
}

func buildMenu(_ menu: Array<Any>) -> NSMenu {
    let m = NSMenu()
    menu.forEach { (menuItem) in
        let parsedItem = MenuItem(menuItem)
        let item = m.addItem(withTitle: parsedItem.label, action: "handleMenu:", keyEquivalent: "")
        item.tag = parsedItem.id
        if(parsedItem.submenu != nil) {
            item.submenu = buildMenu(parsedItem.submenu!)
        }
    }
    return m
}

class Menu: NeutrinoModule {
    var map: Dictionary = Dictionary<String, (NeutrinoMessage) -> String>()
    
    init() {
        map["setApplicationMenu"] = setApplicationMenu
    }
    
    func onMessage(_ message: NeutrinoMessage, _ context: JSContext) {
        context.evaluateScript("__NEUTRINO_MESSAGE_HANDLER(\(map[message["method"] as! String]!(message)))")
    }
    
    func onMessage(_ message: NeutrinoMessage, _ context: WKWebView) {
        context.evaluateJavaScript("__NEUTRINO_MESSAGE_HANDLER(\(map[message["method"] as! String]!(message)))")
    }
    
    func setApplicationMenu(_ message: NeutrinoMessage) -> String {
        let menu = message["arguments"] as! Array<Any>

        
        NSApplication.shared.mainMenu = buildMenu(menu)
        
        return Response(0, true)
    }
    
}
