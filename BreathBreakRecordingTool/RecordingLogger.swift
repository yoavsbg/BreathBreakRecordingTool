//
//  RecordingLogger.swift
//  BreathBreakRecordingTool
//
//  Created by Yoav Ss on 30/10/2025.
//

import SwiftUI
import Combine

class RecordingLogger: ObservableObject {
    @Published var logs: [LogEntry] = []
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: LogType
        
        enum LogType {
            case info
            case success
            case error
            case progress
            
            var icon: String {
                switch self {
                case .info: return "ℹ️"
                case .success: return "✅"
                case .error: return "❌"
                case .progress: return "⏳"
                }
            }
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .success: return .green
                case .error: return .red
                case .progress: return .orange
                }
            }
        }
        
        var formattedMessage: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return "\(formatter.string(from: timestamp)) \(type.icon) \(message)"
        }
    }
    
    func log(_ message: String, type: LogEntry.LogType = .info) {
        DispatchQueue.main.async {
            self.logs.append(LogEntry(timestamp: Date(), message: message, type: type))
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}
