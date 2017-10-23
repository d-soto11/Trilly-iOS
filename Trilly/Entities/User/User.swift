//
//  User.swift
//  Trilly
//
//  Created by Daniel Soto on 9/27/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class User: TrillyObject {
    
    // Class variables
    static var current: User?
    static let defaultPhoto: String = ""
    static let collectionName = "users"
    // Class methods
    public class func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out")
        }
    }
    // Type constructor
    class func withID(id: String, callback: @escaping (_ s: User?)->Void) {
        Trilly.Database.ref().collection(User.collectionName).document(id).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(User(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    // Init from Firebase User
    public convenience init(user: Firebase.User) {
        var dict: [String:Any] = ["name": user.displayName ?? "", "email":user.email ?? "", "id": user.uid]
        if let pp = user.photoURL {
            dict["photo"] = pp.absoluteString
        }
        self.init(dict)
    }
    
    // Object fields
    var name: String?
    var email: String?
    var photo: String? = User.defaultPhoto
    var phone: String?
    var gender: Int?
    var birth: NSDate?
    var joined: NSDate?
    var nextTree: Double?
    var blocked: Bool?
    var tokens: [String]?
    var organizationID: String?
    // Cache fields
    private var loadedHashtags: [HashtagPoints]?
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let email = dict["email"] as? String {
            self.email = email
        }
        if let photo = dict["photo"] as? String {
            self.photo = photo
        }
        if let phone = dict["phone"] as? String {
            self.phone = phone
        }
        if let gender = dict["gender"] as? Int {
            self.gender = gender
        }
        if let birth = dict["birth"] as? NSDate {
            self.birth = birth
        }
        if let joined = dict["joined"] as? NSDate {
            self.joined = joined
        }
        if let nextTree = dict["nextTree"] as? Double {
            self.nextTree = nextTree
        }
        if let blocked = dict["blocked"] as? Bool {
            self.blocked = blocked
        }
        if let tokens = dict["tokens"] as? [String] {
            self.tokens = tokens
        }
        if let organizationID = dict["organization"] as? String {
            self.organizationID = organizationID
        }
    }
    
    // Reference functions
    public func events(_ callback: @escaping ([Event]?)->Void) {
        guard self.uid != nil else { return }
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Event.collectionName)
            .getDocuments { (documents, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [Event] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(Event(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    public func hashtags(callback: @escaping (Bool)->Void = {_ in}, forceReload: Bool = false) -> [HashtagPoints]? {
        if loadedHashtags == nil || forceReload {
            HashtagPoints.pointsFromUser(userID: self.uid!, callback: { (hashtags) in
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
    
    public func trees(_ callback: @escaping ([Tree]?)->Void) {
        guard self.uid != nil else { return }
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Tree.collectionName)
            .getDocuments { (documents, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [Tree] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(Tree(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    public func organization(_ callback: @escaping (Organization?)->Void) {
        guard self.organizationID != nil else { return }
        Organization.withID(id: self.organizationID!, callback: callback)
    }
    
    public func history(_ callback: @escaping ([Trip]?)->Void) {
        guard self.uid != nil else { return }
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Trip.collectionName)
            .getDocuments { (documents, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [Trip] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(Trip(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    public func notifications() {
        
    }
    
    // Saving functions
    public func save() {
        if self.name != nil {
            originalDictionary["name"] = self.name
        }
        if self.email != nil {
            originalDictionary["email"] = self.email
        }
        if self.photo != nil {
            originalDictionary["photo"] = self.photo
        }
        if self.phone != nil {
            originalDictionary["phone"] = self.phone
        }
        if self.gender != nil {
            originalDictionary["gender"] = self.gender
        }
        if self.birth != nil {
            originalDictionary["birth"] = self.birth
        }
        if self.joined != nil {
            originalDictionary["joined"] = self.joined
        }
        if self.nextTree != nil {
            originalDictionary["nextTree"] = self.nextTree
        }
        if self.blocked != nil {
            originalDictionary["blocked"] = self.blocked
        }
        if self.tokens != nil {
            originalDictionary["tokens"] = self.tokens
        }
        if self.organizationID != nil {
            originalDictionary["organization"] = self.organizationID
        }
        
        super.save(route: User.collectionName)
    }
    
    public func addEvent(_ event: Event) {
        guard self.uid != nil, event.uid != nil else { return }
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Event.collectionName)
            .document(event.uid!).setData(event.originalDictionary)
    }
    
    public func addTree(_ tree: Tree) {
        guard self.uid != nil, tree.uid != nil else { return }
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Tree.collectionName)
            .document(tree.uid!).setData(tree.originalDictionary)
    }
    
    public func addTrip(_ trip: Trip) {
        guard self.uid != nil, trip.uid != nil else { return }
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Trip.collectionName)
            .document(trip.uid!).setData(trip.originalDictionary)
    }
    
    
    public func saveNotificationToken(token: String) {
        if self.tokens != nil {
            if !self.tokens!.contains(token) {
                self.tokens!.append(token)
                self.save()
            }
        } else {
            self.tokens = [token]
            self.save()
        }
    }
    
    public func checkNotifications() {
//        if let pending = self.notifications() {
//            for notification in pending {
//                switch notification.type! {
//                default:
//                    break
//                }
//            }
//            self.clearNotifications()
//        }
    }
    
    public func clearNotifications() {
//        original_dictionary.removeValue(forKey: "notifications")
//        Trilly.Database.ref().child("users").child(self.uid!).child("notifications").removeValue()
    }
}
