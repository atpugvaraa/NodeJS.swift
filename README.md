# NodeJS Swift Package

A fully reusable Swift Package wrapper for running [nodejs-mobile](https://github.com/nodejs-mobile/nodejs-mobile) in your iOS applications. 

This package allows you to easily embed a full Node.js runtime inside your Swift apps. You can use it to run an Express or Hono server, execute Node scripts, and use standard NPM packages natively on an iPhone or iOS Simulator.

## Features
- **Drop-in Swift Package:** Simple integration using Xcode and Swift Package Manager.
- **Custom Scripts:** Inject your own `nodejs-project` from your app bundle, or fallback to the default provided by the package.
- **Built-in UI:** Includes `NodeServerView` to help you test and debug your local Node server connection via Wi-Fi or USB.

## Usage

### 1. Installation
Add this package to your Xcode project via Swift Package Manager by pointing it to this GitHub repository.

**Important Framework Setup:**
To keep this repository lightweight, the compiled Node.js framework is not distributed directly. You must download it manually to make the app work:
1. Download the Node.js framework from the [nodejs-mobile releases page](https://github.com/nodejs-mobile/nodejs-mobile/releases).
2. Unzip the downloaded archive.
3. Add the `NodeMobile.xcframework` and the `include` folder into the `Frameworks` folder of this package (located at `/Users/aaravgupta/Programming/Swift/Packages/NodeJS.swift/Frameworks`).

### 2. Preparing your `nodejs-project`
Create a folder named `nodejs-project` in your main iOS application target. This folder will contain your JavaScript code. 

**Important:** Before building your app, you must install your dependencies inside this folder so that the `node_modules` directory is bundled into your app.
```bash
cd path/to/your/app/nodejs-project
npm install # or bun install
```

### 3. Injecting Your Node.js Project
Drop your `nodejs-project` folder into your main iOS application target (ensure it is added to your target's Copy Bundle Resources). Then, you can start the Node runtime by pointing it to your app's JavaScript entry file:

```swift
import SwiftUI
import NodeJS

@main
struct MyApp: App {
    init() {
        // Find the path to the main.js in your app's bundle
        if let scriptPath = Bundle.main.path(forResource: "main", ofType: "js", inDirectory: "nodejs-project") {
            // Start the Node engine using your custom app-level code
            NodeRuntime.start(scriptPath: scriptPath)
        } else {
            // Fallback to the default script bundled inside the NodeJS package
            NodeRuntime.startIfNeeded()
        }
    }

    var body: some Scene {
        WindowGroup {
            // Use the built-in view for testing
            NodeServerView()
        }
    }
}
```

## Local Development (Bun & NPM)
You can use `bun` locally on your Mac to manage packages (`bun install`) for your `nodejs-project`. 

> **Warning**: Keep in mind that the engine running on the device is **Node.js (V8)**. You cannot use Bun-specific APIs (like `Bun.serve()`) inside your scripts. You must stick to Node.js compatible APIs.

---

## Acknowledgements & Licensing

This project is a Swift wrapper around the incredible [**nodejs-mobile**](https://github.com/nodejs-mobile/nodejs-mobile) project. All heavy lifting, including the compiled V8 engine and Node.js environment for iOS, is entirely thanks to their work.

### nodejs-mobile License
`nodejs-mobile` is distributed under the MIT license, with Node.js and its dependencies carrying their respective licenses. 
For the full license text, please refer to the [nodejs-mobile LICENSE on GitHub](https://github.com/nodejs-mobile/nodejs-mobile/blob/main/LICENSE).
