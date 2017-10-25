//
//  ProfileViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        User.current!.
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func organization(_ sender: Any) {
    }
    

}
