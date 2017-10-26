//
//  ProfileViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var backB: UIButton!
    @IBOutlet weak var profileScroll: UIScrollView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var organizationB: UIButton!
    @IBOutlet weak var treesLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var statsCollection: UICollectionView!
    
    @IBOutlet weak var mainHeight: NSLayoutConstraint!
    @IBOutlet weak var statsHeight: NSLayoutConstraint!
    
    private var userStats: [UserStat] = []
    private var user: User!
    
    public class func showProfile(user: User = User.current!, onViewController: UIViewController? = nil) {
        let profile = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "Profile") as! ProfileViewController
        profile.user = user
        
        if onViewController == nil {
            MaterialTB.currentTabBar!.show(profile, sender: nil)
        } else {
            onViewController?.show(profile, sender: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user.stats { (stats) in
            if stats != nil {
                self.userStats = stats!
                self.statsCollection.reloadData()
                self.statsCollection.layoutIfNeeded()
                self.statsHeight.constant = self.statsCollection.contentSize.height
                let height = self.statsCollection.frame.origin.y
                self.mainHeight.constant = max(height + self.statsCollection.contentSize.height, self.mainHeight.constant)
            }
        }
        
        if user.uid! != User.current!.uid! {
            self.organizationB.isEnabled = false
            if user.organization == nil {
                self.organizationB.alpha = 0
            }
        }
        
        if user.photo != nil {
            self.profileImage.downloadedFrom(link: user.photo!)
        }
        self.userName.text = user.name
        user.organization { (org) in
            if org != nil {
                self.organizationB.setTitle(org!.name ?? "", for: .normal)
            }
        }
        user.trees { (trees) in
            if trees != nil {
                self.treesLabel.text = "\(trees!.count)"
            }
        }
        self.pointsLabel.text = String(format: "%.0f pts.", user.points ?? 0)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        self.profileImage.roundCorners(radius: 10)
    }
    
    @IBAction func organization(_ sender: Any) {
    }
    
    
    // Collection
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userStats.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let stat = userStats[indexPath.row]
        var cellUI = TrillyCollectionCell()
        let loadInfo: (UICollectionViewCell) -> Void = { cell in
            cell.viewWithTag(1)?.addNormalShadow()
            if stat.icon != nil {
                //(cell.viewWithTag(2) as? UIImageView)?.downloadedFrom(link: stat.icon!)
                (cell.viewWithTag(11) as? UILabel)?.text = String(format: "%.0f %@", (stat.stat ?? 0), (stat.descriptionT ?? "pts."))
            }
            
        }
        switch indexPath.row % 4{
        case 0:
            cellUI = collectionView.dequeueReusableCell(withReuseIdentifier: "VerticalStat", for: indexPath) as! TrillyCollectionCell
        case 1:
            cellUI = collectionView.dequeueReusableCell(withReuseIdentifier: "VerticalStat", for: indexPath) as! TrillyCollectionCell
        case 2:
            cellUI = collectionView.dequeueReusableCell(withReuseIdentifier: "HorizontalStat", for: indexPath) as! TrillyCollectionCell
        case 3:
            cellUI = collectionView.dequeueReusableCell(withReuseIdentifier: "VerticalStat", for: indexPath) as! TrillyCollectionCell
        default:
            break
        }
        cellUI.uiUpdates = loadInfo
        return cellUI
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.statsCollection.frame.size.width / 2) - 20
        print(width)
        switch indexPath.row % 4 {
        case 0:
            return CGSize(width: width, height: width*1.3)
        case 1:
            return CGSize(width: width, height: width*0.8)
        case 2:
            return CGSize(width: width, height: width*0.8)
        case 3:
            return CGSize(width: width, height: width*1.3)
        default:
            return CGSize(width: width, height: width)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

}
