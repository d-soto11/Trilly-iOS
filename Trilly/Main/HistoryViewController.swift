//
//  HistoryViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/9/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB
import MBProgressHUD

class HistoryViewController: MaterialViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {


    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBackground: UIView!
    @IBOutlet weak var searchB: UIButton!
    @IBOutlet weak var historyTable: UITableView!
    @IBOutlet weak var reloadLabel: UILabel!
    
    private var filteredTrips: [Trip]?
    var userTrips: [Trip] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        User.current!.history({ (trips) in
            if trips != nil && trips!.count > 0 {
                print(trips!.count)
                self.userTrips = trips!
                self.historyTable.reloadData()
            } else {
                // Show no trip message
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        })
        if Trilly.Network.offline {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        self.searchBackground.addNormalShadow()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if userTrips.count > 0 {
            self.historyTable.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: true)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func search(_ sender: UIButton) {
    }
    
    
    // Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTrips != nil ? filteredTrips!.count : userTrips.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(220, UIScreen.main.bounds.size.height/4)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellUI = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! TrillyCell
        let trip = filteredTrips != nil ? filteredTrips![indexPath.row] : userTrips[indexPath.row]
        
        cellUI.uiUpdates = {cell in
            cell.viewWithTag(1)?.addNormalShadow()
            if trip.image != nil {
                (cell.viewWithTag(2) as? UIImageView)?.downloadedFrom(link: trip.image!)
            } else {
                (cell.viewWithTag(2) as? UIImageView)?.image = nil
            }
            (cell.viewWithTag(11) as? UILabel)?.text = String(format: "%.2f km", trip.stats?.km ?? 0)
            (cell.viewWithTag(12) as? UILabel)?.text = (trip.date! as Date).toString(format: .Short)
        }
        
        return cellUI
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip = filteredTrips != nil ? filteredTrips![indexPath.row] : userTrips[indexPath.row]
        TripBriefViewController.showTrip(trip: trip, onViewController: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == userTrips.count - 1 {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            User.current!.history({ (trips) in
                if trips != nil && trips!.count > 0 {
                    self.historyTable.beginUpdates()
                    var indexPaths = [IndexPath]()
                    for row in (self.userTrips.count..<(self.userTrips.count + trips!.count)) {
                        indexPaths.append(IndexPath(row: row, section: 0))
                    }
                    self.userTrips.append(contentsOf: trips!)
                    self.historyTable.insertRows(at: indexPaths, with: .bottom)
                    self.historyTable.endUpdates()
                    
                }
                MBProgressHUD.hide(for: self.view, animated: true)
            }, true)
        }
    }
    // Search
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let resultString = text.replacingCharacters(in: range, with: string)
            applySearch(resultString)
        } else {
            applySearch("")
        }
        return true
    }
    
    func applySearch(_ query: String) {
        if query != "" {
            filteredTrips = userTrips.filter({ (trip) -> Bool in
                trip.filters!.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(query.lowercased().folding(options: .diacriticInsensitive, locale: .current))
            })
        } else {
            filteredTrips = nil
        }
        self.historyTable.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchTextField.resignFirstResponder()
        
        if scrollView.contentOffset.y <= 0 {
            let net = scrollView.contentOffset.y / -100
            let opacity = net > 1 ? 1 : net
            UIView.animate(withDuration: 0.15, animations: {
                self.reloadLabel.alpha = opacity
            })
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= -75 {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            User.current!.history({ (trips) in
                if trips != nil && trips!.count > 0 {
                    self.userTrips = trips!
                    self.historyTable.reloadData()
                } else {
                    // Show no trip message
                }
                MBProgressHUD.hide(for: self.view, animated: true)
            })
        }
    }
    
    override func refreshViewController() -> MaterialViewController {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        User.current!.history ({ (trips) in
            if trips != nil && trips!.count > 0 {
                self.userTrips = trips!
                self.historyTable.reloadData()
            } else {
                // Show no trip message
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        })
        return self
    }

}
