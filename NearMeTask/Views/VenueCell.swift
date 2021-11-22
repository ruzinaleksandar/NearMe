//
//  VenueCell.swift
//  NearMeTask
//
//  Created by Aleksandar Ruzin on 20.11.21.
//

import UIKit

/*
 
 Custom UITableViewCell class for creating a TebleView Cell
 
 */

class VenueCell: UITableViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var category: UILabel!
    @IBOutlet var address: UILabel!
    @IBOutlet var distance: UILabel!
    @IBOutlet var coordinates: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
