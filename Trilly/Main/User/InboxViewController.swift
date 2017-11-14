//
//  InboxViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 11/6/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MBProgressHUD

class InboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public class func showInbox(_ parent: UIViewController) {
        let s = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "Inbox")
        parent.show(s, sender: nil)
    }

    @IBOutlet weak var inboxTable: UITableView!
    
    private var inbox: [Inbox] = []
    private var unread: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        User.current?.inbox({ (noti, unr) in
            if noti != nil {
                self.unread = unr
                self.inbox = noti!
                self.inboxTable.reloadData()
                if self.inbox.count == 0 {
                    User.current?.inboxHistory({ (noti) in
                        if noti != nil && noti!.count > 0 {
                            self.inboxTable.beginUpdates()
                            var indexPaths = [IndexPath]()
                            for row in (self.inbox.count..<(self.inbox.count + noti!.count)) {
                                indexPaths.append(IndexPath(row: row, section: 0))
                            }
                            self.inbox.append(contentsOf: noti!)
                            self.inboxTable.insertRows(at: indexPaths, with: .bottom)
                            self.inboxTable.endUpdates()
                        }
                    })
                }
            }
        })
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UserDefaults.standard.set(Date(), forKey: Trilly.Settings.lastReadFeedKey)
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let count = inbox[indexPath.row].content?.count ?? 0
        return 260.0 + (20.0 * CGFloat(count/45)) + (inbox[indexPath.row].link == nil ? 0 : 20)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.inbox.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellUI = tableView.dequeueReusableCell(withIdentifier: "InboxCell", for: indexPath) as! TrillyCell
        let feed = inbox[indexPath.row]
        cellUI.uiUpdates = {cell in
            cell.viewWithTag(1)?.addNormalShadow()
            (cell.viewWithTag(11) as? UILabel)?.text = feed.title
            (cell.viewWithTag(12) as? UILabel)?.text = (feed.date! as Date).toString(format: .News)
            (cell.viewWithTag(20) as? UITextView)?.text = feed.content
            
            if feed.image != nil {
                (cell.viewWithTag(2) as? UIImageView)?.downloadedFrom(link: feed.image!)
            }
            
            if feed.link != nil && feed.link != "" {
                (cell.viewWithTag(21))?.alpha = 1
            } else {
                (cell.viewWithTag(21))?.alpha = 0
            }
            
            if indexPath.row < self.unread {
                (cell.viewWithTag(30))?.roundCorners(radius: 5)
                (cell.viewWithTag(30))?.alpha = 1
            } else {
                (cell.viewWithTag(30))?.alpha = 0
            }
        }
        return cellUI
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == inbox.count - 1 {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            User.current?.inboxHistory({ (noti) in
                if noti != nil && noti!.count > 0 {
                    self.inboxTable.beginUpdates()
                    var indexPaths = [IndexPath]()
                    for row in (self.inbox.count..<(self.inbox.count + noti!.count)) {
                        indexPaths.append(IndexPath(row: row, section: 0))
                    }
                    self.inbox.append(contentsOf: noti!)
                    self.inboxTable.insertRows(at: indexPaths, with: .bottom)
                    self.inboxTable.endUpdates()
                }
                MBProgressHUD.hide(for: self.view, animated: true)
            })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feed = inbox[indexPath.row]
        if feed.link != nil {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            if let url = URL(string: feed.link!) {
                UIApplication.shared.openURL(url)
            } else {
                self.showAlert(title: "Lo sentimos", message: "La página de este mensaje ha sido eliminada.", closeButtonTitle: "OK")
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}
