//
//  TripBriefViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/5/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit

class TripBriefViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var shareB: UIButton!
    @IBOutlet weak var hashtagTable: UITableView!
    @IBOutlet weak var doneB: UIButton!
    @IBOutlet weak var statsScroll: UIScrollView!
    @IBOutlet weak var statsPageControll: UIPageControl!
    @IBOutlet weak var smallStat1: UIView!
    @IBOutlet weak var smallStat2: UIView!
    @IBOutlet weak var bigStat1: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        self.smallStat1.addNormalShadow()
        self.smallStat2.addNormalShadow()
        self.bigStat1.addNormalShadow()
        let _ = self.doneB.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor, horizontal: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "hashtag1", for: indexPath)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "hashtag2", for: indexPath)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "hashtag3", for: indexPath)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "hashtag", for: indexPath)
            return cell
        }
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
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.contentSize.width)
        self.statsPageControll.currentPage = Int(page)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        HashtagViewController.showHashtag(parent: self)
    }

}
