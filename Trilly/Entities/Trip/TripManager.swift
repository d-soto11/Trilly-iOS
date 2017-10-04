//
//  TripManager.swift
//  Trilly
//
//  Created by Daniel Soto on 10/3/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import GoogleMaps
import CoreLocation
import CoreMotion

class TripManager: NSObject, CLLocationManagerDelegate {
    
    // Location
    private var locationManager: CLLocationManager!
    private(set) public var location: CLLocationCoordinate2D?
    // Motion
    private var motionManager: CMMotionManager!
    private var motionActivityManager: CMMotionActivityManager!
    private var acceleration: CMAcceleration?
    // Trip
    private var speed: Double = 0
    private var time: Int = 0
    private var hashTag: String = ""
    // Path
    private(set) public var trackingPath: GMSMutablePath! = GMSMutablePath()
    // Logic
    private var onForeground: Bool = true
    private var timer: Timer?
    private var initialLocationTimer: Timer?
    private var shakingTimer: Timer?
    private var shaking: Bool = true
    private var deferringUpdates: Bool = false
    private var hardwareAvailable: Bool = false
    private var queue: OperationQueue = OperationQueue()
    // Verification
    private var slowMovementTimer: Timer?
    private var fastMovementTimer: Timer?
    private var slowMovementInterval = 30.0
    private var fastMovementInterval = 30.0
    // Listener
    private var tripListener: TripListener?
    // Singleton
    private(set) public static var current: TripManager?
    private static let footSpeed = 8.0
    private static let bycicleSpeed = 40.0
    private static let maximumAcceleration = 5.0
    // Encoded
    private static var encodedGMSPath: String?
    private static var lastHashtag: String?
    private static var time: Int?
    // Start
    public class func start(_ listener: TripListener?) {
        guard current == nil else {
            print("Trip is already in progress!!!!")
            return
        }
        current = TripManager()
        current!.load()
        current!.tripListener = listener
    }
    // Resume
    public class func resume(_ listener: TripListener?) {
        guard current == nil else {
            print("Trip is already in progress!!!!")
            return
        }
        guard encodedGMSPath != nil, time != nil, lastHashtag != nil else {
            print("There is no encoded data to resume")
            return
        }
        current = TripManager()
        current!.trackingPath = GMSMutablePath(fromEncodedPath: encodedGMSPath!)
        current!.time = time!
        current!.hashTag = lastHashtag!
        current!.load()
        current!.tripListener = listener
        encodedGMSPath = nil
        time = nil
        lastHashtag = nil
    }
    // Clear
    public class func clear() {
        current = nil
        encodedGMSPath = nil
    }
    // Stop
    public func stop() {
        self.pause()
        // Save route to firebase
        TripManager.current = nil
    }
    // Pause
    public func pause() {
        shakingTimer?.invalidate()
        shakingTimer = nil
        timer?.invalidate()
        timer = nil
        initialLocationTimer?.invalidate()
        initialLocationTimer = nil
        stopVerifiers()
        locationManager!.stopUpdatingHeading()
        locationManager!.stopUpdatingLocation()
        motionActivityManager!.stopActivityUpdates()
        motionManager!.stopAccelerometerUpdates()
        TripManager.encodedGMSPath = self.trackingPath.encodedPath()
        TripManager.time = time
        TripManager.lastHashtag = hashTag
        TripManager.current = nil
    }
    
    // Load
    private func load() {
        self.initialLocationTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector:  #selector(noLocation), userInfo: nil, repeats: false)
        self.shakingTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(verifyShaking), userInfo: nil, repeats: true)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        
        // Start Location
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.delegate = self;
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .fitness
        hardwareAvailable = CLLocationManager.deferredLocationUpdatesAvailable()
        
        // Start Motion
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 120
        motionManager.startAccelerometerUpdates(to: queue) { (data, error) in
            if error != nil {
                DispatchQueue.main.async {
                    print("Error in accelerometer")
                }
            } else {
                self.acceleration = data?.acceleration
                if !CMMotionActivityManager.isActivityAvailable() {
                    self.updateTripMotion()
                }
            }
        }
        // Start Activity
        motionActivityManager = CMMotionActivityManager()
        motionActivityManager!.startActivityUpdates(to: queue) { (activity) in
            if activity == nil {
                DispatchQueue.main.async {
                    print("Error in activity")
                }
            } else {
                if activity!.cycling {
                    if activity?.confidence == .high {
                        self.stopVerifiers()
                    } else {
                        self.updateTripMotion()
                    }
                } else {
                    if activity!.walking || activity!.running || activity!.stationary {
                        if self.slowMovementTimer == nil {
                            self.slowMovementTimer = Timer.scheduledTimer(timeInterval: self.slowMovementInterval, target: self, selector: #selector(self.verifySlowMovement), userInfo: nil, repeats: false)
                        }
                    } else if activity!.automotive || activity!.unknown {
                        if self.fastMovementTimer == nil {
                            self.fastMovementTimer = Timer.scheduledTimer(timeInterval: self.fastMovementInterval, target: self, selector: #selector(self.verifyFastMovement), userInfo: nil, repeats: false)
                        }
                    }
                }
            }
        }
        
        // Request permission
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        } else {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    
    // Trip logic
    @objc public func tick() {
        if (time % 60 == 0 || hashTag == "") && location != nil {
            GMSGeocoder().reverseGeocodeCoordinate(location!, completionHandler: { (response, error) in
                if error != nil {
                    print("Error getting hashtag from MAPS")
                } else {
                    if let address = response?.firstResult() {
                        DispatchQueue.main.async {
                            self.tripListener?.hashtagUpdated(address.subLocality ?? address.locality ?? address.administrativeArea ?? address.country ?? "trilly")
                        }
                    } else {
                        print("Error getting hashtag from MAPS")
                    }
                    
                }
            })
        }
        time = time + 1
        DispatchQueue.main.async {
            self.tripListener?.timeTick(self.time)
        }
    }
    
    private func updateTripMotion() {
        if speed < TripManager.footSpeed {
            if slowMovementTimer == nil {
                slowMovementTimer = Timer.scheduledTimer(timeInterval: slowMovementInterval, target: self, selector: #selector(verifySlowMovement), userInfo: nil, repeats: false)
            }
        } else if speed < TripManager.bycicleSpeed {
            stopVerifiers()
        } else {
            if fastMovementTimer == nil {
                fastMovementTimer = Timer.scheduledTimer(timeInterval: fastMovementInterval, target: self, selector: #selector(verifyFastMovement), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc public func verifySlowMovement() {
        print("Verifing slow")
        let intents = slowMovementInterval / 30
        if intents >= 10 {
            if onForeground {
                self.tripListener?.tripStoped(message: "Hemos detectado que has parado tu rodada. Puedes terminar tu viaje o continuarlo si ya estás listo para seguir pedaleando.", path: self.trackingPath)
            } else {
                // Guardar notificación para el background
            }
            self.pause()
        } else {
            slowMovementInterval = slowMovementInterval + 30
            slowMovementTimer = Timer.scheduledTimer(timeInterval: slowMovementInterval, target: self, selector: #selector(verifySlowMovement), userInfo: nil, repeats: false)
        }
    }
    
    @objc public func verifyFastMovement() {
        print("Verifing fast")
        let intents = fastMovementInterval / 30
        if intents >= 10 {
            if onForeground {
                self.tripListener?.tripStoped(message: "Hemos detectado que vas muy rápido, posiblemente en un medio de transporte diferente a la bicicleta. Debemos parar tu viaje porque Trilly está diseñado para bicicletas, pero hemos guardado los pedalazos que diste antes.", path: self.trackingPath)
            } else {
                // Guardar notificación para el background
            }
            self.stop()
        } else {
            fastMovementInterval  = fastMovementInterval + 30
            fastMovementTimer = Timer.scheduledTimer(timeInterval: fastMovementInterval, target: self, selector: #selector(verifyFastMovement), userInfo: nil, repeats: false)
        }
    }
    
    // Helper
    private func stopVerifiers() {
        if slowMovementTimer != nil {
            slowMovementTimer?.invalidate()
            slowMovementTimer = nil
        }
        if fastMovementTimer != nil {
            fastMovementTimer?.invalidate()
            fastMovementTimer = nil
        }
        slowMovementInterval = 30
        fastMovementInterval = 30
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if initialLocationTimer != nil {
            initialLocationTimer!.invalidate()
            initialLocationTimer = nil
        }
        
        if trackingPath.count() == 1 {
            trackingPath.removeAllCoordinates()
            trackingPath.add(locations.last!.coordinate)
        }
        
        trackingPath.add(locations.last!.coordinate)
        self.location = locations.last!.coordinate
        self.speed = locations.last!.speed < 0 ? 0 : locations.last!.speed
        if onForeground && tripListener != nil {
            DispatchQueue.main.async {
                self.tripListener!.tripUpdated(path: self.trackingPath)
            }
        }
        updateTripMotion()
        if hardwareAvailable {
            if (!deferringUpdates) {
                locationManager.allowDeferredLocationUpdates(untilTraveled: 100, timeout: 120)
                deferringUpdates = true;
            }
        } else {
            // Use custom method to defer updates
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if onForeground {
            DispatchQueue.main.async {
                self.tripListener?.headingUpdated(heading: newHeading.trueHeading)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        self.deferringUpdates = false
    }
    
    // Background controllers
    public func startBackground() {
        onForeground = false
    }
    
    public func stopBackground() {
        onForeground = true
    }
    
    // Listener methods
    public func registerTripListener(_ listener: TripListener) {
        self.tripListener = listener
    }
    
    public func clearTripListener() {
        self.tripListener = nil
    }
    
    @objc public func noLocation() {
        DispatchQueue.main.async {
            self.tripListener?.noLocation()
        }
    }
    
    // Shaking detection
    var shakeData: [CMAcceleration]?
    //Counter for calculating completion of one second interval
    var shakeTestInterval: Double = 0.0
    
    @objc public func verifyShaking() {
        guard acceleration != nil else {
            print("No Accelerometer data")
            return
        }
        print("Verifiyng acc")
        shakeTestInterval += 0.01
        if (shakeTestInterval < 1.0) {
            if shakeData == nil {
                shakeData = []
            }
            let acc = CMAcceleration(x: acceleration!.x, y: acceleration!.y, z: acceleration!.z)
            shakeData!.append(acc)
        } else {
            var count = 0
            for acc in shakeData! {
                let accX_2 = acc.x * acc.x
                let accY_2 = acc.y * acc.y
                let accZ_2 = acc.z * acc.z
                let v = sqrt(accX_2 + accY_2 + accZ_2)
                if (v >= TripManager.maximumAcceleration) {
                    count = count + 1
                }
            }
            self.shaking = count > 0
            shakeData = nil
            shakeTestInterval = 0.0
        }
    }
}

protocol TripListener {
    func tripUpdated(path: GMSPath)
    func headingUpdated(heading: CLLocationDirection)
    func noLocation()
    func tripStoped(message: String, path: GMSPath)
    func tripPaused(message: String, path: GMSPath)
    func timeTick(_ time: Int)
    func hashtagUpdated(_ hashtag: String)
}