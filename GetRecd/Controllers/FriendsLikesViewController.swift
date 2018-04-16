//
//  FriendsLikesViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 4/16/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class FriendsLikesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var user = ""

    var songIds = [(String, Song.SongType)](){
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    var movieIds = [(String)](){
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    var showIds = [(String)]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        DataService.sharedInstance.getUser(uid: user, success: { (user) in
            self.navigationItem.title = user.name + "'s Likes"

            if !user.privateMovies {
                DataService.sharedInstance.getLikedMovies(uid: self.user, sucesss: { (movieIds) in
                    self.movieIds = movieIds
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }) { (error) in
                    // TODO: Show error
                    print(error.localizedDescription)
                }
            }

            if !user.privateMusic {
                DataService.sharedInstance.getLikedSongs(uid: self.user, sucesss: { (songIds) in
                    self.songIds = songIds
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }) { (error) in
                    // TODO: Show error on get liked songs
                    print(error.localizedDescription)
                }
            }

            if !user.privateShows {
                DataService.sharedInstance.getLikedShows(uid: self.user, sucesss: { (showIds) in
                    self.showIds = showIds
                }) { (error) in
                    // TODO: Show error that liked shows not appearing
                    print(error.localizedDescription)
                }
            }
        }) { (error) in
            print(error)
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchButtonPressed(_ sender: Any) {
    }
    
    @IBAction func changedSegment(_ sender: Any) {
        
    }

    // Table View Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
            case 0:
                return songIds.count
            case 1:
                return movieIds.count
            case 2:
                return showIds.count
            default:
                return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch segmentedControl.selectedSegmentIndex {
            case 0:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as? SongCell else { return SongCell() }
                return cell
            case 1:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieCell else { return MovieCell() }
                return cell
            case 2:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieCell else { return MovieCell() }
                return cell
            default:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieCell else { return MovieCell() }
                return cell
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
