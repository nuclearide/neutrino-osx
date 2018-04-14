import Foundation
import JavaScriptCore
import WebKit

struct FileSystemRequest {
    var filePath: String
    var contents: String
    
    init(_ dict: Dictionary<String, Any>) {
        filePath = dict["filePath"] as! String
        contents = dict["contents"] as? String ?? ""
    }
}

class FileSystem: NeutrinoModule {
    var cwd: String = ""
    
    override init() {
        super.init()
        map["readFile"] = readFile
        map["readdir"] = readdir
        map["writeFile"] = writeFile
        if(debug) {
            cwd = (URL(string: CommandLine.arguments[1])?.deletingLastPathComponent().absoluteString)!
        } else {
            cwd = Bundle.main.bundlePath
        }
    }
    
    
    func readFile(_ message: NeutrinoMessage) -> String{
        do {
            let args = FileSystemRequest(message["arguments"] as! Dictionary<String, Any>)
            let path = URL(string: args.filePath, relativeTo: URL(string: cwd))
            return Response(message["seq"] as! Int, [try String(contentsOfFile: (path?.absoluteString)!, encoding: .utf8)])
        } catch {
            print(error)
        }
        return Response(message["seq"] as! Int, [nil, "Error"])
    }
    
    func readdir(_ message: NeutrinoMessage) -> String{
        do {
            let args = FileSystemRequest(message["arguments"] as! Dictionary<String, Any>)
            let path = URL(string: args.filePath, relativeTo: URL(string: cwd))
            let files = try FileManager.default.contentsOfDirectory(at: path!, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            let ret = files.map { (_ url: URL) -> String in
                return url.lastPathComponent
            }
            return Response(message["seq"] as! Int, ret);
        } catch {
            print(error)
        }
        return Response(message["seq"] as! Int, [nil, "Error"])
    }
    
    func writeFile(_ message: NeutrinoMessage) -> String{
        do {
            let args = FileSystemRequest(message["arguments"] as! Dictionary<String, Any>)
            let path = URL(fileURLWithPath: args.filePath, relativeTo: URL(fileURLWithPath: cwd))
            
            try args.contents.write(to: path, atomically: false, encoding: .utf8)
            
            return Response(message["seq"] as! Int, [true])
        } catch {
            print(error)
        }
        return Response(message["seq"] as! Int, [nil, "Error"])
    }
}
