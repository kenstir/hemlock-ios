//
//  ListsViewController.swift
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

import UIKit
import ToastSwiftFramework
import PromiseKit
import PMKAlamofire

class ListsViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    /*
    override func viewDidLayoutSubviews() {
        // per https://stackoverflow.com/questions/2824435/uiscrollview-not-scrolling
        // you must sent content size or else the UIScrollView does not scroll
        // But it does not look like that is correct, scrolling works when contentView > scrollView
//        self.scrollView.contentSize = self.contentView.frame.size
        // If you want it to always scroll (even when scrollView > contentView) then add some slop:
        //self.scrollView.contentSize = CGSize(width: self.contentView.frame.size.width, height: self.contentView.frame.size.height + 300)
    }
    */

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Functions
    
    func setupViews() {
        tableView.dataSource = self
        //tableView.delegate = self
        self.setupHomeButton()
        //self.setupTapToDismissKeyboard(onScrollView: scrollView)
        //self.scrollView.setupKeyboardAutoResizer()
    }
    
    func setupButtons() {
        /*
        Style.styleButton(asInverse: firstButton)
        Style.styleButton(asInverse: button2)
        Style.styleButton(asInverse: button3)
        Style.styleButton(asInverse: button4)
        firstButton.addTarget(self, action: #selector(firstButtonPressed(sender:)), for: .touchUpInside)
        button2.addTarget(self, action: #selector(firstButtonPressed(sender:)), for: .touchUpInside)
        button3.addTarget(self, action: #selector(firstButtonPressed(sender:)), for: .touchUpInside)
        button4.addTarget(self, action: #selector(firstButtonPressed(sender:)), for: .touchUpInside)
        */
    }
    
    func fetchData() {
    }
    
    @objc func firstButtonPressed(sender: Any) {
        // JUNK!  just display one book jacket
        guard let authtoken = App.account?.authtoken else {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return
        }
        let records = [MBRecord(id: 71844)]//5859894
        var promises: [Promise<Void>] = []
        for record in records {
            promises.append(SearchService.fetchRecordMVR(authtoken: authtoken, forRecord: record))
            promises.append(PCRUDService.fetchSearchFormat(authtoken: authtoken, forRecord: record))
        }
        print("xxx \(promises.count) promises made")
        
        firstly {
            when(fulfilled: promises)
        }.done {
            let displayOptions = RecordDisplayOptions(enablePlaceHold: false, orgShortName: nil)
            let vc = XDetailsPagerViewController(items: records, selectedItem: 0, displayOptions: displayOptions)
            self.navigationController?.pushViewController(vc, animated: true)
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }

    }
}

extension ListsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "listsCell", for: indexPath) as? UITableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        cell.textLabel?.text = "Format"
        cell.detailTextLabel?.text = "Books"
        
        return cell
    }
}
