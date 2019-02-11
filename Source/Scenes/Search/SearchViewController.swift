//
//  SearchViewController.swift
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
import PromiseKit
import PMKAlamofire

struct SearchParameters {
    let text: String
    let searchClass: String
    let searchFormat: String?
    let organizationShortName: String?
}

class OptionsEntry {
    var label: String
    var value: String?
    init(_ label: String, value: String?) {
        self.label = label
        self.value = value
    }
}

class SearchViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var optionsTable: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    
    weak var activityIndicator: UIActivityIndicatorView!
    
    let scopes = App.searchScopes
    let formats = Format.getSpinnerLabels()
    var orgLabels: [String] = []
    var didCompleteFetch = false

    var options: [OptionsEntry] = []
    let searchClassIndex = 0
    let searchFormatIndex = 1
    let searchLocationIndex = 2

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        searchButton.isEnabled = false
        optionsTable.isUserInteractionEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // deselect row when navigating back
        if let indexPath = optionsTable.indexPathForSelectedRow {
            optionsTable.deselectRow(at: indexPath, animated: true)
        }

        if !didCompleteFetch {
            fetchData()
        }
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }

        var promises: [Promise<Void>] = []        
        promises.append(ActorService.fetchOrgTypesArray())
        promises.append(ActorService.fetchOrgs())
        promises.append(ActorService.fetchUserSettings(account: account))
        promises.append(SearchService.fetchCopyStatusAll())

        self.activityIndicator.startAnimating()

        firstly {
            when(fulfilled: promises)
        }.done {
            self.setupLocationPicker()
            self.searchButton.isEnabled = true
            self.optionsTable.isUserInteractionEnabled = true
            self.didCompleteFetch = true
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func setupViews() {
        setupActivityIndicator()
        optionsTable.delegate = self
        optionsTable.dataSource = self
        optionsTable.tableFooterView = UIView() // prevent ghost rows at end of table
        self.setupHomeButton()
        setupSearchBar()
        setupOptionsTable()
        setupLocationPicker() // will be redone after fetchData
        setupSearchButton()
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }
    
    func setupSearchBar() {
        Style.styleSearchBar(searchBar)
    }
    
    func setupOptionsTable() {
        options = []
        options.append(OptionsEntry("Search by", value: scopes[0]))
        options.append(OptionsEntry("Limit to", value: formats[0]))
        options.append(OptionsEntry("Search within", value: nil))
    }

    func setupLocationPicker() {
        self.orgLabels = Organization.getSpinnerLabels()
        if orgLabels.count == 0 {
            return // we are early
        }

        var selectOrgIndex = 0
        let defaultSearchLocation = App.account?.searchOrgID
        for index in 0..<Organization.orgs.count {
            let org = Organization.orgs[index]
            if org.id == defaultSearchLocation {
                selectOrgIndex = index
            }
        }

        let entry = options[searchLocationIndex]
        entry.value = orgLabels[selectOrgIndex].trim()
        self.optionsTable.reloadData()
    }
    
    func setupSearchButton() {
        searchButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asInverse: searchButton)
    }
    
    @objc func buttonPressed(sender: UIButton) {
        doSearch()
    }

    func doSearch() {
        guard let searchText = searchBar.text?.trim(), searchText.count > 0 else {
            self.showAlert(title: "Nothing to search for", message: "Search words cannot be empty")
            return
        }
        if searchButton.isEnabled == false {
            self.showAlert(title: "Busy", message: "Please wait until data is finished loading")
            return
        }
        guard let searchClass = options[searchClassIndex].value?.lowercased(),
            let formatText = options[searchFormatIndex].value,
            let searchOrg = Organization.getShortName(forName: options[searchLocationIndex].value?.trim()) else
        {
            Analytics.logError(code: .shouldNotHappen, msg: "error during prepare", file: #file, line: #line)
            self.showAlert(title: "Internal error", message: "Internal error preparing for search")
            return
        }
        let searchFormat = Format.getSearchFormat(forSpinnerLabel: formatText)
        let params = SearchParameters(text: searchText, searchClass: searchClass, searchFormat: searchFormat, organizationShortName: searchOrg)
        let vc = XResultsViewController()
        vc.searchParameters = params
        print("--- searchParams \(String(describing: vc.searchParameters))")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        //called on every key press, do not search here
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        doSearch()
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Options"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchOptionsCell", for: indexPath)

        let entry = options[indexPath.row]
        cell.textLabel?.text = entry.label
        cell.detailTextLabel?.text = entry.value
        
        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        let entry = options[indexPath.row]
        vc.title = entry.label
        vc.selectedOption = entry.value
        switch indexPath.row {
        case searchClassIndex:
            vc.options = scopes
        case searchFormatIndex:
            vc.options = formats
        case searchLocationIndex:
            vc.options = orgLabels
        default:
            break
        }

        vc.selectionChangedHandler = { value in
            entry.value = value
            self.optionsTable.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}
