/*
 * SearchViewController.swift
 *
 * Copyright (C) 2018 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import UIKit
import PromiseKit
import PMKAlamofire

struct SearchParameters {
    let text: String
    let searchClass: String
    let searchFormat: String?
    let organizationShortName: String?
    let sort: String?
}

class OptionsEntry {
    var label: String
    var value: String?
    var index: Int?
    init(_ label: String, value: String?, index: Int? = nil) {
        self.label = label
        self.value = value
        self.index = index
    }
}

class SearchViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var optionsTable: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    
    weak var activityIndicator: UIActivityIndicatorView!
    
    let scopes = App.searchScopes
    var formatLabels: [String] = []
    var orgLabels: [String] = []
    var didCompleteFetch = false

    var options: [OptionsEntry] = []
    let searchClassIndex = 0
    let searchFormatIndex = 1
    let searchLocationIndex = 2
    
    var scannedBarcode: String? = nil

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
        
        // handle barcode when navigating back
        if let barcode = scannedBarcode {
            showAlert(title: "got one", message: barcode)
            scannedBarcode = nil
        }

        if !didCompleteFetch {
            fetchData()
        }
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }

        var promises: [Promise<Void>] = []        
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTree())
        promises.append(ActorService.fetchUserSettings(account: account))
        promises.append(PCRUDService.fetchCodedValueMaps())
        promises.append(SearchService.fetchCopyStatusAll())

        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()

        firstly {
            when(fulfilled: promises)
        }.done {
            self.setupFormatPicker()
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
//        setupScanButton()
        setupSearchBar()
        setupOptionsTable()
        setupFormatPicker() // will be redone after fetchData
        setupLocationPicker() // will be redone after fetchData
        setupSearchButton()
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }
    
//    func setupScanButton() {
//        let scanButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(scanButtonPressed(sender:)))
//        navigationItem.rightBarButtonItems?.append(scanButton)
//    }

    func setupSearchBar() {
        Style.styleSearchBar(searchBar)

        // The idea here was to use a .done keyboard for small screens,
        // where the keyboard obscures the search options.  But that
        // doesn't prevent cases where dynamic type is extra huge, so
        // for now always use .done instead of .search.
        //if UIScreen.main.bounds.height < 667
        searchBar.returnKeyType = .done
        
        var image = UIImage(named: "barcode_scan")
        if #available(iOS 13.0, *) {
            image = image?.withTintColor(Style.secondaryLabelColor)
        }
        searchBar.showsBookmarkButton = true
        searchBar.setImage(image, for: .bookmark, state: .normal)
    }
  
    func setupOptionsTable() {
        options = []
        options.append(OptionsEntry("Search by", value: scopes[0]))
        options.append(OptionsEntry("Limit to", value: nil))
        options.append(OptionsEntry("Search within", value: nil))
    }

    func setupFormatPicker() {
        self.formatLabels = CodedValueMap.searchFormatSpinnerLabels()
        if formatLabels.count == 0 {
            return // we are early
        }
        
        let entry = options[searchFormatIndex]
        entry.value = formatLabels[0]
        self.optionsTable.reloadData()
    }

    func setupLocationPicker() {
        self.orgLabels = Organization.getSpinnerLabels()
        if orgLabels.count == 0 {
            return // we are early
        }

        var selectOrgIndex = 0
        let defaultSearchLocation = App.account?.searchOrgID
        for index in 0..<Organization.visibleOrgs.count {
            let org = Organization.visibleOrgs[index]
            if org.id == defaultSearchLocation {
                selectOrgIndex = index
            }
        }

        let entry = options[searchLocationIndex]
        entry.value = orgLabels[selectOrgIndex].trim()
        entry.index = selectOrgIndex
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
        guard let searchText = searchBar.text?.trim(), !searchText.isEmpty else {
            self.showAlert(title: "Nothing to search for", message: "Search words cannot be empty")
            return
        }
        if searchButton.isEnabled == false {
            self.showAlert(title: "Busy", message: "Please wait until data is finished loading")
            return
        }
        guard let searchClass = options[searchClassIndex].value?.lowercased(),
            let searchFormatLabel = options[searchFormatIndex].value,
            let searchOrgIndex = options[searchLocationIndex].index else
        {
            self.showAlert(title: "Internal error", error: HemlockError.shouldNotHappen("Missing search class, format, or org"))
            return
        }
        let searchFormat = CodedValueMap.searchFormatCode(forLabel: searchFormatLabel)
        let searchOrg = Organization.visibleOrgs[searchOrgIndex]
        let params = SearchParameters(text: searchText, searchClass: searchClass, searchFormat: searchFormat, organizationShortName: searchOrg.shortname, sort: App.config.sort)
        let vc = XResultsViewController()
        vc.searchParameters = params
        print("--- searchParams \(String(describing: vc.searchParameters))")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func getTextView(_ searchBar: UISearchBar) -> UITextField? {
        if #available(iOS 13.0, *) {
            return searchBar.searchTextField
        } else {
            let subViews = searchBar.subviews.flatMap { $0.subviews }
            let textField = (subViews.filter { $0 is UITextField }).first as? UITextField
            return textField
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.returnKeyType == .done {
            getTextView(searchBar)?.resignFirstResponder()
        } else {
            doSearch()
        }
    }
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        let grantMessage = "Grant access to the camera in the Settings app under Privacy >> Camera"
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [self] granted in
                // NB: non-main thread
                DispatchQueue.main.async {
                    if !granted {
                        self.showAlert(title: "Notice", message: "Can't scan a barcode without camera access.")
                    } else {
                        self.showScanBarcodeVC()
                    }
                }
            }
        case .denied:
            showAlert(title: "Camera access was denied", message: grantMessage)
        case .restricted:
            showAlert(title: "Camera access is restricted", message: grantMessage)
        default:
            showScanBarcodeVC()
        }
    }
    
    func showScanBarcodeVC() {
        guard let vc = UIStoryboard(name: "ScanBarcode", bundle: nil).instantiateInitialViewController() as? ScanBarcodeViewController else { return }
        vc.barcodeScannedHandler = { barcode in
            self.scannedBarcode = barcode
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func onBarcodeScanned(_ barcode: String) {
        showAlert(title: "got one", message: barcode)
    }
}

//MARK: - UITableViewDataSource
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

//MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        let entry = options[indexPath.row]
        vc.title = entry.label
        vc.selectedLabel = entry.value
        switch indexPath.row {
        case searchClassIndex:
            vc.optionLabels = scopes
        case searchFormatIndex:
            vc.optionLabels = formatLabels
        case searchLocationIndex:
            vc.optionLabels = orgLabels
            vc.optionIsPrimary = Organization.getIsPrimary()
        default:
            break
        }

        vc.selectionChangedHandler = { index, value in
            entry.value = value
            entry.index = index
            self.optionsTable.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}
