//
//  ResultsViewController.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation
import UIKit
import PromiseKit
import PMKAlamofire

class ResultsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var searchParametersLabel: UILabel!
    
    var searchParameters: SearchParameters?
    var resultIDs: [Int] = []
    var records: [String] = []
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        var label: String
        if let sp = searchParameters, let q = getQueryString() {
            label = "You searched for:\n"
            label += "\n"
            label += "\(sp.searchClass):\(sp.text)\n"
            label += "search_format(\(sp.searchFormat ?? ""))\n"
            label += "site(\(sp.organizationShortName ?? ""))\n"
            label += "\n\n"
            label += q
        } else {
            label = """
The engravings translate to
'This space intentionally left blank'.
"""
        }
        searchParametersLabel.text = label
    }
    
    // Build query string, taken with a grain of salt from
    // https://wiki.evergreen-ils.org/doku.php?id=documentation:technical:search_grammar
    // e.g. "title:Harry Potter chamber of secrets search_format(book) site(MARLBORO)"
    func getQueryString() -> String? {
        guard let sp = searchParameters else {
            self.showAlert(title: "Internal Error", message: "No search parameters")
            return nil
        }
        var query = "\(sp.searchClass):\(sp.text)"
        if let sf = sp.searchFormat, !sf.isEmpty {
            query += " search_format(\(sf))"
        }
        if let org = sp.organizationShortName, !org.isEmpty {
            query += " site(\(org))"
        }
        return query
    }
}

