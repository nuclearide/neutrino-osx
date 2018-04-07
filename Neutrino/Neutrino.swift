import Foundation

protocol NeutrinoModule {
    func onMessage(_ message: NeutrinoMessage)
}

struct NeutrinoMessageArgument: Codable {
    var string: String?
    var number: Int?
}

struct NeutrinoMessage: Codable {
    var seq: Int
    var module: String
    var method: String
    var arguments: [NeutrinoMessageArgument]
}

var map: [String: NeutrinoModule] = [
    "FileSystem": FileSystem(),
    "Window": Window()
]

class Neutrino {
    class func handleMessage(_ message: String) {
        let decoder = JSONDecoder()
        do {
            let message = try decoder.decode(NeutrinoMessage.self, from: message.data(using: .utf8)!)
            let method = NSSelectorFromString(message.method)
            if(map[message.module] != nil) {
                map[message.module]?.onMessage(message)
            } else {
                print("Module Not Found: "+message.module)
            }
        } catch {
            print(error)
        }
    }
}
