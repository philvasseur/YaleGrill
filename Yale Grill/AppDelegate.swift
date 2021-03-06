//
//  AppDelegate.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase
import FirebaseRemoteConfig
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var dBaseRef = Database.database().reference()
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
                
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        if(configureError != nil){
            print("We have an error!")
        }
        
        // iOS 10 support
        if #available(iOS 10, *) {
            let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_,_ in })
            
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
            
        } else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        application.registerForRemoteNotifications()
        
        
        
        
        loadMenu()
        loadDefaultValues()
        fetchCloudValues()
                
        return true
    }
    
    func loadDefaultValues() {
        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: false)
        RemoteConfig.remoteConfig().configSettings = remoteConfigSettings!
        RemoteConfig.remoteConfig().setDefaults([
            "READYTIMER" : 12 as NSObject,
            "strikeBanLimit" : 3 as NSObject,
            "banLength" : 10 as NSObject,
            "orderLimit" : 3 as NSObject])
    }
    
    func fetchCloudValues() {
        var expirationDuration = 3600
        if RemoteConfig.remoteConfig().configSettings.isDeveloperModeEnabled {
            expirationDuration = 0
        }
        
        RemoteConfig.remoteConfig().fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                RemoteConfig.remoteConfig().activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(error!.localizedDescription)")
            }
            Constants.READYTIMER = Double(truncating: RemoteConfig.remoteConfig().configValue(forKey: "READYTIMER").numberValue!)
            Constants.strikeBanLimit = Int(truncating: RemoteConfig.remoteConfig().configValue(forKey: "strikeBanLimit").numberValue!)
            Constants.banLength = Int(truncating: RemoteConfig.remoteConfig().configValue(forKey: "banLength").numberValue!)
            Constants.orderLimit = Int(truncating: RemoteConfig.remoteConfig().configValue(forKey: "orderLimit").numberValue!)
        }
    }
    
    func loadMenu() {
        Constants.menuItems = [:]
        let menuRef = Database.database().reference().child("Menu")
        menuRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let json = snapshot.value as? [Any] ?? []
            for menuItemjson in json {
                let newMenuItem = MenuItem(json: menuItemjson as? [String : AnyObject] ?? [:])
                Constants.menuItems[newMenuItem.title] = newMenuItem
            }
        })
        menuRef.keepSynced(true)
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
}
extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("refresh")
    }

    func application(received remoteMessage: MessagingRemoteMessage) {
        print("%@ Data Message: ", remoteMessage.appData)
    }
}
