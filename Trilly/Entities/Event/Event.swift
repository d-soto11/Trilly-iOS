//
//  Event.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class Event: TrillyObject {
    
    // Class variables
    static let collectionName = "events"
    // Class methods
    
    // Type constructor
    class func withID(id: String, callback: @escaping (_ s: Event?)->Void) {
        Trilly.Database.ref().collection(collectionName).document(id).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Event(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    // Object fields
    var name: String?
    var descriptionT: String?
    var date: NSDate?
    var participants: Int?
    var icon: String?
    var reward: Double?
    var location: GeoPoint?
    var users: [String]?
    // Cahce fields
    
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let descriptionT = dict["description"] as? String {
            self.descriptionT = descriptionT
        }
        if let date = dict["date"] as? NSDate {
            self.date = date
        }
        if let participants = dict["participants"] as? Int {
            self.participants = participants
        }
        if let icon = dict["icon"] as? String {
            self.icon = icon
        }
        if let reward = dict["reward"] as? Double {
            self.reward = reward
        }
        if let location = dict["location"] as? GeoPoint {
            self.location = location
        }
        if let users = dict["users"] as? [String] {
            self.users = users
        }
    }
    
    // Reference functions
    public func users(_ callback: @escaping ([User]?)->Void) {
        if self.users != nil {
            var max = self.users!.count
            var response: [User] = []
            for userID in self.users! {
                User.withID(id: userID, callback: { (user) in
                    if user != nil {
                        response.append(user)
                    } else {
                        max = max - 1
                    }
                })
            }
        }
        
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
