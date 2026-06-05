//
//  NodeServerView.swift
//  ringo
//
//  Created by Aarav Gupta on 29/05/26.
//

import SwiftUI
//import UniformTypeIdentifiers
import Network
import UIKit
import Foundation

public struct NodeServerView: View {
    public init() {}
    enum ConnectionMode: String, CaseIterable, Identifiable {
        case wifi = "Wi‑Fi"
        case usb = "USB"
        var id: String { rawValue }
    }

    @State private var connectionMode: ConnectionMode = .wifi
    @State private var baseURL: String = "http://127.0.0.1:3000"
    @State private var endpointPath = "/health"
    @State private var responseText = "Press the button to check /health."
    @State private var isLoading = false
    @State private var wifiAddress: String? = nil
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Connection", selection: $connectionMode) {
                ForEach(ConnectionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: connectionMode) { old, new in
                switch new {
                case .wifi:
                    updateWiFiAddress()
                    if let ip = wifiAddress {
                        baseURL = "http://\(ip):3000"
                    } else {
                        baseURL = "http://127.0.0.1:3000"
                    }
                case .usb:
                    baseURL = "http://127.0.0.1:3000"
                }
            }

            HStack {
                Text("Base URL:")
                TextField("Base URL", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Copy") {
                    UIPasteboard.general.string = baseURL
                }
            }

            if connectionMode == .wifi {
                HStack(spacing: 12) {
                    Text("Wi‑Fi IP:")
                    Text(wifiAddress ?? "(not connected to Wi‑Fi)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Refresh") { updateWiFiAddress(); if let ip = wifiAddress { baseURL = "http://\(ip):3000" } }
                    Button("Use") { if let ip = wifiAddress { baseURL = "http://\(ip):3000" } }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("USB instructions:")
                        .font(.subheadline).bold()
                    Text("On your Mac, install libimobiledevice (Homebrew) and run the forwarding command:")
                        .font(.caption)
                    Text("brew install libimobiledevice && iproxy 3000 3000")
                        .font(.system(.body, design: .monospaced))
                        .padding(6)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)
                    HStack {
                        Button("Copy command") { UIPasteboard.general.string = "brew install libimobiledevice && iproxy 3000 3000" }
                        Spacer()
                        Button("Set base to localhost") { baseURL = "http://127.0.0.1:3000" }
                    }
                }
            }

            Button {
                Task {
                    await loadServerResponse(endpointPath: endpointPath)
                }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Check server health")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Endpoint path:")
                    TextField("/health", text: $endpointPath)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Use /versions") { endpointPath = "/versions" }
                }

                ScrollView {
                    Text(responseText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .onAppear { updateWiFiAddress() }
    }
    
    //MARK: - EVERYTHING NODE
    
    @MainActor
    private func loadServerResponse(endpointPath: String) async {
        isLoading = true
        defer { isLoading = false }

        let normalizedPath = endpointPath.hasPrefix("/") ? endpointPath : "/\(endpointPath)"

        // If the user supplied a full URL in endpointPath, use it directly. Otherwise combine baseURL + path.
        let urlString: String
        if endpointPath.lowercased().hasPrefix("http") {
            urlString = endpointPath
        } else {
            urlString = baseURL + normalizedPath
        }

        guard let url = URL(string: urlString) else {
            responseText = "Invalid local server URL: \(urlString)"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            responseText = String(decoding: data, as: UTF8.self)
        } catch {
            responseText = "Request failed: \(error.localizedDescription)"
        }
    }

    private func updateWiFiAddress() {
        wifiAddress = getWiFiAddress()
    }

    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = firstAddr
        while true {
            let name = String(cString: ptr.pointee.ifa_name)
            if let addrPtr = ptr.pointee.ifa_addr {
                let family = addrPtr.pointee.sa_family
                if name == "en0" && family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addrPtr, socklen_t(MemoryLayout<sockaddr_in>.size), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }

        return address
    }
}

#Preview {
    NodeServerView()
}
