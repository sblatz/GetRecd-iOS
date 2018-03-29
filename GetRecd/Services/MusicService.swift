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
        spotifyAuth.clientID = "ee396a63623f4066a6d5be5d094ffa94"
        spotifyAuth.redirectURL = URL(string: "GetRecd://spotify")!
        spotifyAuth.sessionUserDefaultsKey = "spotify_session"
        spotifyAuth.tokenSwapURL = URL(string: "https://getrecdspotifyrefresher.herokuapp.com/swap")
        spotifyAuth.tokenRefreshURL = URL(string: "https://getrecdspotifyrefresher.herokuapp.com/refresh")
        spotifyAuth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistReadPrivateScope]
        spotifyPlayer.delegate = self
        
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
                print(self.spotifyAuth.session.accessToken)
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
    
    func searchSpotify(with term: String, completion: @escaping CatalogSearchCompletionHandler) {
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
        SPTTrack.track(withURI: URL(string: "spotify:track:\(id)")!, accessToken: spotifyAuth.session.accessToken, market: nil, callback: { (error, data) in
            if let error = error {
                print(error.localizedDescription)
            } else if let data = data {
                let track = data as! SPTTrack
                let song = try! Song(spotifyData: track)
                
                completion(song)
            }
        })
    }
    
    func checkIfSpotifyPlaylistExists(exists: @escaping (Bool)->()) {
        SPTPlaylistList.playlists(forUser: spotifyAuth.session.canonicalUsername, withAccessToken: spotifyAuth.session.accessToken) { (error, playlistsObject) in
            if let error = error {
                print(error.localizedDescription)
            } else if var playlistsPage = playlistsObject as? SPTPlaylistList {
                for item in playlistsPage.items {
                    let playlist = item as! SPTPartialPlaylist
                    if playlist.name == "GetRec'd" {
                        exists(true)
                        return
                    }
                }
                
                let semaphore = DispatchSemaphore(value: 1)
                while playlistsPage.hasNextPage {
                    semaphore.wait()
                    
                    playlistsPage.requestNextPage(withAccessToken: self.spotifyAuth.session.accessToken, callback: { (error, newPlaylistsObject) in
                        if newPlaylistsObject != nil {
                            playlistsPage = newPlaylistsObject as! SPTPlaylistList
                            for item in playlistsPage.items {
                                let playlist = item as! SPTPartialPlaylist
                                if playlist.name == "GetRec'd" {
                                    exists(true)
                                    return
                                } else {
                                    semaphore.signal()
                                }
                            }
                        }
                    })
                }
                
                exists(false)
            }
        }
    }
    
    func createSpotifyPlaylist(success: @escaping ()->(), failure: @escaping (Error)->()) {
        SPTPlaylistList.createPlaylist(withName: "GetRec'd", forUser: spotifyAuth.session.canonicalUsername, publicFlag: false, accessToken: spotifyAuth.session.accessToken) { (error, playlistSnapshot) in
            if let error = error {
                failure(error)
            } else if let playlistSnapshot = playlistSnapshot {
                DataService.instance.setUserSpotifyPlaylist(uid: Auth.auth().currentUser!.uid, uri: playlistSnapshot.uri.absoluteString, success: {
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
            DataService.instance.getUserSpotifyPlaylist(uid: Auth.auth().currentUser!.uid, success: { (uri) in
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
    
    func testSpotify(id: String) {
        spotifyPlayer.playSpotifyURI("spotify:track:\(id)" , startingWith: 0, startingWithPosition: 0) { (error) in
            if let error = error {
                print(error)
            }
        }
    }
    
    func getSpotifyRecommendations(completion: @escaping CatalogSearchCompletionHandler) {
        DataService.instance.getLikedSpotifySongs { (songs) in
            var recommendURLComponents = URLComponents(string: "https://api.spotify.com/v1/recommendations")
            var tracksString = ""
            if songs.count > 5 {
                
            } else {
                for song in songs {
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
            print(self.spotifyAuth.session.accessToken!)
            recommendRequest.addValue("Bearer \(self.spotifyAuth.session.accessToken!)", forHTTPHeaderField: "Authorization")
            print(recommendRequest)
            let recommendSession = URLSession(configuration: .default)
            let task = recommendSession.dataTask(with: recommendRequest, completionHandler: { (data, response, error) in
                var trackResults = [Song]()
                if let error = error {
                    completion(trackResults, error)
                } else if let data = data {
                    if let trackJSON = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let tracks = trackJSON["tracks"] as! [[String: Any]]
                        for track in tracks {
                            let newTrack = try! SPTPartialTrack(fromDecodedJSON: track)
                            trackResults.append(try! Song(spotifyData: newTrack))
                        }
                        
                        completion(trackResults, nil)
                    }
                }
            })
            
            task.resume()
        }
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
    
    /// The instance of `URLSession` that is going to be used for making network calls.
    lazy var urlSession: URLSession = {
        // Configure the `URLSession` instance that is going to be used for making network calls.
        let urlSessionConfiguration = URLSessionConfiguration.default
        
        return URLSession(configuration: urlSessionConfiguration)
    }()
    
    override init() {
        super.init()
        /*
         If the application has already been authorized in a previous run or manually by the user then it can request
         the current set of `SKCloudServiceCapability` and Storefront Identifier.
         */
        if SKCloudServiceController.authorizationStatus() == .authorized {
            requestAppleCloudServiceCapabilities()
            
            /// Retrieve the Music User Token for use in the application if it was stored from a previous run.
            if let token = UserDefaults.standard.string(forKey: MusicService.userTokenUserDefaultsKey) {
                userToken = token
            } else {
                /// The token was not stored previously then request one.
                requestAppleUserToken()
            }
        }
    }
    
    func fetchAppleMusicDeveloperToken() -> String? {
        return "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjJXOVhNOUREWEgifQ.eyJpYXQiOjE1MTkzNTMwMjUsImV4cCI6MTUzNDkwNTAyNSwiaXNzIjoiM1lDOUs0OTUyWSJ9.5ZimoR8HAqGeMbEucflL1_y6VXIGPKjNaf8VTDpfUTnwE7Ds-5dNYen46FwO4fOAYP4XJrbQCTNnPMbXZR3ZAQ"
    }
    
    func requestAppleCloudServiceAuthorization() {
        /*
         An application should only ever call `SKCloudServiceController.requestAuthorization(_:)` when their
         current authorization is `SKCloudServiceAuthorizationStatusNotDetermined`
         */
        guard SKCloudServiceController.authorizationStatus() == .notDetermined else { return }
        
        /*
         `SKCloudServiceController.requestAuthorization(_:)` triggers a prompt for the user asking if they wish to allow the application
         that requested authorization access to the device's cloud services information.  This allows the application to query information
         such as the what capabilities the currently authenticated iTunes Store account has and if the account is eligible for an Apple Music
         Subscription Trial.
         
         This prompt will also include the value provided in the application's Info.plist for the `NSAppleMusicUsageDescription` key.
         This usage description should reflect what the application intends to use this access for.
         */
        
        SKCloudServiceController.requestAuthorization { [weak self] (authorizationStatus) in
            switch authorizationStatus {
            case .authorized:
                self?.requestAppleCloudServiceCapabilities()
                self?.requestAppleUserToken()
            default:
                break
            }
            
            //NotificationCenter.default.post(name: AuthorizationManager.authorizationDidUpdateNotification, object: nil)
        }
    }
    
    func requestAppleCloudServiceCapabilities() {
        cloudServiceController.requestCapabilities(completionHandler: { [weak self] (cloudServiceCapability, error) in
            guard error == nil else {
                fatalError("An error occurred when requesting capabilities: \(error!.localizedDescription)")
            }
            
            self?.cloudServiceCapabilities = cloudServiceCapability
            
            //NotificationCenter.default.post(name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
        })
    }
    
    func requestAppleUserToken() {
        guard let developerToken = fetchAppleMusicDeveloperToken() else {
            return
        }
        
        if SKCloudServiceController.authorizationStatus() == .authorized {
            
            let completionHandler: (String?, Error?) -> Void = { [weak self] (token, error) in
                guard error == nil else {
                    print("An error occurred when requesting user token: \(error!.localizedDescription)")
                    return
                }
                
                guard let token = token else {
                    print("Unexpected value from SKCloudServiceController for user token.")
                    return
                }
                
                self?.userToken = token
                
                /// Store the Music User Token for future use in your application.
                let userDefaults = UserDefaults.standard
                
                userDefaults.set(token, forKey: MusicService.userTokenUserDefaultsKey)
                userDefaults.synchronize()
                
                if self?.cloudServiceStorefrontCountryCode == "" {
                    self?.requestAppleStorefrontCountryCode()
                }
                
                //NotificationCenter.default.post(name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
            }
            
            if #available(iOS 11.0, *) {
                cloudServiceController.requestUserToken(forDeveloperToken: developerToken, completionHandler: completionHandler)
            } else {
                cloudServiceController.requestPersonalizationToken(forClientToken: developerToken, withCompletionHandler: completionHandler)
            }
        }
    }
    
    func requestAppleStorefrontCountryCode() {
        let completionHandler: (String?, Error?) -> Void = { [weak self] (countryCode, error) in
            guard error == nil else {
                print("An error occurred when requesting storefront country code: \(error!.localizedDescription)")
                return
            }
            
            guard let countryCode = countryCode else {
                print("Unexpected value from SKCloudServiceController for storefront country code.")
                return
            }
            
            self?.cloudServiceStorefrontCountryCode = countryCode
            
            //NotificationCenter.default.post(name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
        }
        
        if SKCloudServiceController.authorizationStatus() == .authorized {
            if #available(iOS 11.0, *) {
                /*
                 On iOS 11.0 or later, if the `SKCloudServiceController.authorizationStatus()` is `.authorized` then you can request the storefront
                 country code.
                 */
                cloudServiceController.requestStorefrontCountryCode(completionHandler: completionHandler)
            } else {
                performAppleMusicGetUserStorefront(userToken: userToken, completion: completionHandler)
            }
        } else {
            determineAppleRegionWithDeviceLocale(completion: completionHandler)
        }
    }
    
    func determineAppleRegionWithDeviceLocale(completion: @escaping (String?, Error?) -> Void) {
        /*
         On other versions of iOS or when `SKCloudServiceController.authorizationStatus()` is not `.authorized`, your application should use a
         combination of the device's `Locale.current.regionCode` and the Apple Music API to make an approximation of the storefront to use.
         */
        
        let currentRegionCode = Locale.current.regionCode?.lowercased() ?? "us"
        
        performAppleMusicStorefrontsLookup(regionCode: currentRegionCode, completion: completion)
    }
    
    func performAppleMusicGetUserStorefront(userToken: String, completion: @escaping GetUserStorefrontCompletionHandler) {
        guard let developerToken = fetchAppleMusicDeveloperToken() else {
            fatalError("Developer Token not configured.  See README for more details.")
        }
        
        let urlRequest = createAppleGetUserStorefrontRequest(developerToken: developerToken, userToken: userToken)
        
        let task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                let error = NSError(domain: "AppleMusicManagerErrorDomain", code: -9000, userInfo: [NSUnderlyingErrorKey: error!])
                
                completion(nil, error)
                
                return
            }
            
            do {
                
                let identifier = try self?.processAppleStorefront(from: data!)
                
                completion(identifier, nil)
            } catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func performAppleMusicStorefrontsLookup(regionCode: String, completion: @escaping GetUserStorefrontCompletionHandler) {
        guard let developerToken = fetchAppleMusicDeveloperToken() else {
            fatalError("Developer Token not configured. See README for more details.")
        }
        
        let urlRequest = MusicService.createAppleStorefrontsRequest(regionCode: regionCode, developerToken: developerToken)
        
        let task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                completion(nil, error)
                return
            }
            
            do {
                let identifier = try self?.processAppleStorefront(from: data!)
                completion(identifier, nil)
            } catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func createAppleGetUserStorefrontRequest(developerToken: String, userToken: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = MusicService.appleMusicAPIBaseURLString
        urlComponents.path = userAppleStorefrontPathURLString
        
        // Create and configure the `URLRequest`.
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        
        urlRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue(userToken, forHTTPHeaderField: "Music-User-Token")
        
        return urlRequest
    }
    
    static func createAppleStorefrontsRequest(regionCode: String, developerToken: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = MusicService.appleMusicAPIBaseURLString
        urlComponents.path = "/v1/storefronts/\(regionCode)"
        
        // Create and configure the `URLRequest`.
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        
        urlRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    func processAppleStorefront(from json: Data) throws -> String {
        guard let jsonDictionary = try JSONSerialization.jsonObject(with: json, options: []) as? [String: Any],
            let data = jsonDictionary["data"] as? [[String: Any]] else {
                throw SerializationError.missing("data")
        }
        
        guard let identifier = data.first?["id"] as? String else {
            throw SerializationError.missing("id")
        }
        
        return identifier
    }
    
    func requestAppleMediaLibraryAuthorization() {
        /*
         An application should only ever call `MPMediaLibrary.requestAuthorization(_:)` when their
         current authorization is `MPMediaLibraryAuthorizationStatusNotDetermined`
         */
        guard MPMediaLibrary.authorizationStatus() == .notDetermined else { return }
        
        /*
         `MPMediaLibrary.requestAuthorization(_:)` triggers a prompt for the user asking if they wish to allow the application
         that requested authorization access to the device's media library.
         
         This prompt will also include the value provided in the application's Info.plist for the `NSAppleMusicUsageDescription` key.
         This usage description should reflect what the application intends to use this access for.
         */
        
        MPMediaLibrary.requestAuthorization { (_) in
            //NotificationCenter.default.post(name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
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
        
        guard let developerToken = fetchAppleMusicDeveloperToken() else {
            fatalError("Developer Token not configured. See README for more details.")
        }
        
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
        
        guard let developerToken = fetchAppleMusicDeveloperToken() else {
            fatalError("Developer Token not configured. See README for more details.")
        }
        
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
   

}

