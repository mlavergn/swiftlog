/// App struct with package or bundle related helpers
///
/// -todo:
/// Ideally this would leverage the unified logging system but
/// it appears to be broken in 3.0.2
///
/// if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
///	  logInstance = OSLog(subsystem:subsystem, category:category)
///	  os_log("demo", log:logInstance, type:.error)
/// }
///
/// - author: Marc Lavergne <mlavergn@gmail.com>
/// - copyright: 2017 Marc Lavergne. All rights reserved.
/// - license: MIT

import Foundation

#if os(Linux)
import Glibc
#else
import os.log
import Darwin
#endif

/// Log levels
///
/// - ALL: No filtering of log messages
/// - DEBUG: Debug level or more severe
/// - INFO: Info level or more severe
/// - WARN: Warn level or more severe
/// - ERROR: Error level or more severe
/// - FATAL: Fatal level or more severe
/// - OFF: No log messages
public enum LogLevel: Int {
	case ALL = 0
	case DEBUG
	case INFO
	case WARN
	case ERROR
	case FATAL
	case OFF
}

/// Log destination
///
/// - STDOUT: Console output
/// - STDERR: Error log and console
/// - FILE: File output
/// - SYSTEM: System log output
public enum LogDestination: Int {
	case STDOUT = 0
	case STDERR
	case FILE
	case SYSTEM
}

public struct Log {

	/// Filter level
	public static var logLevel: LogLevel = LogLevel.WARN
	/// Log destination
	public static var logDestination: LogDestination = LogDestination.STDOUT

	/// os_log logger
	public static var logger: OSLog?

	/// Timer singleton for performance measurement
	public static var timeMark: DispatchTime?

	/// Configure the logger
	///
	/// - Parameters:
	///   - level: Filter level for output
	///   - destination: Log destination
	public static func configure(level: LogLevel, destination: LogDestination = .STDOUT, _ subssystem: String? = Bundle.main.bundleIdentifier, _ category: String? = nil) {
		logLevel = level
		logDestination = destination

		// experimental support for os_log
		if #available(macOS 10.12, *) {
			if destination == .SYSTEM {
				if subssystem != nil && category != nil {
					logger = OSLog(subsystem: subssystem!, category: category!)
				}
			}
		} else {
			// send out back to STDOUT
			logDestination = .STDOUT
		}
	}

	/// Read logger environment variables and adjust settings
	public static func readEnv() {
		// (todo) this should be read via a timer
		if let value = ProcessInfo.processInfo.environment["LOG_LEVEL"] {
			if let valInt = Int(value) {
				if let valLogLevel = LogLevel(rawValue: valInt) {
					logLevel = valLogLevel
				}
			}
		}

		if let value = ProcessInfo.processInfo.environment["LOG_DEST"] {
			if let valInt = Int(value) {
				if let valLogDestination = LogDestination(rawValue: valInt) {
					logDestination = valLogDestination
				}
			}
		}
	}

	public static var pathURL: URL {
		if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
		#if os(iOS) || os(tvOS)
			var pathURL = URL(fileURLWithPath: NSHomeDirectory())
		#else
			var pathURL = FileManager.default.homeDirectoryForCurrentUser
		#endif
			pathURL = pathURL.appendingPathComponent("log/swift")

			do {
				try FileManager.default.createDirectory(atPath: pathURL.path, withIntermediateDirectories: true, attributes: nil)
			} catch let error as NSError {
				fputs("\(Date.timeIntervalSinceReferenceDate) Log.pathURL failed: \(error)\n", __stderrp)
			}

			return pathURL
		} else {
			return URL(fileURLWithPath: "/tmp")
		}
	}

	@inline(__always) public static func logLevelToOSLogType(level: LogLevel) -> OSLogType {
		if #available(macOS 10.12, *) {
			var oslogType: OSLogType = .debug
			switch level {
			case .DEBUG:
				oslogType = .debug
			case .INFO:
				oslogType = .info
			case .WARN:
				oslogType = .default
			case .ERROR:
				oslogType = .error
			case .FATAL:
				oslogType = .fault
			default:
				oslogType = .debug
			}

			return oslogType
		}

		return OSLogType(0)
	}

	/// Outputs a log message to the set destination
	///
	/// - Parameter message: description as a String
	@inline(__always) public static func output(level: LogLevel, file: String, function: String, line: Int, message: String) {
		let fileName = (file as NSString).lastPathComponent

		switch logDestination {
		case .STDOUT:
			fputs("\(Date.timeIntervalSinceReferenceDate) [\(fileName).\(function):\(line)] \(message)\n", __stdoutp)
		case .STDERR:
			fputs("\(Date.timeIntervalSinceReferenceDate) [\(fileName).\(function):\(line)] \(message)\n", __stderrp)
		case .SYSTEM:
			if #available(macOS 10.12, *) {
				let oslogType = logLevelToOSLogType(level: level)
				os_log("[%{public}@.%{public}@:%{public}d] %{public}@", log: logger ?? .default, type: oslogType, fileName, function, line, message)
			}
		case .FILE:
			do {
				try "\(Date.timeIntervalSinceReferenceDate) [\(fileName).\(function):\(line)] \(message)\n".write(to: pathURL, atomically: false, encoding: String.Encoding.utf8)
			} catch let error as NSError {
				fputs("\(Date.timeIntervalSinceReferenceDate) file write failed [\(fileName).\(function):\(line)] \(error)\n", __stderrp)
			}
		}
	}

	/// Debug level log message
	///
	/// - Parameter message: description as a String optional
 	@inline(__always) public static func debug(_ message: String?, file: String = #file, function: String = #function, line: Int = #line) {
		if logLevel.rawValue <= LogLevel.DEBUG.rawValue {
			if let message = message {
				output(level: .DEBUG, file: file, function: function, line: line, message: message)
			} else {
				output(level: .DEBUG, file: file, function: function, line: line, message: "<empty optional>")
			}
		}
	}

	/// Debug level log message
	///
	/// - Parameter object: Any optional to print as a debug string
	@inline(__always) public static func debug(_ object: Any?, file: String = #file, function: String = #function, line: Int = #line) {
		if logLevel.rawValue <= LogLevel.DEBUG.rawValue {
			if let object = object as AnyObject? {
				output(level: .DEBUG, file: file, function: function, line: line, message: object.debugDescription)
			} else {
				output(level: .DEBUG, file: file, function: function, line: line, message: "<empty optional>")
			}
		}
	}

	/// Information level log message
	///
	/// - Parameter message: description as a String
	@inline(__always) public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
		if logLevel.rawValue <= LogLevel.INFO.rawValue {
			output(level: .INFO, file: file, function: function, line: line, message: message)
		}
	}

	/// Warning level log message
	///
	/// - Parameter message: description as a String
	@inline(__always) public static func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
		if logLevel.rawValue <= LogLevel.WARN.rawValue {
			output(level: .WARN, file: file, function: function, line: line, message: message)
		}
	}

    /// Warning level log message
    ///
    /// - Parameter error: Error object
    @inline(__always) public static func warn(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        if logLevel.rawValue <= LogLevel.WARN.rawValue {
			output(level: .WARN, file: file, function: function, line: line, message: String(describing: error))
        }
    }

	/// Error level log message
	///
	/// - Parameter message: description as a String
	static public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
		if logLevel.rawValue <= LogLevel.ERROR.rawValue {
			output(level: .ERROR, file: file, function: function, line: line, message: message)
		}
	}

	/// Error level log message
	///
	/// - Parameter error: Error object
	static public func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
		if logLevel.rawValue <= LogLevel.ERROR.rawValue {
			output(level: .ERROR, file: file, function: function, line: line, message: String(describing: error))
		}
	}

	/// Fatal level log message
	///
	/// - Parameter message: description as a String
	static public func fatal(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
		output(level: .FATAL, file: file, function: function, line: line, message: message)
	}

	/// Outputs the file, function, and line stamp to stdout
	///
	/// - Parameters:
	///   - function: function name as a String (should not be provided)
	///   - file: file name as a String (should not be provided)
	///   - line: line as an Int (should not be provided)
	@inline(__always) public static func stamp(file: String = #file, function: String = #function, line: Int = #line) {
		if logLevel.rawValue <= LogLevel.DEBUG.rawValue {
			 output(level: .DEBUG, file: file, function: function, line: line, message: "<empty optional>")
		}
	}

	/// Saves the content String to file at $HOME/log/swift/<epoch>.log
	///
	/// - Parameter message: output as a String
	public static func dumpFile(output: String) {
		if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
			#if os(iOS) || os(tvOS)
	 			var pathURL = URL(fileURLWithPath: NSHomeDirectory())
	 		#else
	 			var pathURL = FileManager.default.homeDirectoryForCurrentUser
	 		#endif
			pathURL = pathURL.appendingPathComponent("log/swift")
			do {
				try FileManager.default.createDirectory(atPath: pathURL.path, withIntermediateDirectories: true, attributes: nil)
				let epoch = NSDate().timeIntervalSince1970
				pathURL = pathURL.appendingPathComponent("\(epoch).log")
				try output.write(to: pathURL, atomically: false, encoding: String.Encoding.utf8)
			} catch let error as NSError {
				print(error)
			}
		}
	}

	/// Resets the elapsed time marker to being a new measurement
	public static var timerMark: Void {
		timeMark = DispatchTime.now()
	}

	/// Measures the elapsed time since the last mark in milliseconds
	public static var timerMeasure: Void {
		if let timeMark = timeMark {
			let timeInterval = Double(DispatchTime.now().uptimeNanoseconds - timeMark.uptimeNanoseconds) / 1_000_000
			output(level: .DEBUG, file: "", function: "", line: -1, message: "ELAPSED [\(timeInterval)]ms")
		}
	}
}
