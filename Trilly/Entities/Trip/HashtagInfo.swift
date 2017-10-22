//
//  HashtagInfo.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class HashtagInfo: TrillyObject {
    
    // Class variables
    static let collectionName = "hashtags"
    // Class methods
    
    // Type constructor
    class func withID(id: String, relativeTo trip: String, callback: @escaping (_ s: HashtagInfo?)->Void) {
        let path = "\(Trip.collectionName)/\(trip)/\(collectionName)/\(id)"
        Trilly.Database.ref().document(path).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(HashtagInfo(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    class func infoFromTrip(tripID: String, callback: @escaping (_ s: [HashtagInfo]?)->Void) {
        
        Trilly.Database.ref().collection(Trip.collectionName)
            .document(tripID)
            .collection(collectionName)
            .getDocuments { (documents, error) in
                
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [HashtagInfo] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(HashtagInfo(document.data()))
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
    var points: Double?
    
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let points = dict["points"] as? Double {
            self.points = points
        }
    }
    
    // Saving functions
    public func saveOnTrip(_ id: String) {
        guard self.name != nil else { return }
        originalDictionary["name"] = self.name
        
        if self.points != nil {
            originalDictionary["points"] = self.points
        }
        
        self.uid = self.name!
        
        super.save(route: "\(Trip.collectionName)/\(id)/\(HashtagInfo.collectionName)")
    }
}
