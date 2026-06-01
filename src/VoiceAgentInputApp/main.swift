import AppKit

let debugLogger = AppDebugLogger()
debugLogger.log("main started")

let app = NSApplication.shared
if CommandLine.arguments.contains("--ui-layout-smoke") {
    exit(AppUILayoutSmoke.run())
}

let delegate = VoiceAgentInputApp()
app.delegate = delegate
app.run()
