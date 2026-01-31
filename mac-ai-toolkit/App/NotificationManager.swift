//
//  NotificationManager.swift
//  mac-ai-toolkit
//
//  System notification manager
//  Created on 2026-01-31
//

import Foundation
import UserNotifications

/// 通知管理器
///
/// 管理系统通知和应用内通知
@MainActor
final class NotificationManager: NSObject, ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = NotificationManager()
    
    // MARK: - Private Properties
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("通知权限请求失败: \(error)")
            return false
        }
    }
    
    /// 发送通知
    func sendNotification(
        title: String,
        body: String,
        identifier: String = UUID().uuidString,
        delay: TimeInterval = 0
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("发送通知失败: \(error)")
        }
    }
    
    /// 发送成功通知
    func notifySuccess(title: String, message: String) async {
        await sendNotification(title: title, body: message)
    }
    
    /// 发送错误通知
    func notifyError(title: String, message: String) async {
        await sendNotification(title: "❌ " + title, body: message)
    }
    
    /// 移除所有通知
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // 处理用户点击通知
        print("用户点击了通知: \(response.notification.request.identifier)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    // OCR
    static let screenshotOCR = Notification.Name("screenshotOCR")
    static let clipboardOCR = Notification.Name("clipboardOCR")
    
    // TTS
    static let quickTTS = Notification.Name("quickTTS")
    
    // STT
    static let quickSTT = Notification.Name("quickSTT")
    
    // Window
    static let openMainWindow = Notification.Name("openMainWindow")
    
    // Settings
    static let settingsDidChange = Notification.Name("settingsDidChange")
    
    // History
    static let historyDidUpdate = Notification.Name("historyDidUpdate")
}
