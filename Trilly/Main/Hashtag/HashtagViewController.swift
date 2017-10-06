//
//  HashtagViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/5/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit

class HashtagViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var backB: UIButton!
    @IBOutlet weak var stickyGradient: UIView!
    @IBOutlet weak var stickyBackground: UIView!
    @IBOutlet weak var stickyLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var hashtagPointsLabel: UILabel!
    @IBOutlet weak var myPointsLabel: UILabel!
    @IBOutlet weak var myKMLabel: UILabel!
    @IBOutlet weak var goalTable: UITableView!
    @IBOutlet weak var goalsB: UIButton!
    @IBOutlet weak var rankingB: UIButton!
    @IBOutlet weak var tabBackground: UIView!
    @IBOutlet weak var tabsFooter: UIView!
    
    @IBOutlet weak var mainHeigth: NSLayoutConstraint!
    @IBOutlet weak var goalHeigth: NSLayoutConstraint!
    
    private var currentTab = 0
    
    // Ranking only
    @IBOutlet weak var userRankingCell: UIView!
    
    // Testing purpose
    private var count = 20
    private let userRanking = 5
    
    
    public class func showHashtag(hashtag: AnyClass? = nil, parent: UIViewController) {
        let st = UIStoryboard(name: "Hashtag", bundle: nil)
        let hashView = st.instantiateViewController(withIdentifier: "Hashtag") as! HashtagViewController
        parent.showDetailViewController(hashView, sender: nil)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = self.view.addGradientBackground(Trilly.UI.mainColor, .white, start: 0.4, end: 0.6)
        tabBackground.backgroundColor = Trilly.UI.secondColor
        tabsFooter.backgroundColor = Trilly.UI.secondColor
        adjustConstraints()
        
        // Load user ranking
        (userRankingCell.viewWithTag(11) as? UILabel)?.text = "#\(userRanking + 1)"
    }
    
    func adjustConstraints() {
        switch self.currentTab {
        case 0:
            let exceded = CGFloat((count * 250))
            mainHeigth.constant = 330 + exceded
            goalHeigth.constant = exceded
        case 1:
            let exceded = CGFloat((count * 100))
            mainHeigth.constant = 330 + exceded
            goalHeigth.constant = exceded
        default:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        stickyBackground.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor)
        stickyGradient.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor)
        userRankingCell.addGradientBackground(UIColor.init(white: 1, alpha: 0), .white, end: 0.5)
        userRankingCell.viewWithTag(1)?.addNormalShadow()
        userRankingCell.viewWithTag(2)?.backgroundColor = Trilly.UI.contrastColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            UIApplication.shared.statusBarStyle = .default
        })
    }
    
    // Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch currentTab {
        case 0:
            return 250
        case 1:
            return 100
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentTab {
        case 0:
            let cellUI = tableView.dequeueReusableCell(withIdentifier: "GoalCell", for: indexPath) as! TrillyCell
            cellUI.uiUpdates = {(cell) in
                cell.viewWithTag(1)?.addNormalShadow()
            }
            return cellUI
        case 1:
            let cellUI = tableView.dequeueReusableCell(withIdentifier: "RankingCell", for: indexPath) as! TrillyCell
            cellUI.uiUpdates = {(cell) in
                cell.viewWithTag(1)?.addNormalShadow()
                cell.viewWithTag(2)?.addGradientBackground(Trilly.UI.secondColor, Trilly.UI.mainColor, horizontal: true, diagonal: true)
                (cell.viewWithTag(11) as? UILabel)?.text = "#\(indexPath.row + 1)"
                
                if indexPath.row == self.userRanking {
                    (cell.viewWithTag(21) as? UILabel)?.text = "Daniel Soto"
                    cell.viewWithTag(3)?.backgroundColor = Trilly.UI.contrastColor
                } else {
                    cell.viewWithTag(3)?.backgroundColor = .clear
                }
            }
            return cellUI
        default:
            return UITableViewCell()
        }
        
    }
    
    // Scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let stickiness = scrollView.contentOffset.y / 100
        let revealing = stickiness > 1 ? 1 : stickiness
        self.stickyLabel.alpha = revealing
        self.mainLabel.alpha = 1 - revealing
        self.hashtagPointsLabel.alpha = 1 - revealing
        
        if (revealing == 1) {
            let gradientness = (scrollView.contentOffset.y - 120) / 50
            let gradient = gradientness > 1 ? 1 : gradientness
            self.stickyGradient.alpha = gradient
        } else {
            self.stickyGradient.alpha = 0
        }
        
        if currentTab == 1 {
            loadUserRankingUI()
        }
        
    }
    
    // Tabbing
    @IBAction func loadGoals(_ sender: Any) {
        if currentTab != 0 {
            currentTab = 0
            self.adjustConstraints()
            self.view.layoutIfNeeded()
            self.goalsB.isSelected = true
            self.rankingB.isSelected = false
            self.goalTable.reloadSections(IndexSet(integer: 0), with: .right)
            UIView.animate(withDuration: 0.1, animations: {
                self.userRankingCell.alpha = 0
            })
        }
    }
    
    @IBAction func loadRanking(_ sender: Any) {
        if currentTab != 1 {
            currentTab = 1
            self.adjustConstraints()
            self.view.layoutIfNeeded()
            self.goalsB.isSelected = false
            self.rankingB.isSelected = true
            self.goalTable.reloadSections(IndexSet(integer: 0), with: .left)
            loadUserRankingUI()
        }
    }
    
    // Ranking animation:
    func loadUserRankingUI() {
        let needed = CGFloat(295 + (userRanking + 1)*100)
        if needed > scrollView.contentOffset.y + scrollView.bounds.height {
            UIView.animate(withDuration: 0.1, animations: {
                self.userRankingCell.alpha = 1
            })
        } else {
            UIView.animate(withDuration: 0.1, animations: {
                self.userRankingCell.alpha = 0
            })
        }
    }
    
}
