//
//  ProfileShowsViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileShowsViewController: UITableViewController {
    var showIds = [(String)]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.navigationItem.hidesBackButton = true
        let saveButton = UIButton(type: .custom)
        saveButton.frame = CGRect(x: 0.0, y: 0.0, width: 35, height: 35)
        saveButton.setImage(UIImage(named:"save-button"), for: .normal)
        saveButton.addTarget(self, action: #selector(onCheck(_:)), for: .touchUpInside)
        
        let navBarItem = UIBarButtonItem(customView: saveButton)
        let currWidth = navBarItem.customView?.widthAnchor.constraint(equalToConstant: 24)
        currWidth?.isActive = true
        let currHeight = navBarItem.customView?.heightAnchor.constraint(equalToConstant: 24)
        currHeight?.isActive = true
        self.navigationItem.rightBarButtonItem = navBarItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DataService.sharedInstance.getLikedShows(uid: Auth.auth().currentUser!.uid, sucesss: { (showIds) in
            self.showIds = showIds
        }) { (error) in
            // TODO: Show error that liked shows not appearing
            print(error.localizedDescription)
        }
        
    }

    @IBAction func onCheck(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return showIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

        let show = showIds[indexPath.row]

        TVService.sharedInstance.getShow(with: show) { (show) in
            cell.show = show
        }

        return cell
    }
}
