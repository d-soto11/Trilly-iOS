//
//  EventDetailViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/6/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit

class EventDetailViewController: UIViewController {
    
    public class func showEventDetail(parent: UIViewController) {
        let st = UIStoryboard(name: "Event", bundle: nil)
        let event = st.instantiateViewController(withIdentifier: "Event") as! EventDetailViewController
        parent.showDetailViewController(event, sender: nil)
        UIApplication.shared.statusBarStyle = .lightContent
    }

    @IBOutlet weak var backB: UIButton!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var coverBackground: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoBackground: UIView!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bookedLabel: UILabel!
    @IBOutlet weak var infoText: UITextView!
    @IBOutlet weak var locationB: UIButton!
    @IBOutlet weak var joinB: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        self.coverBackground.addGradientBackground(Trilly.UI.secondColor, Trilly.UI.mainColor, horizontal: true, diagonal: true)
        self.joinB.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor, horizontal: true)
        self.infoBackground.addNormalShadow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func location(_ sender: Any) {
    }
    
    @IBAction func join(_ sender: Any) {
    }
    
}
