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
    }
    
    // Reference functions
    public func events() {
        
    }
    
    public func hashtags() {
        
    }
    
    public func trees() {
        
    }
    
    public func organization() {
        
    }
    
    public func history() {
        
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
        
        super.save(route: User.collectionName)
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
