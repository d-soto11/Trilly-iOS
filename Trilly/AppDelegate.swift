//
//  AppDelegate.swift
//  Trilly
//
//  Created by Daniel Soto on 9/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD
import FirebaseAuth
import FBSDKCoreKit
import GoogleMaps
import GooglePlaces
import UserNotifications
import Fabric
import Crashlytics
import Modals3A
import MaterialTB

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Configurar Firebase
        FirebaseApp.configure()
        // Configurar Google
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()!.options.clientID
        // Ask location
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        // Configurar Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        // Configuracion de GMaps
        GMSServices.provideAPIKey(Trilly.googleApiKey)
        GMSPlacesClient.provideAPIKey(Trilly.googleApiKey)
        // Configure Modals3A
        Modals3AConfig.foregroundColor = Trilly.UI.mainColor
        Modals3AConfig.fontFamily = "Oxygen"
        Modals3AConfig.titleFontSize = 30
        // Configuracion Stripe
        // STPPaymentConfiguration.shared().publishableKey = K.Hometap.stripe_key
        // Private configurations
        // ...
        // DropDown.startListeningToKeyboard()
        // Crashalytics
        // Fabric.with([Crashlytics.self])
        // New Relic
        // NewRelic.start(withApplicationToken: Trilly.newRelicKey)
        // Notifications configuration
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
        application.applicationIconBadgeNumber = 0
        
        return true
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let handled_by_fb = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        
        let handled_by_google = GIDSignIn.sharedInstance().handle(url,
                                                                  sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                                  annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled_by_fb || handled_by_google
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        TripManager.current?.startBackground()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        TripManager.current?.startBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        TripManager.current?.stopBackground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        TripManager.current?.stopBackground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // K.User.reloadClient()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // K.User.reloadClient()
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        // K.User.client?.saveNotificationToken(token: fcmToken)
    }


}

