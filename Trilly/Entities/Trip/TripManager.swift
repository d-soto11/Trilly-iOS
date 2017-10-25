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
import RestEssentials
import Firebase

class TripManager: NSObject, CLLocationManagerDelegate {
    
    // Location
    private var locationManager: CLLocationManager!
    private(set) public var location: CLLocationCoordinate2D?
    private var lastLocation: CLLocation?
    private var destination: CLLocationCoordinate2D?
    // Motion
    private var motionManager: CMMotionManager!
    private var motionActivityManager: CMMotionActivityManager!
    private var acceleration: CMAcceleration?
    // Trip
    private var speed: Double = 0
    private var time: Int = 0
    private var hashTag: String = ""
    private var hashTagKM: [String:Double] = [:]
    private var currentKM: Double = 0
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
    private static var hashTagKM: [String:Double]?
    // Queue
    private let backgroundQueue: DispatchQueue = DispatchQueue(label: "com.trilly.tripqueue", qos: .utility)
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
        current!.hashTagKM = hashTagKM!
        current!.load()
        current!.tripListener = listener
        
        encodedGMSPath = nil
        time = nil
        lastHashtag = nil
        hashTagKM = nil
    }
    // Clear
    public class func clear() {
        encodedGMSPath = nil
        time = nil
        lastHashtag = nil
    }
    // Stop
    public func stop() {
        self.pause()
        
        backgroundQueue.async {
            let newTrip = Trip([:])
            if self.destination != nil {
                newTrip.destination = GeoPoint(latitude: self.destination!.latitude, longitude: self.destination!.longitude)
            }
            newTrip.path = self.trackingPath.encodedPath()
            let initial = self.trackingPath.coordinate(at: 0)
            newTrip.start = GeoPoint(latitude: initial.latitude, longitude: initial.longitude)
            newTrip.time = self.time
            newTrip.user = User.current!.reference()
            newTrip.date = NSDate()
            newTrip.filters = ""
            
            let stats = Stats([:])
            stats.km = self.trackingPath.length(of: GMSLengthKind.rhumb)/1000
            stats.cal = Double(11 * self.time)
            stats.co2 = 257 * stats.km!
            newTrip.stats = stats
            newTrip.save()
            
            for (name, km) in self.hashTagKM {
                let hashtag = HashtagInfo([:])
                hashtag.name = name
                hashtag.points = km
                hashtag.uid = name
                hashtag.saveOnTrip(newTrip.uid!)
                let userContribution = UserContribution([:])
                userContribution.km = km
                userContribution.name = User.current!.name!
                userContribution.points = km
                userContribution.uid = User.current!.uid!
                userContribution.saveOnHashtag(name)
                let userHashtag = HashtagPoints([:])
                userHashtag.name = name
                userHashtag.km = km
                userHashtag.points = km
                userHashtag.uid = name
                userHashtag.saveToUser(User.current!.uid!)
                newTrip.filters = "\(newTrip.filters!)-\(name)"
            }
            
            newTrip.save()
            User.current!.addTrip(newTrip)
            Trilly.Database.Local.saveModel(id: Trip.new, object: newTrip)
        }
        
        TripManager.current = nil
        TripManager.encodedGMSPath = nil
        TripManager.time = nil
        TripManager.lastHashtag = nil
        TripManager.hashTagKM = nil
        
        self.locationManager?.stopUpdatingHeading()
        self.locationManager?.stopUpdatingLocation()
        self.locationManager?.delegate = nil
        self.locationManager = nil
        
        self.motionActivityManager?.stopActivityUpdates()
        self.motionActivityManager = nil
        
        self.motionManager?.stopAccelerometerUpdates()
        self.motionManager = nil
    }
    // Pause
    public func pause() {
        clearTripListener()
        self.hashTagKM[self.hashTag] = (self.hashTagKM[self.hashTag] ?? 0) + self.currentKM
        backgroundQueue.async {
            self.shakingTimer?.invalidate()
            self.shakingTimer = nil
            
            self.timer?.invalidate()
            self.timer = nil
            
            self.initialLocationTimer?.invalidate()
            self.initialLocationTimer = nil
            
            self.stopVerifiers()
            
            self.locationManager?.stopUpdatingHeading()
            self.locationManager?.stopUpdatingLocation()
            self.locationManager?.delegate = nil
            self.locationManager = nil
            
            self.motionActivityManager?.stopActivityUpdates()
            self.motionActivityManager = nil
            
            self.motionManager?.stopAccelerometerUpdates()
            self.motionManager = nil
            
            TripManager.encodedGMSPath = self.trackingPath.encodedPath()
            TripManager.time = self.time
            TripManager.lastHashtag = self.hashTag
            TripManager.hashTagKM = self.hashTagKM
            
        }
    }
    
    // Destination handlers
    public func setDestination(_ destination: CLLocationCoordinate2D) {
        self.destination = destination
        guard lastLocation != nil else { return }
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(self.lastLocation!.coordinate.latitude),\(self.lastLocation!.coordinate.longitude)&destination=\(destination.latitude),\(destination.longitude)&mode=walking&key=\(Trilly.googleApiKey)"
        
        print(urlString)
        
        guard let url = RestController.make(urlString: urlString) else { return }
        
        url.get(withDeserializer: JSONDeserializer()) { result, httpResponse in
            do {
                let json = try result.value()
                if let routes = json["routes"].array {
                    let route = routes[0]
                    let overview = route["overview_polyline"]
                    if let encoded = overview["points"].string {
                        if let path = GMSPath(fromEncodedPath: encoded) {
                            DispatchQueue.main.async {
                                self.tripListener?.destinationUpdated(path)
                            }
                        }
                    }
                }
            } catch {
                print("Error performing GET: \(error)")
            }
        }
    }
    // Load
    private func load() {
        self.initialLocationTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector:  #selector(noLocation), userInfo: nil, repeats: false)
//        self.shakingTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(verifyShaking), userInfo: nil, repeats: true)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        
        backgroundQueue.sync {
            self.startManagers()
            
            DispatchQueue.main.async {
                // Request permission
                let status = CLLocationManager.authorizationStatus()
                if status == .authorizedAlways || status == .authorizedWhenInUse {
                    self.locationManager.startUpdatingLocation()
                    self.locationManager.startUpdatingHeading()
                } else {
                    self.locationManager.requestAlwaysAuthorization()
                    self.locationManager.requestWhenInUseAuthorization()
                    self.locationManager.startUpdatingLocation()
                    self.locationManager.startUpdatingHeading()
                }
            }
        }
    }
    
    private func startManagers() {
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
                            self.hashTag = address.subLocality ?? address.locality ?? address.administrativeArea ?? address.country ?? "trilly"
                            self.hashTagKM[self.hashTag] = (self.hashTagKM[self.hashTag] ?? 0) + self.currentKM
                            self.currentKM = 0
                            self.tripListener?.hashtagUpdated(self.hashTag)
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
            self.stopVerifiers()
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
        backgroundQueue.sync {
            if self.initialLocationTimer != nil {
                self.initialLocationTimer!.invalidate()
                self.initialLocationTimer = nil
            }
            
            if self.trackingPath.count() == 1 {
                self.trackingPath.removeAllCoordinates()
                self.trackingPath.add(locations.last!.coordinate)
            }
            
            if self.lastLocation != nil {
                self.currentKM = currentKM + locations.last!.distance(from: lastLocation!)
            }
            
            self.trackingPath.add(locations.last!.coordinate)
            self.location = locations.last!.coordinate
            self.lastLocation = locations.last!
            
            self.speed = locations.last!.speed < 0 ? 0 : locations.last!.speed
            if self.onForeground && self.tripListener != nil {
                DispatchQueue.main.async {
                    self.tripListener?.tripUpdated(path: self.trackingPath)
                }
            }
            self.updateTripMotion()
            if self.hardwareAvailable {
                if (!self.deferringUpdates) {
                    self.locationManager.allowDeferredLocationUpdates(untilTraveled: 100, timeout: 60)
                    self.deferringUpdates = true;
                }
            } else {
                // Use custom method to defer updates
            }
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
    func destinationUpdated(_ route: GMSPath)
}
