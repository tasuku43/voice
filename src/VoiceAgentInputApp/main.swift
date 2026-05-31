import AppKit

let debugLogger = AppDebugLogger()
debugLogger.log("main started")

let app = NSApplication.shared
let delegate = VoiceAgentInputApp()
app.delegate = delegate
app.run()
