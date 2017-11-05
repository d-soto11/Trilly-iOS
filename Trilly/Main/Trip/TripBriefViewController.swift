//
//  TripBriefViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/5/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB
import MBProgressHUD

class TripBriefViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var shareB: UIButton!
    @IBOutlet weak var hashtagTable: UITableView!
    @IBOutlet weak var doneB: UIButton!
    @IBOutlet weak var backB: UIButton!
    @IBOutlet weak var statsScroll: UIScrollView!
    @IBOutlet weak var statsPageControll: UIPageControl!
    @IBOutlet weak var smallStat1: UIView!
    @IBOutlet weak var smallStat2: UIView!
    @IBOutlet weak var bigStat1: UIView!
    
    private var loadFromCache = true
    
    public var trip: Trip!
    
    public class func showTrip(trip: Trip, onViewController: UIViewController) {
        let st = UIStoryboard(name: "Trip", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "Brief") as! TripBriefViewController
        vc.trip = trip
        vc.loadFromCache = false
        
        onViewController.showDetailViewController(vc, sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if self.loadFromCache {
            self.loadTripFromCache()
        } else {
            doneB.alpha = 0
            backB.alpha = 1
            self.loadTripData()
        }
    }
    
    @objc public func loadTripFromCache() {
        if let t = Trilly.Database.Local.get(Trip.new) as? Trip {
            trip = t
            self.loadTripData()
        } else {
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(loadTripFromCache), userInfo: nil, repeats: false)
        }
    }
    
    func loadTripData() {
        let _ = trip.hashtags (callback: { done in
            MBProgressHUD.hide(for: self.view, animated: true)
            if done {
                self.hashtagTable.reloadData()
            }
        })
        (self.smallStat1.viewWithTag(11) as? UILabel)?.text = String(format: "%.0f Calorías quemadas", trip.stats?.cal ?? 0)
        (self.smallStat2.viewWithTag(11) as? UILabel)?.text = String(format: "%.0f galones de gasolina ahorrados", trip.stats?.gas ?? 0)
        (self.bigStat1.viewWithTag(11) as? UILabel)?.text = String(format: "%.0f kg de CO2 no emitidos", trip.stats?.co2 ?? 0)
    }
    
    override func viewDidLayoutSubviews() {
        self.smallStat1.addNormalShadow()
        self.smallStat2.addNormalShadow()
        self.bigStat1.addNormalShadow()
        self.doneB.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor, horizontal: true)
        
        self.statsPageControll.numberOfPages = Int(ceil(self.statsScroll.contentSize.width / self.statsScroll.bounds.width))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trip.hashtags()?.count ?? 0
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
        
        (cell.viewWithTag(1) as? UILabel)?.text = "#\(trip.hashtags()?[indexPath.row].name?.lowercased() ?? "trilly")"
        (cell.viewWithTag(2) as? UILabel)?.text = String(format: "%.0f", trip.hashtags()?[indexPath.row].points ?? 0)
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
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.contentSize.width)
        self.statsPageControll.currentPage = Int(page)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let hs = trip.hashtags()?[indexPath.row].name {
            HashtagViewController.showHashtag(hashtag: hs, parent: self)
        }
    }
    
    @IBAction func share(_ sender: Any) {
        
    }
    
    @IBAction func done(_ sender: Any) {
        MaterialTB.currentTabBar!.reloadViewController()
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
