//
//  User.swift
//  Trilly
//
//  Created by Daniel Soto on 9/27/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase
import Modals3A
import MaterialTB

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
    var organization: DocumentReference?
    var points: Double?
    // Cache fields
    private var loadedHashtags: [HashtagPoints]?
    private var lastHistory: DocumentSnapshot?
    private var lastInbox: DocumentSnapshot?
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
        if let organization = dict["organization"] as? DocumentReference {
            self.organization = organization
        }
        if let points = dict["points"] as? Double {
            self.points = points
        }
    }
    
    // Reference functions
    public func reference() -> DocumentReference {
        return Trilly.Database.ref().collection(User.collectionName).document(uid!)
    }
    
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
        guard self.organization != nil else { return }
        Organization.withID(id: self.organization!.documentID, callback: callback)
    }
    
    public func history(_ callback: @escaping ([Trip]?)->Void, _ more: Bool = false) {
        guard self.uid != nil else { return }
        var query = Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Trip.collectionName)
            .order(by: "date", descending: true)
        if lastHistory != nil && more {
            query = query.start(afterDocument: lastHistory!)
        }   
        
        query.limit(to: 10).getDocuments { (documents, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    if more && self.lastHistory != nil && self.lastHistory?.documentID == documents!.documents.last?.documentID {
                        callback(nil)
                    } else {
                        self.lastHistory = documents!.documents.last ?? self.lastHistory
                        var response: [Trip] = []
                        for document in documents!.documents {
                            if document.exists {
                                response.append(Trip(document.data()))
                            }
                        }
                        callback(response)
                    }
                } else {
                    callback(nil)
                }
        }
    }
    
    public func inbox(_ callback: @escaping ([Inbox]?, Int)->Void) {
        guard self.uid != nil else { return }
        let lastDate = UserDefaults.standard.object(forKey: Trilly.Settings.lastReadFeedKey) as? Date
        
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Inbox.collectionName)
            .order(by: "date", descending: true)
            .end(before: [(lastDate ?? Date()) as NSDate])
            .addSnapshotListener { (documents, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [Inbox] = []
                    var unread: Int = 0
                    self.lastInbox = documents!.documents.last
                    for document in documents!.documents {
                        if document.exists {
                            let inb = Inbox(document.data())
                            response.append(inb)
                            if lastDate == nil || lastDate! < ((inb.date ?? NSDate()) as Date) {
                                unread += 1
                            }
                        }
                    }
                    callback(response, unread)
                } else {
                    callback(nil, 0)
                }
        }
    }
    
    public func inboxHistory(_ callback: @escaping ([Inbox]?)->Void) {
        guard self.uid != nil else { return }
        var query = Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(Inbox.collectionName)
            .order(by: "date", descending: true)
        if lastInbox != nil {
            query = query.start(afterDocument: lastInbox!)
        }
        
        query.limit(to: 10).getDocuments { (documents, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if documents != nil {
                if self.lastInbox != nil && self.lastInbox?.documentID == documents!.documents.last?.documentID {
                    callback(nil)
                } else {
                    self.lastInbox = documents!.documents.last ?? self.lastInbox
                    var response: [Inbox] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(Inbox(document.data()))
                        }
                    }
                    callback(response)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    public func stats(_ callback: @escaping ([UserStat]?)->Void) {
        guard self.uid != nil else { return }
        Trilly.Database.ref().collection(User.collectionName)
            .document(self.uid!).collection(UserStat.collectionName)
            .addSnapshotListener { (documents, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [UserStat] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(UserStat(document.data()))
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
        if self.organization != nil {
            originalDictionary["organization"] = self.organization
        }
        if self.points != nil {
            originalDictionary["points"] = self.points
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
    
    public func scheduleNotification(title: String, message: String, type: Int = Trilly.Settings.NotificationTypes.normal) {
        UserDefaults.standard.set(true, forKey: Trilly.Settings.notificationPending)
        UserDefaults.standard.set(title, forKey: Trilly.Settings.notificationTitle)
        UserDefaults.standard.set(message, forKey: Trilly.Settings.notificationContent)
        UserDefaults.standard.set(type, forKey: Trilly.Settings.notificationType)
    }
    
    public func checkNotifications() {
        if UserDefaults.standard.bool(forKey: Trilly.Settings.notificationPending) {
            guard let title = UserDefaults.standard.string(forKey: Trilly.Settings.notificationTitle),
                let content = UserDefaults.standard.string(forKey: Trilly.Settings.notificationContent) else { return }
            
            let type = UserDefaults.standard.integer(forKey: Trilly.Settings.notificationType)
            
            switch type {
            case Trilly.Settings.NotificationTypes.normal:
                Alert3A.show(withTitle: title, body: content, accpetTitle: "Entendido", confirmation: {
                    self.clearNotifications()
                })
            case Trilly.Settings.NotificationTypes.tripEnded:
                Alert3A.show(withTitle: title, body: content, accpetTitle: "Entendido", confirmation: {
                    self.clearNotifications()
                    
                    if let _ = Trilly.Database.Local.get(Trip.new) as? Trip {
                        guard var parent = UIApplication.shared.delegate?.window??.rootViewController else { return }
                        
                        while ((parent.presentedViewController) != nil) {
                            parent = parent.presentedViewController!
                        }
                        
                        TripBriefViewController.showTrip(onViewController: parent)
                    } else {
                        MaterialTB.currentTabBar?.reloadViewController()
                    }
                })
            case Trilly.Settings.NotificationTypes.tripPaused:
                Alert3A.show(withTitle: title, body: content, accpetTitle: "Continuar viaje", cancelTitle: "Terminar", confirmation: {
                    guard var parent = UIApplication.shared.delegate?.window??.rootViewController else { return }
                    
                    while ((parent.presentedViewController) != nil) {
                        parent = parent.presentedViewController!
                    }
                    
                    if parent.isKind(of: TripViewController.self) {
                        TripManager.resume(parent as! TripViewController)
                    } else {
                        TripManager.resume(nil)
                    }
                    
                    self.clearNotifications()
                    
                }, cancelation: {
                    // Save paused path to firebase and clean encoded path
                    self.clearNotifications()
                    TripManager.clear()
                    
                    if let _ = Trilly.Database.Local.get(Trip.new) as? Trip {
                        guard var parent = UIApplication.shared.delegate?.window??.rootViewController else { return }
                        
                        while ((parent.presentedViewController) != nil) {
                            parent = parent.presentedViewController!
                        }
                        
                        TripBriefViewController.showTrip(onViewController: parent)
                    } else {
                        MaterialTB.currentTabBar?.reloadViewController()
                    }
                    
                    
                })
            default:
                break
            }
        }
    }
    
    public func clearNotifications() {
        UserDefaults.standard.removeObject(forKey: Trilly.Settings.notificationPending)
        UserDefaults.standard.removeObject(forKey: Trilly.Settings.notificationTitle)
        UserDefaults.standard.removeObject(forKey: Trilly.Settings.notificationContent)
    }
}
