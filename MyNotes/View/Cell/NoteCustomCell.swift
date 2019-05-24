//
//  NoteCustomCell.swift
//  MyNotes
//
//  Created by Тарас on 5/22/19.
//  Copyright © 2019 Taras. All rights reserved.
//

import UIKit

class NoteCustomCell: UITableViewCell {

    @IBOutlet weak var noteTextLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
