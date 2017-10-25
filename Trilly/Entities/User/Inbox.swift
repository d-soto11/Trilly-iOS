//
//  Inbox.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class Inbox: TrillyObject {
    
    // Class variables
    static let collectionName = "inbox"
    private static var lastLoadedInbox: DocumentSnapshot?
    // Class methods
    
    // Type constructor
    class func withID(id: String, relativeTo user: String, callback: @escaping (_ s: Inbox?)->Void) {
        let path = "\(User.collectionName)/\(user)/\(collectionName)/\(id)"
        Trilly.Database.ref().document(path).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Inbox(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    class func userInbox(userID: String, callback: @escaping (_ s: [Inbox]?)->Void) {
        Trilly.Database.ref().collection(User.collectionName)
            .document(userID)
            .collection(collectionName)
            .getDocuments { (documents, error) in
                
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [Inbox] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(Inbox(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    // Object fields
    var title: String?
    var content: String?
    var image: String?
    var link: String?
    var date: NSDate?
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let title = dict["title"] as? String {
            self.title = title
        }
        if let content = dict["content"] as? String {
            self.content = content
        }
        if let image = dict["image"] as? String {
            self.image = image
        }
        if let link = dict["link"] as? String {
            self.link = link
        }
        if let date = dict["date"] as? NSDate {
            self.date = date
        }
    }
    
    // Saving functions
    public func saveToUser(_ id: String) {
        if self.title != nil {
            originalDictionary["title"] = self.title
        }
        if self.content != nil {
            originalDictionary["content"] = self.content
        }
        if self.image != nil {
            originalDictionary["image"] = self.image
        }
        if self.link != nil {
            originalDictionary["link"] = self.link
        }
        if self.date != nil {
            originalDictionary["date"] = self.date
        }
        
        super.save(route: "\(User.collectionName)/\(id)/\(Inbox.collectionName)")
    }
}
