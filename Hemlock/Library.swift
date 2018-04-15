//
//  Library.swift
//  Hemlock
//
//  Created by Ken Cox on 4/15/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation

class Library {
    let name: String
    let directoryName: String
    let url: String
    
    init(name: String, directoryName: String, url: String) {
        self.name = name
        self.directoryName = directoryName
        self.url = url
    }
}
