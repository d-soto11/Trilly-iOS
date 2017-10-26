//
//  ProfileViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

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
                let height = self.statsCollection.bounds.origin.y
                self.mainHeight.constant = max(height + self.statsCollection.contentSize.height, self.view.bounds.height - 50)
                self.statsHeight.constant = self.statsCollection.contentSize.height
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
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
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func organization(_ sender: Any) {
    }
    
    
    // Collection
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userStats.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        switch indexPath.row % 4{
        case 0:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VerticalStat", for: indexPath)
            return cell
        case 1:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VerticalStat", for: indexPath)
        case 2:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HorizontallStat", for: indexPath)
        case 3:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VerticalStat", for: indexPath)
        default:
            break
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = ((UIScreen.main.bounds.width - 50) / 2) - 10
        switch indexPath.row % 4{
        case 0:
            return CGSize(width: width, height: width*1.4)
        case 1:
            return CGSize(width: width, height: width*0.6)
        case 2:
            return CGSize(width: width, height: width*0.6)
        case 3:
            return CGSize(width: width, height: width*1.4)
        default:
            return CGSize()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }

}
