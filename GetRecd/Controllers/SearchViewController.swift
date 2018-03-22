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


    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var searchController = UISearchController(searchResultsController: nil)
    var timerToQuery: Timer?
    var searchString = ""

    /// A `DispatchQueue` used for synchornizing the setting of `mediaItems` to avoid threading issues with various `UITableView` delegate callbacks.
    var setterQueue = DispatchQueue(label: "SearchViewController")

    var movies = [Movie]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

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

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 100))
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true

        let searchBar = searchController.searchBar

        headerView.addSubview(searchBar)
        headerView.addSubview(segmentedControl)

        searchBar.alpha = 0
        searchBar.delegate = self

        let constraint1 = NSLayoutConstraint(item: searchBar, attribute: .top, relatedBy: .equal, toItem: headerView, attribute: .top, multiplier: 1, constant: 0)
        let constraint2 = NSLayoutConstraint(item: segmentedControl, attribute: .top, relatedBy: .equal, toItem: headerView, attribute: .top, multiplier: 1, constant: 0)
        let constraint3 = NSLayoutConstraint(item: segmentedControl, attribute: .bottom, relatedBy: .equal, toItem: headerView, attribute: .bottom, multiplier: 1, constant: 0)

        let constraint4 = NSLayoutConstraint(item: segmentedControl, attribute: .centerX, relatedBy: .equal, toItem: headerView, attribute: .centerX, multiplier: 1, constant: 0)

        let constraint5 = NSLayoutConstraint(item: segmentedControl, attribute: .width, relatedBy: .equal, toItem: headerView, attribute: .width, multiplier: 1, constant: 0)

        headerView.addConstraints([constraint1, constraint2, constraint3, constraint4, constraint5])

        //tableView.tableHeaderView = searchController.searchBar
        //tableView.tableHeaderView = segmentedControl

        tableView.tableHeaderView = headerView

        view.layoutIfNeeded()
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
        switch segmentedControl.selectedSegmentIndex {
            case 0:
                return songs.count
            case 1:
                return movies.count
            default:
                return 0
        }
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

        switch segmentedControl.selectedSegmentIndex {
            case 0:
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
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

                // Reset the cell from previous use:
                cell.releaseLabel.text = ""
                cell.nameLabel.text = ""
                cell.artworkView.image = UIImage()

                cell.tag = indexPath.row
                cell.artworkView.tag = indexPath.row
                let movie = movies[indexPath.row]
                cell.movie = movie
                return cell
            default:
                return UITableViewCell()
        }
    }
}

extension SearchViewController: UISearchResultsUpdating {

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
        switch segmentedControl.selectedSegmentIndex {
        case 0:
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
        case 1:
            if searchString == "" {
                self.setterQueue.sync {
                    self.songs = []
                }
            } else {
                MovieService.sharedInstance.searchTMDB(forMovie: searchString, completion: { (movies, error) in
                    guard error == nil else {
                        print(error)
                        self.movies = []
                        return
                    }

                    if let movieArray = movies {
                        self.movies = movieArray.sorted(by: { (first, second) -> Bool in
                            return first.name < second.name
                        })
                    }
                })
            }
        default:
            break
        }

    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.songs = []
    }
}
