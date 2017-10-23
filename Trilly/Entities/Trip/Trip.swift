//
//  Trip.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class Trip: TrillyObject {
    
    // Class variables
    static let collectionName = "trips"
    // Class methods
    
    // Type constructor
    class func withID(id: String, callback: @escaping (_ s: Trip?)->Void) {
        Trilly.Database.ref().collection(collectionName).document(id).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Trip(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    // Object fields
    var path: String?
    var start: GeoPoint?
    var destination: GeoPoint?
    var time: Int?
    var stats: Stats?
    var userID: String?
    // Cahce fields
    private var loadedHashtags: [HashtagInfo]?
    private var loadedAccidents: [Accident]?
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let path = dict["path"] as? String {
            self.path = path
        }
        if let start = dict["start"] as? GeoPoint {
            self.start = start
        }
        if let destination = dict["destination"] as? GeoPoint {
            self.destination = destination
        }
        if let time = dict["time"] as? Int {
            self.time = time
        }
        if let stats = dict["stats"] as? [String:Any] {
            self.stats = Stats(stats)
        }
        if let user = dict["user"] as? String {
            self.userID = user
        }
    }
    
    // Reference functions
    public func hashtags(callback: @escaping (Bool)->Void = {_ in}, forceReload: Bool = false) -> [HashtagInfo]? {
        if loadedHashtags == nil || forceReload {
            HashtagInfo.infoFromTrip(tripID: self.uid!, callback: { (hashtags) in
                if hashtags != nil {
                    self.loadedHashtags = hashtags!
                    callback(true)
                } else {
                    callback(false)
                }
            })
        }
        
        return loadedHashtags
    }
    
    public func accidents(callback: @escaping (Bool)->Void = {_ in}, forceReload: Bool = false) -> [Accident]? {
        if loadedAccidents == nil || forceReload {
            Accident.infoFromTrip(tripID: self.uid!, callback: { (accidents) in
                if accidents != nil {
                    self.loadedAccidents = accidents!
                    callback(true)
                } else {
                    callback(false)
                }
            })
        }
        
        return loadedAccidents
    }
    
    public func user(_ callback: @escaping (User?)->Void) {
        guard self.userID != nil else { return }
        User.withID(id: self.userID!, callback: callback)
    }
    
    // Saving functions
    
    public func save() {
        if self.path != nil {
            originalDictionary["path"] = self.path
        }
        if self.start != nil {
            originalDictionary["start"] = self.start
        }
        if self.destination != nil {
            originalDictionary["destination"] = self.destination
        }
        if self.time != nil {
            originalDictionary["time"] = self.time
        }
        
        super.save(route: Trip.collectionName)
    }
}
