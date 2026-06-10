import TopToDoCore
import SwiftUI
import AppKit

@main
struct TopToDoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TodoStore()
    @AppStorage("appFontSizeRawValue") private var fontSizeRawValue: String = FontSize.medium.rawValue

    private var fontSize: FontSize {
        FontSize(rawValue: fontSizeRawValue) ?? .medium
    }

    var body: some Scene {
        WindowGroup("TopToDo") {
            TodoListView()
                .environmentObject(store)
                .environment(\.fontScale, fontSize.scale)
                .frame(minWidth: 600, maxWidth: 600, minHeight: 520, idealHeight: 700)
        }
        .defaultSize(width: 600, height: 700)
        .windowResizability(.contentSize)
        .commands {
            // Single-window app: hide the New menu group (New TopToDo Window, New Tab, ...).
            CommandGroup(replacing: .newItem) { }
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Single-window app: drop the Tab Bar and "Show All Tabs" items from the View menu.
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
