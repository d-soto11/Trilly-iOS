//
//  Goal.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class Goal: TrillyObject {
    
    // Class variables
    static let collectionName = "goals"
    // Class methods
    
    // Type constructor
    class func withID(id: String, relativeTo hashtag: String, callback: @escaping (_ s: Goal?)->Void) {
        let path = "\(Hashtag.collectionName)/\(hashtag.lowercased().folding(options: .diacriticInsensitive, locale: .current))/\(collectionName)/\(id)"
        Trilly.Database.ref().document(path).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Goal(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    class func goalsFromHashtag(hashtagID: String, callback: @escaping (_ s: [Goal]?)->Void) {
        
        Trilly.Database.ref().collection(Hashtag.collectionName)
            .document(hashtagID)
            .collection(collectionName)
            .getDocuments { (documents, error) in
                
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [Goal] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(Goal(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    // Object fields
    var name: String?
    var descriptionT: String?
    var icon: String?
    var points: Double?
    var achieved: Bool?
    var startDate: NSDate?
    var achievedDate: NSDate?
    var sponsors: [String]?
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let descriptionT = dict["description"] as? String {
            self.descriptionT = descriptionT
        }
        if let icon = dict["icon"] as? String {
            self.icon = icon
        }
        if let points = dict["points"] as? Double {
            self.points = points
        }
        if let achieved = dict["achieved"] as? Bool {
            self.achieved = achieved
        }
        if let startDate = dict["startDate"] as? NSDate {
            self.startDate = startDate
        }
        if let achievedDate = dict["achievedDate"] as? NSDate {
            self.achievedDate = achievedDate
        }
        if let sponsors = dict["sponsors"] as? [String] {
            self.sponsors = sponsors
        }
    }
    
    // Saving functions
    public func saveOnHashtag(_ id: String) {
        if self.name != nil {
            originalDictionary["name"] = self.name
        }
        if self.descriptionT != nil {
            originalDictionary["description"] = self.descriptionT
        }
        if self.icon != nil {
            originalDictionary["icon"] = self.icon
        }
        if self.points != nil {
            originalDictionary["points"] = self.points
        }
        if self.achieved != nil {
            originalDictionary["achieved"] = self.achieved
        }
        if self.startDate != nil {
            originalDictionary["startDate"] = self.startDate
        }
        if self.achievedDate != nil {
            originalDictionary["achievedDate"] = self.achievedDate
        }
        if self.sponsors != nil {
            originalDictionary["sponsors"] = self.sponsors
        }
        
        super.save(route: "\(Hashtag.collectionName)/\(id)/\(Goal.collectionName)")
    }
}
