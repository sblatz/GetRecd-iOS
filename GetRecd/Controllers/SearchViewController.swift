//
//  SearchViewController.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class SearchViewController: UITableViewController {
    
    @IBOutlet weak var likeButton: UIButton!
    
    var searchController = UISearchController(searchResultsController: nil)
    var timerToQueryMusic: Timer?
    var searchString = ""

    /// A `DispatchQueue` used for synchornizing the setting of `mediaItems` to avoid threading issues with various `UITableView` delegate callbacks.
    var setterQueue = DispatchQueue(label: "SearchViewController")
    
    var songs = [Song]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var likedAppleMusicSongs = Set<String>()
    var likedSpotifySongs = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.delegate = self
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onArtTap(_ sender: Any) {
        let gesture = sender as! UITapGestureRecognizer
        let cell = gesture.view!.superview!.superview as! SongCell
        
        //MusicService.sharedInstance.playPreview(url: cell.song.preview)
    }
    
    @IBAction func onAdd(_ sender: Any) {
        DataService.instance.likeSongs(appleMusicSongs: likedAppleMusicSongs, spotifySongs: likedSpotifySongs, success: {
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print(songs.count)
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? SongCell {

            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                switch cell.song.type {
                    case .AppleMusic:
                        likedAppleMusicSongs.remove(cell.song.id)
                    case .Spotify:
                        likedSpotifySongs.remove(cell.song.id)
                    default:
                        break
                }
            } else {
                cell.accessoryType = .checkmark
                switch cell.song.type {
                    case .AppleMusic:
                        likedAppleMusicSongs.insert(cell.song.id)
                    case .Spotify:
                        likedSpotifySongs.insert(cell.song.id)
                    default:
                        break
                }
            }
        }
        
        if likedAppleMusicSongs.count > 0 || likedSpotifySongs.count > 0 {
            likeButton.isHidden = false
        } else {
            likeButton.isHidden = true
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell

        // Reset the cell from previous use:
        cell.artistLabel.text = ""
        cell.artworkView.image = UIImage()
        cell.nameLabel.text = ""

        cell.tag = indexPath.row
        cell.artworkView.tag = indexPath.row
        let song = songs[indexPath.row]
        cell.song = song
        return cell
    }
}

extension SearchViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }

        self.searchString = searchString

        // Check if user is still actively typing... if so, delay the call by one second:
        if let timer = timerToQueryMusic {
            timer.invalidate()
        }

        timerToQueryMusic = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(queryForMusic), userInfo: nil, repeats: false)
    }

    // Function called after 1 second delay of user typing
    @objc func queryForMusic() {
        if searchString == "" {
            self.setterQueue.sync {
                self.songs = []
            }
        } else {
            MusicService.sharedInstance.searchSpotify(with: searchString) { (spotifySongs, error) in
                guard error == nil else {
                    print(error)
                    self.songs = []
                    return
                }
                MusicService.sharedInstance.performAppleMusicCatalogSearch(with: self.searchString, countryCode: MusicService.sharedInstance.cloudServiceStorefrontCountryCode, completion: {(appleMusicSongs, error) in
                    guard error == nil else {
                        self.songs = []
                        return
                    }
                    var newResult = appleMusicSongs + spotifySongs
                    newResult.sort(by: { (first, second) -> Bool in
                        return first.name < second.name
                    })
                    self.songs = newResult
                })
            }
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.songs = []
    }
}
