//
//  ProfileMusicViewController.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileMusicViewController: UITableViewController {

    var songIds = [(String, Song.SongType)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        SongCell.currPlaying = -1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        DataService.sharedInstance.getLikedSongs(uid: uid, sucesss: { (songIds) in
            self.songIds = songIds
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) { (error) in
            // TODO: Show error on get liked songs
            print(error.localizedDescription)
        }
    }
    @IBAction func onCheck(_ sender: Any) {
       navigationController?.popViewController(animated: true)
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
        cell.tag = indexPath.row
        
        let song = songIds[indexPath.row]
        
        if song.1 == .Spotify {
            
            MusicService.sharedInstance.getSpotifyTrack(with: song.0) { (song) in
                DispatchQueue.main.async {
                    cell.song = song
                }
            }
        } else {
            MusicService.sharedInstance.getAppleMusicTrack(with: song.0) { (song) in
                DispatchQueue.main.async {
                    cell.song = song
                }
            }
        }
        return cell
    }
    
    @IBAction func onPlayAll(_ sender: Any) {
        MusicService.sharedInstance.playListOfSong(songIds: songIds)
    }
}
