//
//  Hashtag.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class Hashtag: TrillyObject {
    
    // Class variables
    static let collectionName = "hashtags"
    // Class methods
    
    // Type constructor
    class func withID(id: String, callback: @escaping (_ s: Hashtag?)->Void) {
        Trilly.Database.ref().collection(collectionName).document(id).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Hashtag(documentData))
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
    var routeName: String?
    var points: Double?
    var center: GeoPoint?
    var radius: Double?
    // Cahce fields
    private var loadedContributions: [UserContribution]?
    private var loadedGoals: [Goal]?
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let routeName = dict["routeName"] as? String {
            self.routeName = routeName
        }
        if let points = dict["points"] as? Double {
            self.points = points
        }
        if let center = dict["center"] as? GeoPoint {
            self.center = center
        }
        if let radius = dict["radius"] as? Double {
            self.radius = radius
        }
    }
    
    // Reference functions
    public func users(callback: @escaping (Bool)->Void = {_ in}, forceReload: Bool = false) -> [UserContribution]? {
        if loadedContributions == nil || forceReload {
            UserContribution.usersFromHashtag(hashtagID: self.uid!, callback: { (users) in
                if users != nil {
                    self.loadedContributions = users!
                    callback(true)
                } else {
                    callback(false)
                }
            })
        }
        
        return loadedContributions
    }
    
    public func goals(callback: @escaping (Bool)->Void = {_ in}, forceReload: Bool = false) -> [Goal]? {
        if loadedGoals == nil || forceReload {
            Goal.goalsFromHashtag(hashtagID: self.uid!, callback: { (goals) in
                if goals != nil {
                    self.loadedGoals = goals!
                    callback(true)
                } else {
                    callback(false)
                }
            })
        }
        
        return loadedGoals
    }
    
    // Saving functions
    
    public func save() {
        guard self.name != nil else { return }
        
        originalDictionary["name"] = self.name
        
        if self.routeName != nil {
            originalDictionary["routeName"] = self.routeName
        }
        if self.points != nil {
            originalDictionary["points"] = self.points
        }
        if self.center != nil {
            originalDictionary["center"] = self.center
        }
        if self.radius != nil {
            originalDictionary["radius"] = self.radius
        }
        
        self.uid = name!
    
        super.save(route: Hashtag.collectionName)
    }
}
