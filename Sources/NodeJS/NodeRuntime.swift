//
//  NodeRuntime.swift
//  ringo
//
//  Created by Aarav Gupta on 29/05/26.
//

import SwiftUI
import NodeMobile
import Darwin

public enum NodeRuntime {
    nonisolated(unsafe) private static var customScriptPath: String? = nil

    private static let startOnce: Void = {
        let thread = Thread {
            run()
        }
        thread.stackSize = 2 * 1024 * 1024
        thread.start()
    }()

    /// Start the Node.js engine with a custom script path (e.g. from the app's Bundle.main).
    public static func start(scriptPath: String) {
        self.customScriptPath = scriptPath
        _ = startOnce
    }

    /// Start the Node.js engine using the default bundled script.
    public static func startIfNeeded() {
        _ = startOnce
    }

    private static func run() {
        let path = customScriptPath ?? Bundle.module.path(forResource: "main", ofType: "js", inDirectory: "nodejs-project")
        
        guard let scriptPath = path else {
            print("Unable to find nodejs-project/main.js")
            return
        }

        let arguments = ["node", scriptPath]
        let totalSize = arguments.reduce(0) { $0 + $1.utf8.count + 1 }

        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: totalSize)
        let argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: arguments.count)

        var currentOffset = 0
        for (index, argument) in arguments.enumerated() {
            let cString = Array(argument.utf8CString)
            cString.withUnsafeBufferPointer { source in
                if let baseAddress = source.baseAddress {
                    memcpy(buffer.advanced(by: currentOffset), baseAddress, source.count)
                }
            }
            argv[index] = buffer.advanced(by: currentOffset)
            currentOffset += cString.count
        }

        node_start(Int32(arguments.count), argv)
    }
}
