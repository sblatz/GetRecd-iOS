//
//  FriendsViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 3/29/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var refresher: UIRefreshControl!
    
    var searchController = UISearchController(searchResultsController: nil)
    var timerToQuery: Timer?
    var searchString = ""
    var selectedUser = ""
    
    /// A `DispatchQueue` used for synchornizing the setting of `friends` to avoid threading issues with various `UITableView` delegate callbacks.
    var setterQueue = DispatchQueue(label: "SearchViewController")
    
    var friends = [String]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var findFriends = [String]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var requests = [String]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var selectedFriends = Set<String>()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        addButton.isHidden = true
        denyButton.isHidden = true
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self
        self.definesPresentationContext = true
        self.navigationItem.searchController = searchController
        view.layoutIfNeeded()
        
        getFriends()
        
        refresher = UIRefreshControl()
        tableView.addSubview(refresher)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.becomeFirstResponder()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return friends.count
        case 1:
            return findFriends.count
        case 2:
            return requests.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as? FriendCell else { return FriendCell() }
        
        var arr: [String] = []
        
        cell.accessoryType = .none
        
        // Configure the cell...
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            arr = friends
        case 1:
            arr = findFriends
        case 2:
            arr = requests
        default:
            arr = []
        }
        
        let user = arr[indexPath.row]
        cell.user = user
        
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc =  segue.destination as? FriendsLikesViewController {
            vc.user = selectedUser
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch segmentedControl.selectedSegmentIndex {
        // Friends list showing
        case 0:
            if let cell = tableView.cellForRow(at: indexPath) as? FriendCell {
                // Segue to a view controller that shows that user's profile:

                selectedUser = cell.user
                self.performSegue(withIdentifier: "toFriend", sender: nil)
            }
        case 1:
            if let cell = tableView.cellForRow(at: indexPath) as? FriendCell {
                
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    selectedFriends.remove(cell.user)
                } else {
                    cell.accessoryType = .checkmark
                    selectedFriends.insert(cell.user)
                }
            }
            
            if selectedFriends.count > 0 {
                addButton.isHidden = false
            } else {
                addButton.isHidden = true
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        case 2:
            if let cell = tableView.cellForRow(at: indexPath) as? FriendCell {
                
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    selectedFriends.remove(cell.user)
                } else {
                    cell.accessoryType = .checkmark
                    selectedFriends.insert(cell.user)
                }
            }
            
            if selectedFriends.count > 0 {
                addButton.isHidden = false
                denyButton.isHidden = false
            } else {
                addButton.isHidden = true
                denyButton.isHidden = true
            }
        default:
            return
        }
    }
    
    @IBAction func didChangeSegment(_ sender: Any) {
        friends = []
        requests = []
        findFriends = []
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            getFriends()
            addButton.isHidden = true
            denyButton.isHidden = true
            searchController.searchBar.isHidden = false
            refresher.isHidden = false
            refresher = UIRefreshControl()
            refresher.addTarget(self, action: #selector(getFriends), for: UIControlEvents.valueChanged)
            
        case 1:
            addButton.isHidden = false
            searchController.searchBar.isHidden = false
            refresher.isHidden = true
            denyButton.isHidden = true
        case 2:
            getRequests()
            searchController.searchBar.isHidden = true
            refresher.isHidden = false
            refresher = UIRefreshControl()
            refresher.addTarget(self, action: #selector(getRequests), for: UIControlEvents.valueChanged)
        default:
            addButton.isHidden = true
            refresher.isHidden = false
            denyButton.isHidden = true
            searchController.searchBar.isHidden = false
        }
    }
    
    @objc func getFriends() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        DataService.sharedInstance.getFriends(uid: uid, success: { (friends) in
            self.friends = friends
            DispatchQueue.main.async {
                self.refresher.endRefreshing()
            }

        }) { (error) in
            // TODO: Show error in getting friends
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.refresher.endRefreshing()
            }

        }
        
    }
    
    @objc func getRequests() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        DataService.sharedInstance.getIncomingFriendRequests(uid: uid, success: { (requests) in
            self.requests = requests
            DispatchQueue.main.async {
                self.refresher.endRefreshing()
            }
        }) { (error) in
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.refresher.endRefreshing()
            }
        }
    }
    
    @IBAction func onAddPressed(_ sender: Any) {
        addFriends()
    }
    
    func addFriends() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            for fuid in selectedFriends {
                DataService.sharedInstance.requestFriend(uid: uid, friendUid: fuid, success: {
                    // TODO: Show successful add
                    self.queryForSearch()
                }) { (error) in
                    // TODO: Show error adding friend
                    print(error.localizedDescription)
                }
            }
            
        case 2:
            for puid in selectedFriends {
                DataService.sharedInstance.respondFriendRequest(uid: uid, friendUid: puid, accept: true, success: {
                     // TODO: Show successful accept
                    self.getRequests()
                }) { (error) in
                    // TODO: Show error accepting friend
                    print(error.localizedDescription)
                }
            }
            
            /*for cell in tableView.visibleCells {
                if cell.accessoryType == .checkmark {
                    tableView.deleteRows(at: [tableView.indexPath(for: cell)!], with: .automatic)
                }
            }*/
        default:
            return
        }
    }
    
    @IBAction func denyPressed(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        for duid in selectedFriends {
            DataService.sharedInstance.respondFriendRequest(uid: uid, friendUid: duid, accept: false, success: {
                // TODO: Show successful reject
                self.getRequests()
            }) { (error) in
                // TODO: Show error rejecting friend
                print(error.localizedDescription)
            }
        }
        
        /*for cell in tableView.visibleCells {
            if cell.accessoryType == .checkmark {
                tableView.deleteRows(at: [tableView.indexPath(for: cell)!], with: .automatic)
            }
        }*/
        
    }
    
}

extension FriendsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }
        
        self.searchString = searchString
        
        // Check if user is still actively typing... if so, delay the call by one second:
        if let timer = timerToQuery {
            timer.invalidate()
        }
        
        timerToQuery = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.queryForSearch), userInfo: nil, repeats: false)
    }
    
    // The following functions are called after 1 second delay of user typing
    
    
    @objc func queryForSearch() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if searchString == "" {
                self.setterQueue.sync {
                    self.friends = []
                }
            } else {
                // Get friends from DataService and set friends array to results using searchString
                //self.friends = []
                
            }
        case 1:
            if searchString == "" {
                self.setterQueue.sync {
                    self.findFriends = []
                }
            } else {
                self.findFriends = []
               // Search all users using searchString and set searchResults array
                DataService.sharedInstance.searchForUsers(uid: uid, name: searchString, success: { (users) in
                    self.findFriends = users
                }) { (error) in
                    // TODO: Show error searching
                    print(error.localizedDescription)
                }
            }
        default:
            break
        }
    }
}

extension FriendsViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        getFriends()
        self.findFriends = []
        self.addButton.isHidden = true
    }
}
