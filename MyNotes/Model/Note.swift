//
//  Note.swift
//  MyNotes
//
//  Created by Тарас on 5/22/19.
//  Copyright © 2019 Taras. All rights reserved.
//

import Foundation
import RealmSwift

class Note: Object {
    @objc dynamic var noteText : String = ""
    @objc dynamic var noteDate : Date?
    @objc dynamic var canEdit : Bool = false
}
