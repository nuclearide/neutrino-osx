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
            item.submenu?.title = parsedItem.label
        }
    }
    return m
}

class Menu: NeutrinoModule {
    
    override init() {
        super.init()
        map["setApplicationMenu"] = setApplicationMenu
    }

    
    func setApplicationMenu(_ message: NeutrinoMessage) -> String {
        let menu = message["arguments"] as! Array<Any>

        
        NSApplication.shared.mainMenu = buildMenu(menu)
        
        return Response(0, true)
    }
    
}
