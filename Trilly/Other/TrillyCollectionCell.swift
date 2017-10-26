//
//  TrillyCollectionCell.swift
//  Trilly
//
//  Created by Daniel Soto on 10/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit

class TrillyCollectionCell: UICollectionViewCell {
    public var uiUpdates: ((UICollectionViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        uiUpdates?(self)
    }
}
