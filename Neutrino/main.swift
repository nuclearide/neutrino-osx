import AppKit
import WebKit
import JavaScriptCore

class WebInspector: NSObject {
    var webView: WebView?
    
    init(webView: WebView?) {
    }
    
    func detach(_ sender: Any?) {
    }
    
    func show(_ sender: Any?) {
    }
    
    func showConsole(_ sender: Any?) {
    }
}

let app = NSApplication.shared

let log: @convention(block) (JSValue) -> () = { input in
    print(input)
}

@objc protocol ConsoleClass: JSExport {
    static func log(_ str: JSValue)
}

@objc class Console: NSObject, ConsoleClass {
    class func log(_ str: JSValue) {
        print(str)
    }
}


@objc protocol TimerJSExport : JSExport {
    
    func setTimeout(_ callback : JSValue,_ ms : Double) -> String
    
    func clearTimeout(_ identifier: String)
    
    func setInterval(_ callback : JSValue,_ ms : Double) -> String
    
}

// Custom class must inherit from `NSObject`
@objc class TimerJS: NSObject, TimerJSExport {
    var timers = [String: Timer]()
    
    static func registerInto(jsContext: JSContext, forKeyedSubscript: String = "timerJS") {
        jsContext.setObject(timerJSSharedInstance,
                            forKeyedSubscript: forKeyedSubscript as (NSCopying & NSObjectProtocol))
        jsContext.evaluateScript(
            "function setTimeout(callback, ms) {" +
                "    return timerJS.setTimeout(callback, ms)" +
                "}" +
                "function clearTimeout(indentifier) {" +
                "    timerJS.clearTimeout(indentifier)" +
                "}" +
                "function setInterval(callback, ms) {" +
                "    return timerJS.setInterval(callback, ms)" +
            "}"
        )
    }
    
    func clearTimeout(_ identifier: String) {
        let timer = timers.removeValue(forKey: identifier)
        
        timer?.invalidate()
    }
    
    
    func setInterval(_ callback: JSValue,_ ms: Double) -> String {
        return createTimer(callback: callback, ms: ms, repeats: true)
    }
    
    func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
        return createTimer(callback: callback, ms: ms , repeats: false)
    }
    
    func createTimer(callback: JSValue, ms: Double, repeats : Bool) -> String {
        let timeInterval  = ms/1000.0
        
        let uuid = NSUUID().uuidString
        
        // make sure that we are queueing it all in the same executable queue...
        // JS calls are getting lost if the queue is not specified... that's what we believe... ;)
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                             target: self,
                                             selector: #selector(self.callJsCallback),
                                             userInfo: callback,
                                             repeats: repeats)
            self.timers[uuid] = timer
        })
        
        
        return uuid
    }
    
    @objc func callJsCallback(_ timer: Timer) {
        let callback = (timer.userInfo as! JSValue)
        
        callback.call(withArguments: nil)
    }
}
let timerJSSharedInstance = TimerJS()

#if DEBUG
let debug = true
#else
let debug = false
#endif

let jsc = JSContext()

let sendMessage: @convention(block) (String) -> Void = { message in
    do {
        let parsedMessage = try JSONSerialization.jsonObject(with: message.data(using: .utf8)!, options: []) as! NeutrinoMessage
        Neutrino.handleMessage(parsedMessage, jsc!)
    } catch {
        print(error)
    }
}

@objc class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        TimerJS.registerInto(jsContext: jsc!)
        jsc?.setObject(Console.self, forKeyedSubscript: "NeutrinoConsole" as NSString)
        
        jsc?.evaluateScript("var __NEUTRINO_MESSAGE_HANDLER;var __NEUTRINO_MENU_HANDLER;")
        jsc?.evaluateScript("var console = {log: function(...args){NeutrinoConsole.log(args)}}")
        jsc?.setObject(sendMessage, forKeyedSubscript: "__NEUTRINO_SEND_MESSAGE" as NSString)
        
        jsc?.exceptionHandler = {(ctx: JSContext!, _ value: JSValue!) in
            print(value)
        }
        
        do {
            if(debug) {
                jsc?.evaluateScript(try String(contentsOfFile: CommandLine.arguments[1]))
            } else {
                jsc?.evaluateScript(try String(contentsOfFile: Bundle.main.path(forResource: "index", ofType: "js")!))
            }
        } catch {
            print(error)
        }
    }
    @objc(handleMenu:)
    func handleMenu(_ arg: NSMenuItem) {
        print(arg.tag)
        jsc?.evaluateScript("__NEUTRINO_MENU_HANDLER(\(arg.tag))");
        NSApplication.shared.windows.forEach { (window) in
            if(type(of: window) == NSWindow.self) {
                let webview = window.contentView as! WKWebView
                webview.evaluateJavaScript("__NEUTRINO_MENU_HANDLER(\(arg.tag))", completionHandler: nil)
            }
        }
    }
}

//let window = NSWindow(contentRect: NSRect(x: 50, y: 50, width: 800, height: 600), styleMask: mask, backing: .buffered, defer: false)
//
//window.makeKeyAndOrderFront(nil)
//
//let webview = WKWebView()
//webview.frame = window.frame
//
//webview.load(URLRequest(url: URL(string: "https://google.com")!))
//
//window.contentView = webview

app.delegate = AppDelegate()
NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
app.run()
