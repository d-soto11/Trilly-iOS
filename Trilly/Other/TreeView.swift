//
//  TreeView.swift
//  Trilly
//
//  Created by Daniel Soto on 11/13/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit

class TreeView: UIView {
    
    let liquidView = UIImageView()
    let shape = UIImage(named: "BigTree")
    var height = NSLayoutConstraint()
    var width = NSLayoutConstraint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        
        self.liquidView.contentMode = .scaleAspectFit
        self.liquidView.image = UIImage(named: "BigTree")
        self.liquidView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(liquidView)
        
        let c1 = NSLayoutConstraint(item: self.liquidView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let c2 = NSLayoutConstraint(item: self.liquidView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        height = NSLayoutConstraint(item: self.liquidView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.bounds.height)
        width = NSLayoutConstraint(item: self.liquidView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.bounds.width)
        
        self.addConstraints([c1, c2, width, height])
        
        layoutIfNeeded()
        reset()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func reset() {
        self.liquidView.image = nil
    }
    
    func animate(toFilled p:CGFloat) {
        reset()
        let image = self.shape!
        let height = CGFloat(image.size.height * p)
        let rect = CGRect(x: 0, y: image.size.height - height, width: image.size.width, height: height)
        self.liquidView.image = self.cropImage(image: image, toRect: rect)
        self.width.constant = self.frame.width * p
        self.height.constant = self.frame.height * p
        self.layoutIfNeeded()
    }
    
    func cropImage(image:UIImage, toRect rect:CGRect) -> UIImage?{
        var rect = rect
        rect.size.width = rect.width * image.scale
        rect.size.height = rect.height * image.scale
        rect.origin.y = rect.origin.y*image.scale
        
        guard let imageRef = image.cgImage?.cropping(to: rect) else {
            return nil
        }
        
        let croppedImage = UIImage(cgImage:imageRef)
        return croppedImage
    }
}
