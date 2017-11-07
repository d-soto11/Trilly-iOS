//
//  HashtagsViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/9/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB

class HashtagsViewController: MaterialViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var backB: UIButton!
    @IBOutlet weak var stickyGradient: UIView!
    @IBOutlet weak var stickyBackground: UIView!
    @IBOutlet weak var stickyLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var hashtagsTable: UITableView!
    @IBOutlet weak var myHashtagsB: UIButton!
    @IBOutlet weak var globalB: UIButton!
    @IBOutlet weak var tabBackground: UIView!
    
    @IBOutlet weak var mainHeigth: NSLayoutConstraint!
    @IBOutlet weak var goalHeigth: NSLayoutConstraint!
    
    private var currentTab = 0
    
    
    
    // Data
    private var userRanking: Int = Int.max
    private var count = 0
    private var globalHashtags: [Hashtag]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = self.view.addGradientBackground(Trilly.UI.mainColor, .white, start: 0.4, end: 0.6)
        tabBackground.backgroundColor = Trilly.UI.secondColor
        adjustConstraints()
        let _ = User.current?.hashtags(callback: { (done) in
            if done {
                self.count = User.current?.hashtags()?.count ?? 0
                self.hashtagsTable.reloadData()
                self.adjustConstraints()
            }
        }, forceReload: true)
        
        Hashtag.global { (hashtags) in
            self.globalHashtags = hashtags
        }
    }
    
    func adjustConstraints() {
        var exceded: CGFloat = CGFloat(0)
        
        if count > 3 {
            exceded = CGFloat(90+80+70 + ((count-3) * 60))
        } else if count > 0{
            for i in 0...(count-1) {
                exceded = exceded + CGFloat(60 + (10*(3-i)))
            }
        }
        
        mainHeigth.constant = max(330 + exceded, self.view.bounds.height)
        goalHeigth.constant = exceded
    }
    
    override func viewDidLayoutSubviews() {
        stickyBackground.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor)
        stickyGradient.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    // Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        switch indexPath.row {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "hashtag1", for: indexPath)
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "hashtag2", for: indexPath)
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "hashtag3", for: indexPath)
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "hashtag", for: indexPath)
        }
        
        switch self.currentTab {
        case 0:
            let hashtag = User.current!.hashtags()![indexPath.row]
            (cell.viewWithTag(1) as? UILabel)?.text = "#\(hashtag.name?.lowercased() ?? "trilly")"
            (cell.viewWithTag(2) as? UILabel)?.text = String(format: "%.0f", hashtag.points ?? 0)
        case 1:
            let hashtag = self.globalHashtags![indexPath.row]
            (cell.viewWithTag(1) as? UILabel)?.text = "#\(hashtag.name?.lowercased() ?? "trilly")"
            (cell.viewWithTag(2) as? UILabel)?.text = String(format: "%.0f", hashtag.points ?? 0)
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 90
        case 1:
            return 80
        case 2:
            return 70
        default:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.currentTab {
        case 0:
            let hashtag = User.current!.hashtags()![indexPath.row]
            HashtagViewController.showHashtag(hashtag: hashtag.name!, parent: self)
        case 1:
            let hashtag = self.globalHashtags![indexPath.row]
            HashtagViewController.showHashtag(hashtag: hashtag.name!, parent: self)
        default:
            break
        }
    }
    
    // Scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let stickiness = scrollView.contentOffset.y / 100
        let revealing = stickiness > 1 ? 1 : stickiness
        self.stickyLabel.alpha = revealing
        self.mainLabel.alpha = 1 - revealing
        
        if (revealing == 1) {
            let gradientness = (scrollView.contentOffset.y - 120) / 50
            let gradient = gradientness > 1 ? 1 : gradientness
            self.stickyGradient.alpha = gradient
        } else {
            self.stickyGradient.alpha = 0
        }
        
    }
    
    // Tabbing
    @IBAction func loadMyHashtags(_ sender: Any) {
        if currentTab != 0 {
            currentTab = 0
            self.myHashtagsB.isSelected = true
            self.globalB.isSelected = false
            self.count = User.current?.hashtags()?.count ?? 0
            self.adjustConstraints()
            self.view.layoutIfNeeded()
            self.hashtagsTable.reloadSections(IndexSet(integer: 0), with: .right)
        }
    }
    
    @IBAction func loadGlobal(_ sender: Any) {
        if currentTab != 1 {
            currentTab = 1
            self.myHashtagsB.isSelected = false
            self.globalB.isSelected = true
            self.count = self.globalHashtags?.count ?? 0
            self.adjustConstraints()
            self.view.layoutIfNeeded()
            self.hashtagsTable.reloadSections(IndexSet(integer: 0), with: .left)
        }
    }

}
