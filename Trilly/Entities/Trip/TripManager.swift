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
import MapKit

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
    private(set) public var destinationName: String = ""
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
    private var lowMemory: Bool = false
    private var timeToRecoverMemory: Int = 60
    // Verification
    private var slowMovementTimer: Timer?
    private var fastMovementTimer: Timer?
    private var slowMovementInterval = 10.0
    private var fastMovementInterval = 2.0
    // Listener
    private weak var tripListener: TripListener?
    // Singleton
    private(set) public static var current: TripManager?
    private static let footSpeed = 2.5
    private static let bycicleSpeed = 12.0
    private static let carSpeed = 20.0
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
    // Load
    private func load() {
        self.initialLocationTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector:  #selector(noLocation), userInfo: nil, repeats: false)
        //        self.shakingTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(verifyShaking), userInfo: nil, repeats: true)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        
        DispatchQueue(label: "com.trilly.tripcreationqueue", qos: .userInitiated).sync {
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
            self.locationManager?.disallowDeferredLocationUpdates()
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
    // Stop
    public func stop() -> Bool {
        self.pause()
        
        guard self.trackingPath.count() >= 2 else { return false }
        
        let globalKM = self.trackingPath.length(of: GMSLengthKind.rhumb)/1000
        
        if globalKM < 0.7 {
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
            return false
        }
        
        backgroundQueue.async {
            let newTrip = Trip([:])
            if self.destination != nil {
                newTrip.destination = GeoPoint(latitude: self.destination!.latitude, longitude: self.destination!.longitude)
            }
            
            newTrip.path = self.trackingPath.encodedPath()
            
            var outter = 1.0
            while self.trackingPath.count() > 150 {
                for i in 1...(self.trackingPath.count()-1) {
                    let l2d1 = self.trackingPath.coordinate(at: i-1)
                    let l2d2 = self.trackingPath.coordinate(at: i)
                    let location1 = CLLocation(latitude: l2d1.latitude, longitude: l2d1.longitude)
                    let location2 = CLLocation(latitude: l2d2.latitude, longitude: l2d2.longitude)
                    
                    if location1.distance(from: location2) < (5.0 * outter) {
                        self.trackingPath.removeCoordinate(at: i)
                    }
                }
                outter += 1
            }
            
            newTrip.shortPath = self.trackingPath.encodedPath()
            
            let initial = self.trackingPath.coordinate(at: 0)
            newTrip.start = GeoPoint(latitude: initial.latitude, longitude: initial.longitude)
            let final = self.trackingPath.coordinate(at: self.trackingPath.count() - 1)
            newTrip.end = GeoPoint(latitude: final.latitude, longitude: final.longitude)
            newTrip.time = self.time
            newTrip.user = User.current!.reference()
            newTrip.date = NSDate()
            newTrip.filters = ""
            
            let stats = Stats([:])
            stats.km = globalKM
            stats.cal = Double(11 * (self.time/60))
            stats.co2 = 257 * stats.km!
            newTrip.stats = stats
            newTrip.save()
            
            for (name, km) in self.hashTagKM {
                let hashtag = HashtagInfo([:])
                hashtag.name = name
                hashtag.points = km
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
                userHashtag.saveToUser(User.current!.uid!)
                newTrip.filters = "\(newTrip.filters!)-\(name)"
            }
            
            newTrip.save()
            User.current!.points = User.current!.points ?? 0 + newTrip.stats!.km!
            User.current!.addTrip(newTrip)
            User.current!.save()
            Trilly.Database.Local.save(id: Trip.new, data: newTrip as AnyObject)
        }
        
        TripManager.current = nil
        TripManager.encodedGMSPath = nil
        TripManager.time = nil
        TripManager.lastHashtag = nil
        TripManager.hashTagKM = nil
        
        self.locationManager?.stopUpdatingHeading()
        self.locationManager?.stopUpdatingLocation()
        self.locationManager?.disallowDeferredLocationUpdates()
        self.locationManager?.delegate = nil
        self.locationManager = nil
        
        self.motionActivityManager?.stopActivityUpdates()
        self.motionActivityManager = nil
        
        self.motionManager?.stopAccelerometerUpdates()
        self.motionManager = nil
        
        return true
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
        motionManager.startAccelerometerUpdates(to: OperationQueue()) { (data, error) in
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
        motionActivityManager!.startActivityUpdates(to: OperationQueue()) { (activity) in
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
        if lowMemory && timeToRecoverMemory > 0 {
            timeToRecoverMemory -= 1
            time += 1
            DispatchQueue.main.async {
                self.tripListener?.timeTick(self.time)
            }
            return
        } else if lowMemory {
            lowMemory = false
            timeToRecoverMemory = 60
            if self.destination != nil {
                self.setDestination(destination!, destinationName)
            }
        }
        
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
        
        if (time % 20 == 0 && destination != nil && onForeground) {
            setDestination(destination!, destinationName)
        }
        
        time += 1
        DispatchQueue.main.async {
            self.tripListener?.timeTick(self.time)
        }
    }
    
    // Destination handlers
    public func boundsFromLocation() -> GMSCoordinateBounds? {
        guard self.location != nil else { return nil }
        
        let region = MKCoordinateRegionMakeWithDistance(self.location!, 30000, 30000)
        let northEast = CLLocationCoordinate2D(latitude: self.location!.latitude + region.span.latitudeDelta, longitude: self.location!.longitude + region.span.longitudeDelta)
        let southWeast = CLLocationCoordinate2D(latitude: self.location!.latitude - region.span.latitudeDelta, longitude: self.location!.longitude - region.span.longitudeDelta)
        
        return GMSCoordinateBounds(coordinate: northEast, coordinate: southWeast)
    }
    
    public func setDestination(_ destination: CLLocationCoordinate2D, _ name: String) {
        self.destination = destination
        self.destinationName = name
        guard lastLocation != nil else { return }
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(self.lastLocation!.coordinate.latitude),\(self.lastLocation!.coordinate.longitude)&destination=\(destination.latitude),\(destination.longitude)&mode=walking&key=\(Trilly.googleApiKey)"
        
        
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
                                if self.tripListener != nil {
                                    self.tripListener!.destinationUpdated(path)
                                } else {
                                    print("No listener")
                                }
                            }
                        }
                    } else {
                        print("No path received")
                    }
                }
            } catch {
                print("Error performing GET: \(error)")
            }
        }
    }
    
    private func updateTripMotion() {
        // print("Motion: \(speed)")
        if speed < TripManager.footSpeed {
            if slowMovementTimer == nil {
                slowMovementTimer = Timer.scheduledTimer(timeInterval: slowMovementInterval, target: self, selector: #selector(verifySlowMovement), userInfo: nil, repeats: false)
            }
        } else if speed < TripManager.bycicleSpeed {
            self.stopVerifiers()
        } else if speed < TripManager.carSpeed {
            if fastMovementTimer == nil {
                fastMovementTimer = Timer.scheduledTimer(timeInterval: fastMovementInterval, target: self, selector: #selector(verifyFastMovement), userInfo: nil, repeats: false)
            }
        } else {
            if onForeground {
                self.tripListener?.tripStoped(message: "Hemos detectado que vas muy rápido, posiblemente en un medio de transporte diferente a la bicicleta. Debemos parar tu viaje porque Trilly está diseñado para bicicletas, pero hemos guardado los pedalazos que diste antes.", path: self.trackingPath)
                
                let _ = self.stop()
            } else {
                // Guardar notificación para el background
                if self.stop() {
                    User.current!.scheduleNotification(title: "Lo sentimos", message: "Hemos detectado que vas muy rápido, posiblemente en un medio de transporte diferente a la bicicleta. Debemos parar tu viaje porque Trilly está diseñado para bicicletas, pero hemos guardado los pedalazos que diste antes.", type: Trilly.Settings.NotificationTypes.tripEnded)
                } else {
                    User.current!.scheduleNotification(title: "Lo sentimos", message: "Hemos detectado que vas muy rápido, posiblemente en un medio de transporte diferente a la bicicleta.")
                }
            }
        }
    }
    
    
    
    @objc public func verifySlowMovement() {
        print("Verifing slow")
        let intents = slowMovementInterval / 10
        if intents >= 10 {
            if onForeground {
                self.tripListener?.tripPaused(message: "Hemos detectado que has parado tu rodada. Puedes terminar tu viaje o continuarlo si ya estás listo para seguir pedaleando.", path: self.trackingPath)
            } else {
                // Guardar notificación para el background
                User.current!.scheduleNotification(title: "Viaje pausado", message: "Hemos detectado que has parado tu rodada. Puedes terminar tu viaje o continuarlo si ya estás listo para seguir pedaleando.", type: Trilly.Settings.NotificationTypes.tripPaused)
            }
            self.pause()
        } else {
            slowMovementInterval = slowMovementInterval + 10
            slowMovementTimer = Timer.scheduledTimer(timeInterval: slowMovementInterval, target: self, selector: #selector(verifySlowMovement), userInfo: nil, repeats: false)
        }
    }
    
    @objc public func verifyFastMovement() {
        print("Verifing fast")
        let intents = fastMovementInterval / 2
        if intents >= 10 {
            if onForeground {
                self.tripListener?.tripStoped(message: "Hemos detectado que vas muy rápido, posiblemente en un medio de transporte diferente a la bicicleta. Debemos parar tu viaje porque Trilly está diseñado para bicicletas, pero hemos guardado los pedalazos que diste antes.", path: self.trackingPath)
                
                let _ = self.stop()
            } else {
                // Guardar notificación para el background
                if self.stop() {
                    User.current!.scheduleNotification(title: "Lo sentimos", message: "Hemos detectado que vas muy rápido, posiblemente en un medio de transporte diferente a la bicicleta. Debemos parar tu viaje porque Trilly está diseñado para bicicletas, pero hemos guardado los pedalazos que diste antes.", type: Trilly.Settings.NotificationTypes.tripEnded)
                } else {
                    User.current!.scheduleNotification(title: "Lo sentimos", message: "Hemos detectado que vas muy rápido, posiblemente en un medio de transporte diferente a la bicicleta.")
                }
            }
            
        } else {
            fastMovementInterval  = fastMovementInterval + 2
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
        slowMovementInterval = 10
        fastMovementInterval = 2
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
            var localSpeed = 0.0
            if self.lastLocation != nil {
                localSpeed = locations.last!.distance(from: lastLocation!)
                self.currentKM = currentKM + (localSpeed/1000)
            }
            
            self.trackingPath.add(locations.last!.coordinate)
            self.location = locations.last!.coordinate
            self.lastLocation = locations.last!
            
            self.speed = max(locations.last!.speed < 0 ? 0 : locations.last!.speed, localSpeed)
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
        if self.destination != nil {
            self.setDestination(destination!, destinationName)
        }
    }
    
    // Listener methods
    public func registerTripListener(_ listener: TripListener) {
        self.tripListener = listener
        if self.destination != nil {
            self.setDestination(self.destination!, self.destinationName)
        }
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
    
    public func memoryWarning() {
        self.stopVerifiers()
        self.lowMemory = true
    }
}

protocol TripListener: NSObjectProtocol {
    func tripUpdated(path: GMSPath)
    func headingUpdated(heading: CLLocationDirection)
    func noLocation()
    func tripStoped(message: String, path: GMSPath)
    func tripPaused(message: String, path: GMSPath)
    func timeTick(_ time: Int)
    func hashtagUpdated(_ hashtag: String)
    func destinationUpdated(_ route: GMSPath)
}
