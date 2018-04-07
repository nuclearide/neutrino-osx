import Foundation

@objc class FileSystem: NSObject, NeutrinoModule {
    func onMessage(_ message: NeutrinoMessage) {
        
    }
    
    func readFile(_ message: NeutrinoMessage) {
        print(message.arguments[0].string)
    }
}
