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
    
    static var current: User?
    
    static let defaultPhoto: String = ""
    
    public class func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out")
        }
    }
    
    public override init(_ dict: [String: AnyObject]){
        super.init(dict)
        
        if let name = dict["name"] {
            self.name = (name as? String)
        }
        if let birth = dict["birth"] {
            self.birth = Date(fromString: birth as! String)
        }
        if let joined = dict["joined"] {
            self.joined = Date(fromString: joined as! String)
        }
        if let gender = dict["gender"] {
            self.gender = (gender as? Int)
        }
        if let photo = dict["photo"] {
            self.photo = (photo as? String)
        }
        if let email = dict["email"] {
            self.email = (email as? String)
        }
        if let points = dict["points"] {
            self.points = (points as? Double)
        }
        if let phone = dict["phone"] {
            self.phone = (phone as? String)
        }
        if let blocked = dict["blocked"] {
            self.blocked = (blocked as? Bool)
        }
    }
    
    public convenience init(user: Firebase.User) {
        var dict = ["name": user.displayName, "email":user.email, "id": user.uid]
        if let pp = user.photoURL {
            dict["photo"] = pp.absoluteString
        }
        self.init(dict as [String : AnyObject])
    }
    
    public func save() {
        if self.name != nil {
            original_dictionary["name"] = self.name as AnyObject
        }
        if self.birth != nil {
            original_dictionary["birth"] = self.birth!.toString(format: .Default) as AnyObject
        }
        if self.joined != nil {
            original_dictionary["joined"] = self.joined!.toString(format: .Long) as AnyObject
        }
        if self.gender != nil {
            original_dictionary["gender"] = self.gender as AnyObject
        }
        if self.photo != nil {
            original_dictionary["photo"] = self.photo as AnyObject
        }
        if self.email != nil {
            original_dictionary["email"] = self.email as AnyObject
        }
        if self.points != nil {
            original_dictionary["points"] = self.points as AnyObject
        }
        if self.phone != nil {
            original_dictionary["phone"] = self.phone as AnyObject
        }
        if self.blocked != nil {
            original_dictionary["blocked"] = self.blocked as AnyObject
        }
        
        super.save(route: "users")
    }
    
    class func withID(id: String, callback: @escaping (_ s: User?)->Void){
        Trilly.Database.ref().child("users").child(id).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            if let dict = snapshot.value as? [String:AnyObject] {
                callback(User(dict))
            } else {
                callback(nil)
            }
        })
    }
    
    var name: String?
    var birth: Date?
    var joined: Date?
    var gender: Int?
    var photo: String? = User.defaultPhoto
    var email: String?
    var points: Double?
    var phone: String?
    var blocked: Bool?
    
    public func notifications() -> [Notification]? {
        var notifications:[Notification] = []
        if let not = original_dictionary["notifications"] {
            if let notDict = not as? [String:AnyObject] {
                for (_, notification) in notDict {
                    if let notificationDict = notification as? [String:AnyObject] {
                        notifications.append(Notification(notificationDict))
                    }
                }
                return notifications
            }
        }
        return nil
    }
    
    public func saveNotificationToken(token: String) {
        Trilly.Database.ref().child("users").child(self.uid!).child("tokens").child(token).setValue(true)
    }
    
    public func checkNotifications() {
        if let pending = self.notifications() {
            for notification in pending {
                switch notification.type! {
                default:
                    break
                }
            }
            self.clearNotifications()
        }
    }
    
    public func clearNotifications() {
        original_dictionary.removeValue(forKey: "notifications")
        Trilly.Database.ref().child("users").child(self.uid!).child("notifications").removeValue()
    }
}
