//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Artem Osipov on 11/04/2020.
//  Copyright © 2020 Artem Osipov. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progress: UIActivityIndicatorView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
