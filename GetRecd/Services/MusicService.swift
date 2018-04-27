//
//  MusicService.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/20/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import StoreKit
import MediaPlayer
import SafariServices
import FirebaseAuth

class MusicService: NSObject, SPTAudioStreamingDelegate {
    
    static var sharedInstance = MusicService()
    
    var spotifyAuth: SPTAuth!
    var spotifyPlayer: SPTAudioStreamingController!
    
    func setupSpotify() {
        spotifyAuth = SPTAuth.defaultInstance()
        spotifyPlayer = SPTAudioStreamingController.sharedInstance()
        spotifyAuth.clientID = "b2a4e9e6c816448cb0ee30b7f62d25b1"
        spotifyAuth.redirectURL = URL(string: "GetRecd://spotify")!
        spotifyAuth.sessionUserDefaultsKey = "spotify_session"
        spotifyAuth.tokenSwapURL = URL(string: "https://getrecdspotifyrefresher.herokuapp.com/swap")
        spotifyAuth.tokenRefreshURL = URL(string: "https://getrecdspotifyrefresher.herokuapp.com/refresh")
        spotifyAuth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistReadPrivateScope]
        spotifyPlayer.delegate = self
        //spotifyPlayer.playbackDelegate = self
        
        if spotifyPlayer.initialized {
            try? spotifyPlayer.stop()
        }
        
        do {
            try spotifyPlayer.start(withClientId: MusicService.sharedInstance.spotifyAuth.clientID)
        } catch let error {
            assert(false, "There was a problem starting the Spotify SDK: \(error.localizedDescription)")
        }
        
        if let sessionObj = UserDefaults.standard.object(forKey: "spotify_session") {
            let sessionDataObj = sessionObj as! Data
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            spotifyAuth.session = session
            
            if !spotifyAuth.session.isValid() {
                spotifyAuth.renewSession(spotifyAuth.session) { (error, session) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else if let session = session {
                        self.spotifyAuth.session = session
                        self.spotifyPlayer.login(withAccessToken: self.spotifyAuth.session.accessToken)
                    }
                }
            } else {
                spotifyPlayer.login(withAccessToken: spotifyAuth.session.accessToken)
            }
        } 
    }
    
    func isSpotifyLoggedIn() -> Bool {
        return (spotifyAuth.session != nil && spotifyAuth.session.isValid())
    }
    
    func authenticateSpotify() {
        if !isSpotifyLoggedIn() {
            var authURL: URL!
            if UIApplication.shared.canOpenURL(NSURL(string:"spotify:")! as URL) {
                authURL = spotifyAuth.spotifyAppAuthenticationURL()
            } else {
                authURL = spotifyAuth.spotifyWebAuthenticationURL()
            }
            UIApplication.shared.open(authURL!, options: [:], completionHandler: nil)
        } else {
            spotifyPlayer.login(withAccessToken: spotifyAuth.session.accessToken)
        }
    }
    
    func deAuthenticateSpotify() {
        spotifyAuth.session = nil
        UserDefaults.standard.removeObject(forKey: "spotify_session")
        UserDefaults.standard.synchronize()
        
    }
    
    func searchSpotify(with term: String, completion: @escaping CatalogSearchCompletionHandler) {
        if spotifyAuth.session == nil {
            completion([], nil)
            return
        }
        let request = try? SPTSearch.createRequestForSearch(withQuery: term, queryType: .queryTypeTrack, accessToken: spotifyAuth.session.accessToken)
        
        let task = URLSession.shared.dataTask(with: request!) { (data, response, error) in
            
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                completion([], error)
                return
            }
            
            do {
                let results = try! SPTSearch.searchResults(from: data!, with: response!, queryType: .queryTypeTrack)
                let tracks = results.items as! [SPTPartialTrack]
                
                var songResult = [Song]()
                for track in tracks {
                    songResult.append(try Song(spotifyData: track))
                }
                completion(songResult, nil)
            } catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
            
        }
        
        task.resume()
    }
    
    func getSpotifyTrack(with id: String, completion: @escaping (Song) -> ()) {
        if isSpotifyLoggedIn() {
            SPTTrack.track(withURI: URL(string: "spotify:track:\(id)")!, accessToken: spotifyAuth.session.accessToken, market: nil, callback: { (error, data) in
                if let error = error {
                    print(error.localizedDescription)
                } else if let data = data {
                    let track = data as! SPTPartialTrack
                    let song = try! Song(spotifyData: track)
                    
                    completion(song)
                }
            })
        }
    }
    
    func checkIfSpotifyPlaylistExists(exists: @escaping (Bool)->()) {
        SPTPlaylistList.playlists(forUser: spotifyAuth.session.canonicalUsername, withAccessToken: spotifyAuth.session.accessToken) { (error, playlistsObject) in
            if let error = error {
                print(error.localizedDescription)
            } else if let playlistsPage = playlistsObject as? SPTPlaylistList {
                for item in playlistsPage.items {
                    let playlist = item as! SPTPartialPlaylist
                    if playlist.name == "GetRec'd" {
                        exists(true)
                        return
                    }
                }

                exists(false)

                /*
                let semaphore = DispatchSemaphore(value: 1)
                while playlistsPage.hasNextPage {
                    semaphore.wait()
                    
                    playlistsPage.requestNextPage(withAccessToken: self.spotifyAuth.session.accessToken, callback: { (error, newPlaylistsObject) in
                        if newPlaylistsObject != nil {
                            playlistsPage = newPlaylistsObject as! SPTPlaylistList
                            for item in playlistsPage.items {
                                let playlist = item as! SPTPartialPlaylist
                                print(playlist.name)
                                if playlist.name == "GetRec'd" {
                                    exists(true)
                                    return
                                } else {
                                    print("name is not get recd")
                                }
                            }
                        }
                        semaphore.signal()

                    })
                }

                     */
                exists(false)
            }
        }
    }
    
    func createSpotifyPlaylist(success: @escaping ()->(), failure: @escaping (Error)->()) {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        
        SPTPlaylistList.createPlaylist(withName: "GetRec'd", forUser: spotifyAuth.session.canonicalUsername, publicFlag: false, accessToken: spotifyAuth.session.accessToken) { (error, playlistSnapshot) in
            if let error = error {
                failure(error)
            } else if let playlistSnapshot = playlistSnapshot {
                DataService.sharedInstance.setUserSpotifyPlaylist(uid: uid, uri: playlistSnapshot.uri.absoluteString, success: {
                    success()
                }, failure: { (error) in
                    failure(error)
                })
            }
        }
    }
    
    func addToSpotifyPlaylist(songs: Set<String>, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        var tracks = [SPTTrack]()
        let trackgroup = DispatchGroup()
        for song in songs {
            trackgroup.enter()
            SPTTrack.track(withURI: URL(string: "spotify:track:\(song)")!, accessToken: spotifyAuth.session.accessToken, market: nil, callback: { (error, data) in
                if let error = error {
                    failure(error)
                    return
                } else if let data = data {
                    let track = data as! SPTTrack
                    tracks.append(track)
                    trackgroup.leave()
                }
            })
        }
        
        
        trackgroup.notify(queue: DispatchQueue .global()) {
            guard let uid = Auth.auth().currentUser?.uid else {
                // TODO: Show error in getting current user's uid
                return
            }
            
            DataService.sharedInstance.getUserSpotifyPlaylist(uid: uid, success: { (uri) in
                let request = try? SPTPlaylistSnapshot.createRequest(forAddingTracks: tracks, toPlaylist: URL(string: uri)!, withAccessToken: self.spotifyAuth.session.accessToken)
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request!, completionHandler: { (data, response, error) in
                    if let error = error {
                        failure(error)
                    } else {
                        success()
                    }
                })
                
                task.resume()
            }, failure: { (error) in
                failure(error)
            })
        }
    }
    
    func playSpotify(id: String) {
//        spotifyPlayer.skipNext { (error) in
//            if let error = error {
//                print(error.localizedDescription)
//            }
//        }
        appleMusicPlayer.stop()
        
        spotifyPlayer.playSpotifyURI("spotify:track:\(id)" , startingWith: 0, startingWithPosition: 0) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
       
    }
    
    func getSpotifyRecommendations(uid: String, completion: @escaping CatalogSearchCompletionHandler) {
        if self.spotifyAuth.session == nil {
            completion([], nil)
            return
        }
        DataService.sharedInstance.getLikedSpotifySongs(uid: uid, sucesss: { (songs) in
            var recommendURLComponents = URLComponents(string: "https://api.spotify.com/v1/recommendations")
            var tracksString = ""
            var newSongs = [String]()
            var selectedSongs = [String]()
            newSongs += songs
            DataService.sharedInstance.getContentWithRating(uid: uid, contentType: DataService.ContentType.SpotifySong, minimumRating: 3, success: { (recommendedIds) in
                for recommendedId in recommendedIds {
                    for _ in 1...3 {
                        newSongs.append(recommendedId)
                    }
                }
                
                if songs.count > 5 {
                    for _ in 0...4 {
                        let index = Int(arc4random_uniform(UInt32(newSongs.count)))
                        if !selectedSongs.contains(newSongs[index]) {
                            selectedSongs.append(newSongs[index])
                            if (tracksString == "") {
                                tracksString.append(songs[index])
                            } else {
                                tracksString.append(",\(songs[index])")
                            }
                        }
                    }
                } else {
                    for song in newSongs {
                        if (tracksString == "") {
                            tracksString.append(song)
                        } else {
                            tracksString.append(",\(song)")
                        }
                    }
                }
                recommendURLComponents?.queryItems = [URLQueryItem(name: "seed_tracks", value: tracksString)]
                let recommendURL = recommendURLComponents!.url!
                var recommendRequest = URLRequest(url: recommendURL)
                recommendRequest.addValue("Bearer \(self.spotifyAuth.session.accessToken!)", forHTTPHeaderField: "Authorization")
                print(recommendRequest)
                let recommendSession = URLSession(configuration: .default)
                let task = recommendSession.dataTask(with: recommendRequest, completionHandler: { (data, response, error) in
                    var trackResults = [Song]()
                    if let error = error {
                        completion(trackResults, error)
                    } else if let data = data {
                        if let trackJSON = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            if let tracks = trackJSON["tracks"] as? [[String: Any]] {
                                
                                for track in tracks {
                                    let newTrack = try! SPTPartialTrack(fromDecodedJSON: track)
                                    trackResults.append(try! Song(spotifyData: newTrack))
                                }
                                
                                completion(trackResults, nil)
                                return
                            }
                            
                            completion(trackResults, nil)
                        }
                    }
                })
                
                task.resume()
            }, failure: { (error) in completion([], error) })
        }) { (error) in completion([], error) }
    }
    
    // Apple Music stuff
    /// The base URL for all Apple Music API network calls.
    static let appleMusicAPIBaseURLString = "api.music.apple.com"
    
    /// The Apple Music API endpoint for requesting a list of recently played items.
    let recentlyPlayedPathURLString = "/v1/me/recent/played"
    
    /// The Apple Music API endpoint for requesting a the storefront of the currently logged in iTunes Store account.
    let userAppleStorefrontPathURLString = "/v1/me/storefront"
    
    /// The instance of `SKCloudServiceController` that will be used for querying the available `SKCloudServiceCapability` and Storefront Identifier.
    let cloudServiceController = SKCloudServiceController()
    
    /// The current set of `SKCloudServiceCapability` that the sample can currently use.
    var cloudServiceCapabilities = SKCloudServiceCapability()
    
    /// The current set of two letter country code associated with the currently authenticated iTunes Store account.
    var cloudServiceStorefrontCountryCode = "us"
    
    /// The Music User Token associated with the currently signed in iTunes Store account.
    var userToken = ""
    
    /// The `UserDefaults` key for storing and retrieving the Music User Token associated with the currently signed in iTunes Store account.
    static let userTokenUserDefaultsKey = "UserTokenUserDefaultsKey"
    
    /// The completion handler that is called when an Apple Music Catalog Search API call completes.
    typealias CatalogSearchCompletionHandler = (_ mediaItems: [Song], _ error: Error?) -> Void
    
    /// The completion handler that is called when an Apple Music Get User Storefront API call completes.
    typealias GetUserStorefrontCompletionHandler = (_ storefront: String?, _ error: Error?) -> Void
    
    let appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
    
    /// The instance of `URLSession` that is going to be used for making network calls.
    lazy var urlSession: URLSession = {
        // Configure the `URLSession` instance that is going to be used for making network calls.
        let urlSessionConfiguration = URLSessionConfiguration.default
        
        return URLSession(configuration: urlSessionConfiguration)
    }()
    
    func fetchAppleMusicDeveloperToken() -> String {
        return "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjJXOVhNOUREWEgifQ.eyJpYXQiOjE1MTkzNTMwMjUsImV4cCI6MTUzNDkwNTAyNSwiaXNzIjoiM1lDOUs0OTUyWSJ9.5ZimoR8HAqGeMbEucflL1_y6VXIGPKjNaf8VTDpfUTnwE7Ds-5dNYen46FwO4fOAYP4XJrbQCTNnPMbXZR3ZAQ"
    }
    
    func setupAppleMusic() {
        
        appleMusicPlayer.beginGeneratingPlaybackNotifications()
        if SKCloudServiceController.authorizationStatus() == .authorized {
            if let token = UserDefaults.standard.string(forKey: MusicService.userTokenUserDefaultsKey) {
                userToken = token
                if self.cloudServiceStorefrontCountryCode == "" {
                    self.requestAppleStorefrontCountryCode(success: {
                    }, failure: { (error) in
                        print(error.localizedDescription)
                    })
                }
            }
        }
    }
    
    func isAppleMusicLoggedIn() -> Bool {
        return userToken != ""
    }
    
    func requestAppleUserToken(success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let developerToken = fetchAppleMusicDeveloperToken()
        cloudServiceController.requestUserToken(forDeveloperToken: developerToken) { (userToken, error) in
            if let error = error {
                failure(error)
            } else if let userToken = userToken {
                self.userToken = userToken
                
                let userDefaults = UserDefaults.standard
                
                userDefaults.set(userToken, forKey: MusicService.userTokenUserDefaultsKey)
                userDefaults.synchronize()
                
                if self.cloudServiceStorefrontCountryCode == "" {
                    self.requestAppleStorefrontCountryCode(success: {
                        success()
                    }, failure: { (error) in
                        failure(error)
                    })
                }
            }
        }
    }
    
    func deAuthenticateAppleMusic() {
        userToken = ""
        UserDefaults.standard.removeObject(forKey: MusicService.userTokenUserDefaultsKey)
        UserDefaults.standard.synchronize()
        
    }
    func requestAppleStorefrontCountryCode(success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        cloudServiceController.requestStorefrontCountryCode { (countryCode, error) in
            if let error = error {
                failure(error)
            } else if let countryCode = countryCode {
                self.cloudServiceStorefrontCountryCode = countryCode
            } else {
                self.cloudServiceStorefrontCountryCode = "us"
            }
        }
    }
    
    func requestAppleCloudServiceAuthorization(success: @escaping (Bool) -> (), failure: @escaping (Error) -> ()) {
        SKCloudServiceController.requestAuthorization { (status: SKCloudServiceAuthorizationStatus) in
            switch status {
            case .notDetermined:
                success(false)
                break
            case .denied:
                success(false)
                break
            case .restricted:
                success(false)
                break
            case .authorized:
                self.cloudServiceController.requestCapabilities(completionHandler: { (cloudServiceCapability, error) in
                    guard error == nil else {
                        fatalError("An error occurred when requesting capabilities: \(error!.localizedDescription)")
                    }
                    
                    self.cloudServiceCapabilities = cloudServiceCapability
                    
                    self.requestAppleUserToken(success: {
                        success(true)
                    }, failure: { (error) in
                        failure(error)
                    })
                })
            }
        }
        
    }
    
    func createAppleSearchRequest(with term: String, countryCode: String, developerToken: String) -> URLRequest {
        
        // Create the URL components for the network call.
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = MusicService.appleMusicAPIBaseURLString
        urlComponents.path = "/v1/catalog/\(countryCode)/search"
        
        let expectedTerms = term.replacingOccurrences(of: " ", with: "+")
        let urlParameters = ["term": expectedTerms,
                             "limit": "10",
                             "types": "songs"]
        
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        urlComponents.queryItems = queryItems
        
        // Create and configure the `URLRequest`.
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
    
    func performAppleMusicCatalogSearch(with term: String, countryCode: String, completion: @escaping CatalogSearchCompletionHandler) {
        if userToken == "" {
            completion([], nil)
            return
        }
        let developerToken = fetchAppleMusicDeveloperToken()
        let urlRequest = createAppleSearchRequest(with: term, countryCode: countryCode, developerToken: developerToken)
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                completion([], error)
                return
            }
            
            do {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                let results = json["results"] as! [String: Any]
                let songs = results["songs"] as! [String: Any]
                let data = songs["data"] as! [[String: Any]]
                var songResult = [Song]()
                for songData in data {
                    songResult.append(try Song(appleMusicData: songData))
                }
                
                completion(songResult, nil)
            } catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func getAppleMusicTrack(with id: String, completion: @escaping (Song) -> ()) {
        
        let developerToken = fetchAppleMusicDeveloperToken()
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = MusicService.appleMusicAPIBaseURLString
        urlComponents.path = "/v1/catalog/us/songs/\(id)"
        
        // Create and configure the `URLRequest`.
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        
        urlRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                return
            }
            
            do {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                let data = json["data"] as! [[String: Any]]
                completion(try Song(appleMusicData: data[0]))
            } catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func getAppleMusicRecommendations(completion: @escaping CatalogSearchCompletionHandler) {
        if userToken == "" {
            completion([], nil)
            return
        }
        let developerToken = fetchAppleMusicDeveloperToken()
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = MusicService.appleMusicAPIBaseURLString
        urlComponents.path = "/v1/me/recommendations"
        
        // Create and configure the `URLRequest`.
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        
        urlRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue(userToken, forHTTPHeaderField: "Music-User-Token")
        
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                return
            }
            
            do {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                let data = json["data"] as! [[String: Any]]
                let newReleases = data[4]
                let relationships = newReleases["relationships"] as! [String: Any]
                let contents = relationships["contents"] as! [String: Any]
                let insideData = contents["data"] as! [[String: Any]]
                 var songResult = [Song]()
                for songData in insideData {
                    songResult.append(try Song(appleMusicData: songData))
                }
                completion(songResult, nil)
            } catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
   
    func playAppleMusic(id: String) {
        let catalogQueueDescriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [id])
        appleMusicPlayer.setQueue(with: catalogQueueDescriptor)
        appleMusicPlayer.play()
        self.appleMusicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    var spotifySongs: [(id: String, type: Song.SongType)] = []
    var csp = 0
    var currId: UInt64?
    func playListOfSong(songIds: [(id: String, type: Song.SongType)]) {
        let appleMusicSongs = songIds.filter { (song) -> Bool in
            return song.type == .AppleMusic
        }
        
        spotifySongs = songIds.filter { (song) -> Bool in
            return song.type == .Spotify
        }
        
        csp = 0
        
        let catalogQueueDescriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [])
        
        for song in appleMusicSongs {
            catalogQueueDescriptor.storeIDs?.append(song.id)
        }
        
        appleMusicPlayer.setQueue(with: catalogQueueDescriptor)
        appleMusicPlayer.play()
        currId = appleMusicPlayer.nowPlayingItem?.persistentID
        NotificationCenter.default.addObserver(self, selector: #selector(switchToSpotify), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        
    }
    
    @objc func switchToSpotify() {
        if appleMusicPlayer.nowPlayingItem?.persistentID != currId {
            appleMusicPlayer.stop()
            if (csp < spotifySongs.count) {
                spotifyPlayer.playSpotifyURI("spotify:track:\(spotifySongs[csp].id)" , startingWith: 0, startingWithPosition: 0, callback: nil)
                csp += 1
            } else {
                appleMusicPlayer.play()
            }
        }
    }
}

extension MusicService: SPTAudioStreamingPlaybackDelegate {
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        appleMusicPlayer.play()
        currId = appleMusicPlayer.nowPlayingItem?.persistentID
    }
}
