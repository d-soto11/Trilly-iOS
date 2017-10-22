//
//  Accident.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

typealias AccidentType = Int

class Accident: TrillyObject {
    
    // Class variables
    static let collectionName = "accidents"
    static let fall: AccidentType = 0
    static let crash: AccidentType = 1
    static let flatTire: AccidentType = 2
    // Class methods
    
    // Type constructor
    class func withID(id: String, relativeTo trip: String, callback: @escaping (_ s: Accident?)->Void) {
        let path = "\(Trip.collectionName)/\(trip)/\(collectionName)/\(id)"
        Trilly.Database.ref().document(path).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Accident(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    class func infoFromTrip(tripID: String, callback: @escaping (_ s: [Accident]?)->Void) {
        
        Trilly.Database.ref().collection(Trip.collectionName)
            .document(tripID)
            .collection(collectionName)
            .getDocuments { (documents, error) in
                
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [Accident] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(Accident(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    // Object fields
    var type: AccidentType?
    var location: GeoPoint?
    var confirmed: Bool?
    var date: NSDate?
    
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let type = dict["type"] as? AccidentType {
            self.type = type
        }
        if let location = dict["location"] as? GeoPoint {
            self.location = location
        }
        if let confirmed = dict["confirmed"] as? Bool {
            self.confirmed = confirmed
        }
        if let date = dict["date"] as? NSDate {
            self.date = date
        }
    }
    
    // Saving functions
    public func saveOnTrip(_ id: String) {
        if self.type != nil {
            originalDictionary["type"] = self.type
        }
        if self.location != nil {
            originalDictionary["location"] = self.location
        }
        if self.confirmed != nil {
            originalDictionary["confirmed"] = self.confirmed
        }
        if self.date != nil {
            originalDictionary["date"] = self.date
        }
        
        super.save(route: "\(Trip.collectionName)/\(id)/\(Accident.collectionName)")
        
    }
}
