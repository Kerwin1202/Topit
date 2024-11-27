//
//  SettingsView.swift
//  Topit
//
//  Created by apple on 2024/11/19.
//

import SwiftUI
import KeyboardShortcuts
import ServiceManagement

struct SettingsView: View {
    @State private var selectedItem: String? = "General"
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                NavigationLink(destination: GeneralView(), tag: "General", selection: $selectedItem) {
                    Label("General", image: "gear")
                }
                NavigationLink(destination: WindowView(), tag: "Window", selection: $selectedItem) {
                    Label("Windows", image: "window")
                }
                NavigationLink(destination: HotkeyView(), tag: "Hotkey", selection: $selectedItem) {
                    Label("Hotkey", image: "hotkey")
                }
                NavigationLink(destination: FilterView(), tag: "Filter", selection: $selectedItem) {
                    Label("App Filter", image: "block")
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 9)
        }
        .frame(width: 600, height: 400)
        .navigationTitle("Topit Settings")
    }
}

struct GeneralView: View {
    @AppStorage("showOnDock") private var showOnDock: Bool = true
    @AppStorage("showMenubar") private var showMenubar: Bool = true
    
    @State private var launchAtLogin = false
    
    var body: some View {
        SForm {
            SGroupBox(label: "General") {
                if #available(macOS 13, *) {
                    SToggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            }catch{
                                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                            }
                        }
                    SDivider()
                }
                SToggle("Show Topit on Dock", isOn: $showOnDock)
                SDivider()
                SToggle("Show Topit on Menu Bar", isOn: $showMenubar)
            }
            SGroupBox(label: "Update") {
                UpdaterSettingsView(updater: updaterController.updater)
            }
            VStack(spacing: 8) {
                CheckForUpdatesView(updater: updaterController.updater)
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Topit v\(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear{ if #available(macOS 13, *) { launchAtLogin = (SMAppService.mainApp.status == .enabled) }}
        .onChange(of: showMenubar) { newValue in statusBarItem.isVisible = newValue }
        .onChange(of: showOnDock) { newValue in
            if !newValue {
                NSApp.setActivationPolicy(.accessory)
                closeMainWindow()
            } else { NSApp.setActivationPolicy(.regular) }
        }
    }
}

struct WindowView: View {
    @AppStorage("showCloseButton") private var showCloseButton: Bool = true
    @AppStorage("showUnpinButton") private var showUnpinButton: Bool = true
    @AppStorage("showPauseButton") private var showPauseButton: Bool = true
    @AppStorage("splitButtons") private var splitButtons: Bool = false
    @AppStorage("buttonPosition") private var buttonPosition: Int = 0
    @AppStorage("fullScreenFloating") private var fullScreenFloating: Bool = true
    @AppStorage("mouseOverAction") private var mouseOverAction: Bool = true
    @AppStorage("maxFps") private var maxFps: Int = 65535
    
    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Windows") {
                SPicker("Activate Pinned Window on", selection: $mouseOverAction,
                        tips: "When you select \"Left Click\" as the way to activate a window, you need to activate the window before moving it.") {
                    Text("Cursor Hover").tag(true)
                    Text("Left Click").tag(false)
                }
                SDivider()
                SPicker("Maximum Refresh Rate", selection: $maxFps) {
                    Text("30 Hz").tag(30)
                    Text("60 Hz").tag(60)
                    Text("120 Hz").tag(120)
                    Text("No Limit").tag(65535)
                }
                SDivider()
                SToggle("On Top of Full-screen App", isOn: $fullScreenFloating)
            }
            SGroupBox {
                SPicker("Control Button Position", selection: $buttonPosition) {
                    Text("Top Leading").tag(0)
                    Text("Top Trailing").tag(2)
                    Text("Bottom Leading").tag(1)
                    Text("Bottom Trailing").tag(3)
                }
                SDivider()
                if #available(macOS 13, *) {
                    SPicker("Control Button Style", selection: $splitButtons) {
                        Text("Badge").tag(false)
                        Text("Classic").tag(true)
                    }
                    if splitButtons {
                        SDivider()
                        SToggle("Show Close Button", isOn: $showCloseButton)
                        SDivider()
                        SToggle("Show Pause Button", isOn: $showPauseButton)
                        SDivider()
                        SToggle("Show Unpin Button", isOn: $showUnpinButton)
                    }
                } else {
                    SToggle("Show Close Button", isOn: $showCloseButton)
                    SDivider()
                    SToggle("Show Pause Button", isOn: $showPauseButton)
                    SDivider()
                    SToggle("Show Unpin Button", isOn: $showUnpinButton)
                }
            }
        }
    }
}

struct HotkeyView: View {
    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Hotkey") {
                SItem(label: "Select a Window to Pin") {
                    KeyboardShortcuts.Recorder("", name: .selectWindow)
                }
                SDivider()
                SItem(label: "Open Window Selector"){
                    KeyboardShortcuts.Recorder("", name: .openMainPanel)
                }
            }
            SGroupBox {
                SItem(label: "Pin / Unpin Under-mouse Window") {
                    KeyboardShortcuts.Recorder("", name: .pinUnpin)
                }
                SDivider()
                SItem(label: "Unpin All Pinned Windows"){
                    KeyboardShortcuts.Recorder("", name: .unpinAll)
                }
            }
        }
    }
}

struct FilterView: View {
    @AppStorage("noTitle") var noTitle = true
    
    var body: some View {
        SForm(spacing: 10, noSpacer: true) {
            SGroupBox(label: "App Filter") {
                SToggle("Show Windows with No Title", isOn: $noTitle)
            }
            SGroupBox {
                BundleSelector()
            }
        }
    }
}

extension KeyboardShortcuts.Name {
    static let selectWindow = Self("selectWindow")
    static let openMainPanel = Self("openMainPanel")
    static let pinUnpin = Self("pinUnpin")
    static let unpinAll = Self("unpinAll")
}
