//
//  AppDelegate.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        AuthService.sharedInstance.setupGoogle()
        
        MusicService.sharedInstance.setupSpotify()
        MusicService.sharedInstance.setupAppleMusic()

        let backgroundImage = UIImage(named: "launch-bg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        
        UINavigationBar.appearance().setBackgroundImage(backgroundImage, for: .default)
       
        let storyboard = UIStoryboard(name: "RecFeed", bundle: nil)

        if Auth.auth().currentUser != nil {
            // Reauthenticate!
            print(Auth.auth().currentUser?.email)
            
            if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
                // 2
                print(notification)
                UserDefaults.standard.set(notification["uid"], forKey: "notifyUID");
                UserDefaults.standard.synchronize()
            }

            window?.rootViewController = storyboard.instantiateInitialViewController()
        }
    
        registerForPushNotifications()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        // Handle callback from spotify with acess token
        if url.absoluteString.contains("spotify") {
            MusicService.sharedInstance.spotifyAuth.handleAuthCallback(withTriggeredAuthURL: url) { (error, session) in
                if let error = error {
                    print(error.localizedDescription)
                } else if session != nil {
                    MusicService.sharedInstance.spotifyPlayer.login(withAccessToken: MusicService.sharedInstance.spotifyAuth.session.accessToken)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SpotifyLoggedIn"), object: nil)
                    MusicService.sharedInstance.checkIfSpotifyPlaylistExists { (exists) in
                        if !exists {
                            MusicService.sharedInstance.createSpotifyPlaylist(success: {
                                print("Hello")
                            }, failure: { (error) in
                                print(error.localizedDescription)
                            })
                        }
                    }
                }
            }
            
            return true
        }
        
        // Handle google login
        return GIDSignIn.sharedInstance().handle(url,
                sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                annotation: [:])
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        if let user = Auth.auth().currentUser {
            DataService.sharedInstance.setNotificationToken(uid: user.uid, token: token, success: {
                print("Set token in database")
            }, failure: { (error) in
                print(error.localizedDescription)
            })
        }
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.sync {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
        }
    }
    
}

