//
//  DataService.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/3/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class DataService {
    /** The `DataService` singleton. */
    static let instance = DataService()

    // Firebase Database references.
    private var _REF_USERS = Database.database().reference().child("Users")
    private var _REF_USERS_LIKES = Database.database().reference().child("UsersLikes")
    private var _REF_USERS_FRIENDS = Database.database().reference().child("UsersFriends")
    private var _REF_USERS_PENDING_FRIENDS = Database.database().reference().child("UsersPendingFriends")
    private var _REF_USERS_SPOTIFY_PLAYLISTS = Database.database().reference().child("UsersSpotifyPlaylists")

    // Firebase Storage references.
    private var _REF_PROFILE_PICS = Storage.storage().reference().child("profile-pics")
    
    var REF_PROFILE_PICS: StorageReference {
        return _REF_PROFILE_PICS
    }

    /**
     * Updates a user's entry in the Firebase database, creating one if absent.
     *
     * - parameter uid: The user's unique ID.
     * - parameter userData: A dictionary of user data.
     */
    func createOrUpdateUser(uid: String, userData: [String:Any]) {
        _REF_USERS.child(uid).updateChildValues(userData)
    }
    
    /**
     * Retrieves a user entry matching the given user ID.
     *
     * - parameter uid: The (unique) user ID.
     * - parameter handler: The handler that will be invoked upon a successful `User` retrieval.
     */
    func getUser(uid: String,  handler: @escaping (_ user: User) -> ()) {
        _REF_USERS.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userDict = snapshot.value as? [String:Any] else {
                print("Failed retrieving a user.")
                return
            }
            
            handler(User(userDict: userDict, userID: snapshot.key))
            return
        }) { (error) in
            print("Failure retrieving a user: \(error.localizedDescription)")
            return
        }
    }
    
    /**
     * Retrieves a user's profile picture.
     *
     * - parameter user: The user whose photo is to be retrieved.
     * - parameter handler: The handler that will be invoked upon a successful `UIImage` retrieval.
     */
    func getProfilePicture(user: User, handler: @escaping (_ image: UIImage) -> ()) {
        guard let url = URL(string: user.profilePictureURL) else {
            return
        }
        
        let session = URLSession(configuration: .default)
        let getImageFromUrl = session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print("Error downloading image: \(String(describing: error))")
            } else {
                guard let _ = response as? HTTPURLResponse else {
                    print("No response from server.")
                    return
                }
                
                if let imageData = data {
                    guard let image = UIImage(data: imageData) else {
                        return
                    }
                    
                    handler(image)
                    return
                } else {
                    print("The image file is corrupted.")
                }
            }
        }
        
        getImageFromUrl.resume()
    }
    
    /**
     * Deletes a user from the database.
     *
     * - parameter uid: The (unique) user ID.
     */
    func deleteUser(uid: String) {
        print("Deleting user with UID: \(uid)")
        _REF_USERS.child(uid).removeValue()
    }
    
    /**
     * Returns an array of `User` objects whose names contain `nameSubstring`. The users are
     * supplied to the callback handler.
     *
     * - parameter nameSubstring: A substring of a user's name to match.
     * - parameter handler: The callback handler that will be invoked with the matching users.
     */
    func findUsersByName(nameSubstring: String, handler: @escaping (_ matchingUsers: [User]) -> ()) {
        _REF_USERS.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var matchingUsers = [User]()
            if let userEntries = snapshot.value as? Dictionary<String, AnyObject> {
                for (uid, userDictionary) in userEntries {
                    matchingUsers.append(User(userDict: userDictionary as! [String : Any], userID: uid))
                }
                handler(matchingUsers)
            }
        })
    }
    
    /**
     * Adds a friend request entry for the user specified by their ID from the currently
     * authenticated user.
     *
     * - parameter friendUid: The user ID of the friend the current user requested to add.
     */
    func requestFriend(friendUid: String) {
        if let currentUid = Auth.auth().currentUser?.uid {
            if currentUid == "" || friendUid == "" {
                return
            } else if friendUid == currentUid {
                print("Attempting to friend request oneself.")
                return
            }
            _REF_USERS_PENDING_FRIENDS.child(currentUid).observeSingleEvent(of: .value, with: { (snapshot) in
                var pendingUids = [String]()
                if snapshot.exists() {
                    if let friendUids = snapshot.value as? [String] {
                        pendingUids += friendUids
                    }
                }
                pendingUids.append(friendUid)
                self._REF_USERS_PENDING_FRIENDS.child(currentUid).setValue(pendingUids)
            })
        }
    }
    
    /**
     * Returns an array of `User` objects corresponding to users that have requested to be
     * friends with the current user. The users are supplied to the callback handler.
     *
     * - parameter handler: The callback handler that will be invoked with the incoming friends.
     */
    func getIncomingFriendRequests(handler: @escaping (_ incomingFriends: [User]) -> ()) {
        if let currentUid = Auth.auth().currentUser?.uid {
            if currentUid == "" {
                return
            }
            _REF_USERS_PENDING_FRIENDS.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
                if let requestEntries = snapshot.value as? Dictionary<String, AnyObject> {
                    for (uid, friendUids) in requestEntries {
                        if let friendUidsArray = friendUids as? [String] {
                            var incomingFriends = [User]()
                            for friendUid in friendUidsArray {
                                if currentUid == friendUid {
                                    self.getUser(uid: uid, handler: { (user) in
                                        incomingFriends.append(user)
                                        handler(incomingFriends)
                                    })
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    /**
     * Returns an array of `User` objects corresponding to users that the current user has
     * requested to be friends with. The users are supplied to the callback handler.
     *
     * - parameter handler: The callback handler that will be invoked with the outgoing friends.
     */
    func getOutgoingFriendRequests(handler: @escaping (_ outgoingFriends: [User]) -> ()) {
        if let currentUid = Auth.auth().currentUser?.uid {
            if currentUid == "" {
                return
            }
            _REF_USERS_PENDING_FRIENDS.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
                if let requestEntries = snapshot.value as? Dictionary<String, AnyObject> {
                    if let friendUids = requestEntries[currentUid] as? [String] {
                        var outgoingFriends = [User]()
                        for friendUid in friendUids {
                            self.getUser(uid: friendUid, handler: { (user) in
                                outgoingFriends.append(user)
                                handler(outgoingFriends)
                            })
                        }
                    }
                }
            })
        }
    }
    
    /**
     * Returns an array of `User` objects that the current user is friends with. The users are
     * supplied to the callback handler.
     *
     * - parameter handler: The callback handler that will be invoked with the user's friends.
     */
    func getFriends(handler: @escaping (_ friends: [User]) -> ()) {
        if let currentUid = Auth.auth().currentUser?.uid {
            if currentUid == "" {
                return
            }
            _REF_USERS_FRIENDS.child(currentUid).observeSingleEvent(of: .value, with: { (snapshot) in
                if let friendUids = snapshot.value as? [String] {
                    var friends = [User]()
                    for friendUid in friendUids {
                        self.getUser(uid: friendUid, handler: { (user) in
                            friends.append(user)
                            handler(friends)
                        })
                    }
                }
            })
        }
    }
    
    /**
     * Responds to a friend request from the user with the ID `requesterUid`. If the `accept`
     * argument is `true`, then the requester is added to the current user's friends list. In
     * both cases, the pending friend request is removed as a result of this call.
     *
     * - parameter requesterUid: The user ID of the person that requested to be friends.
     * - parameter accept: If the friend request was accepted.
     */
    func respondFriendRequest(requesterUid: String, accept: Bool) {
        if let currentUid = Auth.auth().currentUser?.uid {
            if currentUid == "" {
                return
            }
            _REF_USERS_PENDING_FRIENDS.child(requesterUid).observeSingleEvent(of: .value, with: { (snapshot) in
                if let pendingUids = snapshot.value as? [String] {
                    if let currentUserIndex = pendingUids.index(of: currentUid) {
                        var removedUids = [String]()
                        removedUids += pendingUids
                        removedUids.remove(at: currentUserIndex)
                        self._REF_USERS_PENDING_FRIENDS.child(requesterUid).setValue(removedUids)
                    }
                }
            })
            if accept {
                _REF_USERS_FRIENDS.child(currentUid).observeSingleEvent(of: .value, with: { (snapshot) in
                    var appendedUids = [String]()
                    if snapshot.exists() {
                        if let friendUids = snapshot.value as? [String] {
                            appendedUids += friendUids
                        }
                    }
                    appendedUids.append(requesterUid)
                    self._REF_USERS_FRIENDS.child(currentUid).setValue(appendedUids)
                })
            }
        }
    }

    func setUserSpotifyPlaylist(uid: String, uri: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        _REF_USERS_SPOTIFY_PLAYLISTS.child(uid).child("uri").setValue(uri) { (error, ref) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    func getUserSpotifyPlaylist(uid: String, success: @escaping (String) -> (), failure: @escaping (Error)->()) {
        _REF_USERS_SPOTIFY_PLAYLISTS.child(uid).child("uri").observe(.value) { (snapshot) in
            let uri = snapshot.value as! String
            success(uri)
        }
    }
    
    func likeSongs(appleMusicSongs: Set<String>, spotifySongs: Set<String>, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        let currUserAppleMusicLikesRef = currUserLikesRef.child("AppleMusic")
        let currUserSpotifyLikesRef = currUserLikesRef.child("Spotify")
        
        let songGroup = DispatchGroup()
        
        for song in appleMusicSongs {
            songGroup.enter()
            currUserAppleMusicLikesRef.child(song).setValue(true) { (error, reference) in
                if let error = error {
                    failure(error)
                } else {
                    songGroup.leave()
                }
            }
        }
        
        for song in spotifySongs {
            songGroup.enter()
            currUserSpotifyLikesRef.child(song).setValue(true) { (error, reference) in
                if let error = error {
                    failure(error)
                } else {
                    songGroup.leave()
                }
            }
        }
        
        songGroup.notify(queue: DispatchQueue .global()) {
            MusicService.sharedInstance.addToSpotifyPlaylist(songs: spotifySongs, success: {
                success()
            }, failure: { (error) in
                failure(error)
            })
        }
    }
    
    func getLikedSongs(sucesss: @escaping ([(String, Song.SongType)]) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        
        currUserLikesRef.observe(.value) { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }
            
            var result = [(String, Song.SongType)]()
            if let appleMusicList = data["AppleMusic"] as? [String: Bool] {
                for (key, _) in appleMusicList {
                    result.append((key, Song.SongType.AppleMusic))
                }
            }
            
            if let spotifyMusicList = data["Spotify"] as? [String: Bool] {
                for (key, _) in spotifyMusicList {
                    result.append((key, Song.SongType.Spotify))
                }
            }
            
            sucesss(result)
        }
    }

    func getLikedSpotifySongs(sucesss: @escaping ([String]) -> ()) {
        let currUserSpotfyLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid).child("Spotify")
        
        currUserSpotfyLikesRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }
            
            var result: [String] = []
            
            for (key, _) in data {
                result.append(key)
            }
            
            sucesss(result)
        }
    }
    
    func likeMovies(movies: Set<Int>, success: @escaping () -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        let currentUserMovieLikesRef = currUserLikesRef.child("Movies")

        for movie in movies {
            currentUserMovieLikesRef.child("\(movie)").setValue(true)
        }

        success()
    }

    func getLikedMovies(sucesss: @escaping ([(String)]) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        currUserLikesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }

            var result = [(String)]()

            if let movies = data["Movies"] as? [String: Bool] {
                for (key, _) in movies {
                    result.append((key))
                }
            }

            sucesss(result)
        })
    }

    func likeShows(shows: Set<Int>, success: @escaping () -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        let currentUserShowLikes = currUserLikesRef.child("Shows")

        for show in shows {
            currentUserShowLikes.child("\(show)").setValue(true)
        }

        success()
    }

    func getLikedShows(sucesss: @escaping ([(String)]) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        currUserLikesRef.observe(.value) { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }

            var result = [(String)]()

            if let shows = data["Shows"] as? [String: Bool] {
                for (key, _) in shows {
                    result.append((key))
                }
            }

            sucesss(result)
        }
    }
}
