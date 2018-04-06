//
//  ProfileMovieViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileMovieViewController: UITableViewController {

    var movieIds = [(String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        DataService.sharedInstance.getLikedMovies(uid: uid, sucesss: { (movieIds) in
            self.movieIds = movieIds
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) { (error) in
            // TODO: Show error
            print(error.localizedDescription)
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
        return movieIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "BarCell", for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell


        let movie = movieIds[indexPath.row]

        MovieService.sharedInstance.getMovie(with: movie) { (movie) in
            cell.movie = movie
        }

        return cell
    }
}
