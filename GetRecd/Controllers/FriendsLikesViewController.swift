//
//  FriendsLikesViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 4/16/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class FriendsLikesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var recsButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!


    var user = ""
    var showingLikes = true

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
        if showingLikes {
            recsButton.title = "Likes"

        } else {
            recsButton.title = "Recs"
        }


        if songs.isEmpty || movies.isEmpty || shows.isEmpty {
            DataService.sharedInstance.getUser(uid: user, success: { (user) in
                if !user.privateMovies {
                    self.getRecommendedMovies()
                }

                if !user.privateMusic {
                    self.getRecommendedSongs()
                }

                if !user.privateShows {
                    self.getRecommendedShows()
                }

                self.showingLikes = !self.showingLikes

                self.tableView.reloadData()
            }) { (error) in
                print(error)
            }
        } else {
            self.tableView.reloadData()
        }
    }

    @IBAction func didChangeSegment(_ sender: Any) {
        tableView.reloadData()
    }

    // Table View Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showingLikes {
            switch segmentedControl.selectedSegmentIndex {
                case 0:
                    if songIds.count == 0 {
                        return 1
                    } 
                    return songIds.count
                case 1:
                    if movieIds.count == 0 {
                        return 1
                    }
                    return movieIds.count
                case 2:
                    if showIds.count == 0 {
                        return 1
                    }
                    return showIds.count
                default:
                    return 0
            }
        } else {
            switch segmentedControl.selectedSegmentIndex {
                case 0:
                    if songs.count == 0 {
                        return 1
                    }
                    return songs.count
                case 1:
                    if movies.count == 0 {
                        return 1
                    }
                    return movies.count
                case 2:
                    if shows.count == 0 {
                        return 1
                    }
                    return shows.count
                default:
                    return 0
                }
            }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if showingLikes {
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                if songIds.count == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! UITableViewCell

                    cell.textLabel?.text = "This user has chosen to hide their music."
                    return cell

                }
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

            case 1:
                if movieIds.count == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! UITableViewCell

                    cell.textLabel?.text = "This user has chosen to hide their movies."
                    return cell

                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
                let movie = movieIds[indexPath.row]

                MovieService.sharedInstance.getMovie(with: movie) { (movie) in
                    cell.movie = movie
                }

                return cell
            case 2:
                if showIds.count == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! UITableViewCell

                    cell.textLabel?.text = "This user has chosen to hide their shows."
                    return cell

                }

                let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
                let show = showIds[indexPath.row]

                TVService.sharedInstance.getShow(with: show) { (show) in
                    cell.show = show
                }

                return cell
            default:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieCell else { return MovieCell() }
                return cell
            }
        } else {
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                if songs.count == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! UITableViewCell

                    cell.textLabel?.text = "This user has chosen to hide their music."
                    return cell

                }

                let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
                cell.tag = indexPath.row
                cell.song = songs[indexPath.row]

                return cell

            case 1:
                if movies.count == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! UITableViewCell

                    cell.textLabel?.text = "This user has chosen to hide their movies."
                    return cell

                }

                let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
                cell.movie = movies[indexPath.row]

                return cell
            case 2:
                if shows.count == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! UITableViewCell

                    cell.textLabel?.text = "This user has chosen to hide their shows."
                    return cell

                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
                cell.show = shows[indexPath.row]

                return cell
            default:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieCell else { return MovieCell() }
                return cell
            }
        }

        return UITableViewCell()
    }

    // MARK: - Recommendations

    func getRecommendedMovies() {
        DataService.sharedInstance.getLikedMovies(uid: user, sucesss: { (likedMovies) in
            self.movies = []

            // add top 5 recommended movies if they have less than 5 saved movies, else add top 2 if less than 10, else top 1
            // Checks to make sure that reccomended movies aren't shown more than once and that user has not already liked them

            for id in self.movieIds {
                MovieService.sharedInstance.getRecommendedMovies(id: id, success: { (movies) in
                    for i in 0..<movies.count {

                        let movieArrcontains = self.movies.contains(where: { (movie) -> Bool in
                            return movie.id == movies[i].id
                        })

                        let likedArrContains = likedMovies.contains(where: { (id) -> Bool in
                            return Int(id) == movies[i].id
                        })

                        if !movieArrcontains && !likedArrContains {
                            self.movies.append(movies[i])
                        }

                        if likedMovies.count < 5, self.movies.count == 5 {
                            break
                        } else if likedMovies.count < 10, self.movies.count == 2 {
                            break
                        } else if self.movies.count == 1 {
                            break
                        }
                    }
                })
            }
        }) { (error) in
            // TODO: Show error
            print(error.localizedDescription)
        }
    }

    func getRecommendedSongs() {
        let songSearchGroup = DispatchGroup()
        var newSongs: [Song] = []
        songSearchGroup.enter()
        MusicService.sharedInstance.getSpotifyRecommendations(uid: user) { (spotifySongs, error) in
            if let error = error {
                print(error.localizedDescription)
                self.songs = []
                return
            } else {
                newSongs.append(contentsOf: spotifySongs)
                songSearchGroup.leave()
            }
        }

        songSearchGroup.enter()
        MusicService.sharedInstance.getAppleMusicRecommendations { (appleMusicSongs, error) in
            if let error = error {
                print(error.localizedDescription)
                self.songs = []
                return
            } else {
                newSongs.append(contentsOf: appleMusicSongs)
                songSearchGroup.leave()
            }
        }

        songSearchGroup.notify(queue: DispatchQueue.global()) {
            newSongs.sort(by: { (first, second) -> Bool in
                return first.name < second.name
            })
            DispatchQueue.main.async {
            }
            self.songs = newSongs
        }
    }

    func getRecommendedShows() {
        DataService.sharedInstance.getLikedShows(uid: user, sucesss: { (likedShows) in
            self.shows = []

            // add top 5 recommended shows if they have less than 5 saved movies, else add top 2 if less than 10, else top 1
            // Checks to make sure that reccomended shows aren't shown more than once and that user has not already liked them

            for id in likedShows {
                TVService.sharedInstance.getRecommendedTV(id: id, success: { (shows) in
                    for i in 0..<shows.count {

                        let showArrcontains = self.shows.contains(where: { (show) -> Bool in
                            return show.id == shows[i].id
                        })

                        let likedArrContains = likedShows.contains(where: { (id) -> Bool in
                            return Int(id) == shows[i].id
                        })

                        if !showArrcontains && !likedArrContains {
                            self.shows.append(shows[i])
                        }

                        if likedShows.count < 5, self.shows.count == 5 {
                            break
                        } else if likedShows.count < 10, self.shows.count == 2 {
                            break
                        } else if self.shows.count == 1 {
                            break
                        }
                    }
                })
            }
        }) { (error) in
            // TODO: Show error
            print(error.localizedDescription)
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
