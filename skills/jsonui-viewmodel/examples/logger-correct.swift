// ✅ CORRECT - use Logger for debug output
import SwiftJsonUI

Logger.debug("Debug message: \(value)")  // Only outputs in DEBUG builds
Logger.log("Always logged message")       // Always outputs
