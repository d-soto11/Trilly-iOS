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
    }
    
    // Reference functions
    public func users(_ callback: @escaping ([User]?)->Void) {
        guard self.uid != nil else { return }
        Trilly.Database.ref().collection(Event.collectionName)
            .document(self.uid!).collection(User.collectionName)
            .getDocuments { (documents, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [User] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(User(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    // Saving functions
    public func save() {
        if self.name != nil {
            originalDictionary["name"] = self.name
        }
        if self.descriptionT != nil {
            originalDictionary["description"] = self.descriptionT
        }
        if self.date != nil {
            originalDictionary["date"] = self.date
        }
        if self.participants != nil {
            originalDictionary["participants"] = self.participants
        }
        if self.icon != nil {
            originalDictionary["icon"] = self.icon
        }
        if self.reward != nil {
            originalDictionary["reward"] = self.reward
        }
        if self.location != nil {
            originalDictionary["location"] = self.location
        }
        
        super.save(route: Event.collectionName)
    }
    
    public func addUser(_ user: User) {
        guard self.uid != nil, user.uid != nil else { return }
        Trilly.Database.ref().collection(Event.collectionName)
            .document(self.uid!).collection(User.collectionName)
            .document(user.uid!).setData(user.originalDictionary)
    }
}
