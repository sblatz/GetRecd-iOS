//
//  ProfileShowsViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class ProfileShowsViewController: UITableViewController {
    var showIds = [(String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DataService.instance.getLikedShows { (showIds) in
            self.showIds = showIds
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    @IBAction func onCheck(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 1
        }
        return showIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "BarCell", for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

        let show = showIds[indexPath.row]

        TVService.sharedInstance.getShow(with: show) { (show) in
            cell.show = show
        }

        return cell
    }
}
