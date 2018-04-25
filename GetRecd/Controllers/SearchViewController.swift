//
//  SearchViewController.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth
import WebKit

class SearchViewController: UITableViewController {
    
    @IBOutlet weak var likeButton: UIButton!

    var selectedScope = 0
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

    var shows = [Show]() {
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
    var likedMovies = Set<Int>()
    var likedTVShows = Set<Int>()
    
    let blurEffectView = UIVisualEffectView(effect: nil)
    
    
    var videoView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true

        searchController.searchBar.scopeButtonTitles = ["Music", "Movies", "Shows"]
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.delegate = self
        self.definesPresentationContext = true
        self.navigationItem.searchController = searchController
        tableView.setContentOffset(CGPoint(x: 0, y: -20), animated: true)
        view.layoutIfNeeded()
        
        blurEffectView.isUserInteractionEnabled = true
        blurEffectView.effect = UIBlurEffect(style: .dark)
        //always fill the view
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.blurEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimissTrailer)))
        
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(userScript)
        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController
        wkWebConfig.requiresUserActionForMediaPlayback = false
        
        videoView = WKWebView(frame: CGRect(x: 8, y: (self.view.frame.height / 2) - ((self.view.frame.width - 16) * (9 / 32)), width: self.view.frame.width - 16, height: (self.view.frame.width - 16) * (9 / 16)), configuration: wkWebConfig)
    }



    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchController.searchBar.text = ""
        likedSpotifySongs.removeAll()
        likedAppleMusicSongs.removeAll()
        likedMovies.removeAll()
        likedTVShows.removeAll()
        songs.removeAll()
        movies.removeAll()
        shows.removeAll()

        self.selectedScope = selectedScope
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        SongCell.currPlaying = -1
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onAdd(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        
        switch selectedScope {
        case 0:
            DataService.sharedInstance.likeSongs(uid: uid, appleMusicSongs: likedAppleMusicSongs, spotifySongs: likedSpotifySongs, success: {
                // TODO: Show successful add
                print("Yay")
            }) { (error) in
                print(error.localizedDescription)
            }
        case 1:
            DataService.sharedInstance.likeMovies(uid: uid, movies: likedMovies, success: {
                // TODO: Show successful add
                print("Yay")
            }) { (error) in
                // TODO: Show error on like movies
                print(error.localizedDescription)
            }
        case 2:
            DataService.sharedInstance.likeShows(uid: uid, shows: likedTVShows, success: {
                // TODO: Show successful add
                print("Yay")
            }) { (error) in
                // TODO: Show error on like movies
                print(error.localizedDescription)
            }
        default:
            break
        }

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedScope {
            case 0:
                return songs.count
            case 1:
                return movies.count
            case 2:
                return shows.count
            default:
                return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch selectedScope {
            case 0:
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
        case 1:
            if let cell = tableView.cellForRow(at: indexPath) as? MovieCell {

                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    likedMovies.remove(cell.movie.id)
                } else {
                    cell.accessoryType = .checkmark
                    likedMovies.insert(cell.movie.id)
                }
            }

            if likedMovies.count > 0 {
                likeButton.isHidden = false
            } else {
                likeButton.isHidden = true
            }

            tableView.deselectRow(at: indexPath, animated: true)
        case 2:
            if let cell = tableView.cellForRow(at: indexPath) as? MovieCell {

                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    likedTVShows.remove(cell.show.id)
                } else {
                    cell.accessoryType = .checkmark
                    likedTVShows.insert(cell.show.id)
                }
            }

            if likedTVShows.count > 0 {
                likeButton.isHidden = false
            } else {
                likeButton.isHidden = true
            }

            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch selectedScope {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell

                // Reset the cell from previous use:
                cell.tag = indexPath.row
                
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
                cell.artworkView.isUserInteractionEnabled = true
                cell.artworkView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTrailer(_:))))
                let movie = movies[indexPath.row]
                cell.movie = movie
                return cell
            case 2:
                // Note: we're using a movie cell as a tv show cell as well for efficiency 😄
                let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

                // Reset the cell from previous use:
                cell.releaseLabel.text = ""
                cell.nameLabel.text = ""
                cell.artworkView.image = UIImage()

                cell.tag = indexPath.row
                cell.artworkView.tag = indexPath.row
                let show = shows[indexPath.row]
                cell.show = show
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
        switch selectedScope {
        case 0:
            if searchString == "" {
                self.setterQueue.sync {
                    self.songs = []
                }
            } else {
                let songSearchGroup = DispatchGroup()
                var newSongs: [Song] = []
                songSearchGroup.enter()
                MusicService.sharedInstance.searchSpotify(with: searchString) { (spotifySongs, error) in
                    if error != nil {
                        self.songs = []
                        return
                    } else {
                        newSongs.append(contentsOf: spotifySongs)
                        songSearchGroup.leave()
                    }
                }
                
                songSearchGroup.enter()
                
                MusicService.sharedInstance.performAppleMusicCatalogSearch(with: self.searchString, countryCode: MusicService.sharedInstance.cloudServiceStorefrontCountryCode, completion: {(appleMusicSongs, error) in
                    if error != nil {
                        self.songs = []
                        return
                    } else {
                        newSongs.append(contentsOf: appleMusicSongs)
                        songSearchGroup.leave()
                    }
                    
                })
                
                songSearchGroup.notify(queue: DispatchQueue.global()) {
                    newSongs.sort(by: { (first, second) -> Bool in
                        return first.name < second.name
                    })
                    
                    self.songs = newSongs
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
                        self.shows = []
                        return
                    }

                    if let movieArray = movies {
                        self.movies = movieArray.sorted(by: { (first, second) -> Bool in
                            return first.name < second.name
                        })
                    }
                })
            }
        case 2:
            if searchString == "" {
                self.setterQueue.sync {
                    self.songs = []
                }
            } else {
                TVService.sharedInstance.searchTMDB(forShow: searchString, completion: { (shows, error) in
                    guard error == nil else {
                        print(error)
                        self.shows = []
                        return
                    }

                    if let showArray = shows {
                        self.shows = showArray.sorted(by: { (first, second) -> Bool in
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
        self.movies = []
        self.shows = []
        self.likeButton.isHidden = true
    }
}

extension SearchViewController: UIWebViewDelegate {
    @objc func dimissTrailer() {
        
        videoView.removeFromSuperview()
        blurEffectView.removeFromSuperview()
        
        
    }
    
    @objc func showTrailer(_ sender: Any) {
        let tap = sender as! UITapGestureRecognizer
        let artworkView = tap.view!
        
        let movie = movies[artworkView.tag]
        MovieService.sharedInstance.getVideo(id: movie.id, width: Int(view.frame.width - 16), height: Int((view.frame.width - 16) * (9 / 16)), success: { (htm) in
            
            
            DispatchQueue.main.async {
                
                
                self.blurEffectView.frame = self.view.bounds
                self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                self.view.addSubview(self.blurEffectView) //if you have more UIViews, use an insertSubview
                
                self.videoView.loadHTMLString(htm, baseURL: nil)
                
                self.view.addSubview(self.videoView)
            }
        }) {
            print("Error loading video")
        }
    }
}
