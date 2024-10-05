 //
 //  Copyright (C) 2018 Kenneth H. Cox
 //
 //  This program is free software; you can redistribute it and/or
 //  modify it under the terms of the GNU General Public License
 //  as published by the Free Software Foundation; either version 2
 //  of the License, or (at your option) any later version.
 //
 //  This program is distributed in the hope that it will be useful,
 //  but WITHOUT ANY WARRANTY; without even the implied warranty of
 //  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 //  GNU General Public License for more details.
 //
 //  You should have received a copy of the GNU General Public License
 //  along with this program; if not, write to the Free Software
 //  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation
import UIKit
import CoreText
#if USE_FCM
import FirebaseCore
import FirebaseMessaging
#elseif USE_FA
import FirebaseCore
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        App.updateLaunchCount()
        App.theme = AppFactory.makeTheme()
        App.config = AppFactory.makeAppConfiguration()
        App.library = Library(App.config.url)
        App.behavior = AppFactory.makeBehavior()

        let appearance = UINavigationBar.appearance()
        appearance.tintColor = UIColor.white
        appearance.barTintColor = App.theme.barBackgroundColor
        appearance.backgroundColor = App.theme.barBackgroundColor
        appearance.isTranslucent = false
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

#if USE_FCM
        FirebaseApp.configure()
        setupFirebaseCloudMessaging(application)

        // If the app was started by tapping a remoteNotification, stash it now
        if let remoteNotification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification],
           let userInfo = remoteNotification as? [AnyHashable: Any]
        {
            let pn = PushNotification(userInfo: userInfo)
            pn.tag = "launchOptions"
            App.launchNotificationUserInfo = pn.userInfo
        }
#elseif USE_FA
        FirebaseApp.configure()
#endif

        return true
    }

#if USE_FCM
    private func notificationOptions() -> UNNotificationPresentationOptions {
        if #available(iOS 14.0, *) {
            return [[.banner]]
        } else {
            return [[.alert]]
        }
    }

    private func authorizationOptions() -> UNAuthorizationOptions {
        return [.alert, .badge]
    }

    private func messageID(_ userInfo: [AnyHashable: Any]) -> String {
        return userInfo[PushNotification.gcmMessageIDKey] as? String ?? "na"
    }

    private func setupFirebaseCloudMessaging(_ application: UIApplication) {
        Messaging.messaging().delegate = self

        //TODO: move this request to later, e.g. when placing a hold
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: authorizationOptions(), completionHandler: { allowed, _ in
            print("[fcm] allowed is \(allowed)")
        })

        application.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        let pn = PushNotification(userInfo: userInfo)
        pn.tag = "didReceiveRemoteNotification(1)"
        print("[fcm] didReceiveRemoteNotification: \(pn)")
        notifyListeners(pn.userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        let pn = PushNotification(userInfo: userInfo)
        pn.tag = "didReceiveRemoteNotification(2)"
        print("[fcm] didReceiveRemoteNotification: \(pn)")
        notifyListeners(pn.userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }

    private func notifyListeners(_ userInfo: [AnyHashable: Any]) {
        let pn = PushNotification(userInfo: userInfo)
        print("[fcm] notifyListeners: \(pn)")

        NotificationCenter.default.post(
            name: Notification.Name("FCMNotification"),
            object: nil,
            userInfo: userInfo
        )
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[fcm] Unable to register for remote notifications: \(error.localizedDescription)")
    }
#endif
}

#if USE_FCM
extension AppDelegate: UNUserNotificationCenterDelegate {
    /// called by the system when the app receives a notification while running (fg or bg), to decide how to present it
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let pn = PushNotification(userInfo: notification.request.content.userInfo)
        print("[fcm] willPresent: \(pn)")
        completionHandler(notificationOptions())
    }

    /// called by the system when a notification is tapped while the app is running (fg or bg)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let pn = PushNotification(userInfo: response.notification.request.content.userInfo)
        pn.tag = "didReceive"
        print("[fcm] didReceive: \(pn)")
        notifyListeners(pn.userInfo)
        completionHandler()
    }
}
#endif

#if USE_FCM
extension AppDelegate: MessagingDelegate {
    /// called by FCM when the notification token is available
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("[fcm] got fcm token: \(fcmToken ?? "(nil)")")
        App.fcmNotificationToken = fcmToken
    }
}
#endif
