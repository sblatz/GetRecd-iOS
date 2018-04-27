//
//  DataService.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/3/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class DataService {
    /** The `DataService` singleton. */
    static let sharedInstance = DataService()

    // Firebase Database references.
    private var db = Firestore.firestore()
    private var userCollection = Firestore.firestore().collection("Users")
    private var userSpotifyLikesCollection = Firestore.firestore().collection("UsersSpotifyLikes")
    private var userAppleMusicLikesCollection = Firestore.firestore().collection("UsersAppleMusicLikes")
    private var userMovieLikesCollection = Firestore.firestore().collection("UsersMovieLikes")
    private var userShowLikesCollection = Firestore.firestore().collection("UsersShowLikes")
    private var userFriendsCollection = Firestore.firestore().collection("UsersFriends")
    private var pendingFriendsCollection = Firestore.firestore().collection("UsersPendingFriends")
    private var spotifyPlaylistsCollection = Firestore.firestore().collection("UsersSpotifyPlaylists")
    private var profilePictureRef = Storage.storage().reference().child("UserPictures")
    private var notificationCollection = Firestore.firestore().collection("Notifications")

    enum ContentType {
        case AppleSong, SpotifySong, Movie, Show
    }
    
    /**
     * Updates a user's entry in the Firebase database, creating one if absent.
     *
     * - parameter uid: The user's unique ID.
     * - parameter userData: A dictionary of user data.
     */
    func createUser(uid: String, userData: [String: Any], success: @escaping (User) -> (), failure: @escaping (Error) -> ()) {
        userCollection.document(uid).setData(userData) { (error) in
            if let error = error {
                failure(error)
            } else {
                success(User(userDict: userData))
            }
        }
    }
    
    func updateUser(uid: String, userData: [String: Any], success: @escaping (User) -> (), failure: @escaping (Error) -> ()) {
        userCollection.document(uid).updateData(userData) { (error) in
            if let error = error {
                failure(error)
            } else {
                success(User(userDict: userData))
            }
        }
    }
    /**
     * Retrieves a user entry matching the given user ID.
     *
     * - parameter uid: The (unique) user ID.
     * - parameter handler: The handler that will be invoked upon a successful `User` retrieval.
     */
    func getUser(uid: String, success: @escaping (User) -> (), failure: @escaping (Error) -> ()) {
        userCollection.document(uid).getDocument { (document, error) in
            if let error = error {
                failure(error)
            } else if let userDoc = document {
                // TODO Check to make sure userinfo exists
                if let userInfo = userDoc.data() {
                    
                    success(User(userDict: userInfo))
                }
            }
        }
    }
    
    // Get user's profile photos
    func setProfilePicture(uid: String, image: UIImage, success: @escaping (String) -> (), failure: @escaping (Error) -> ()) {
        let imageData = UIImageJPEGRepresentation(image, 0.2)!
        profilePictureRef.child(uid).putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                failure(error)
            } else if let metadata = metadata {
                success(metadata.downloadURL()!.absoluteString)
            }
        }
    }
    
    /**
     * Retrieves a user's profile picture.
     *
     * - parameter user: The user whose photo is to be retrieved.
     * - parameter handler: The handler that will be invoked upon a successful `UIImage` retrieval.
     */
    func getProfilePicture(uid: String, success: @escaping (Bool, UIImage?) -> (), failure: @escaping (Error) -> ()) {
        profilePictureRef.child(uid).downloadURL { (url, error) in
            if let error = error {
                failure(error)
            } else if let imageUrl = url {
                let session = URLSession(configuration: .default)
                let getImageFromUrl = session.dataTask(with: imageUrl) { (data, response, error) in
                    if let error = error {
                        failure(error)
                    } else if let imageData = data {
                        guard let image = UIImage(data: imageData) else {
                            // TODO: Send back error if data is not picture
                            return
                        }
                        
                        success(true, image)
                    } else {
                        // TODO: Send back error if no picture
                    }
                }
                
                getImageFromUrl.resume()
            }
        }
        
    }
    
    /**
     * Deletes a user from the database.
     *
     * - parameter uid: The (unique) user ID.
     */
    func deleteUser(uid: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        if Auth.auth().currentUser == nil {
            // TODO: Send back error that no user is logged in
            return
        }
        
        userCollection.document(uid).delete { (error) in
            if let error = error {
                failure(error)
            } else {
                Auth.auth().currentUser?.delete(completion: { (error) in
                    if let error = error {
                        failure(error)
                    } else {
                        success()
                    }
                })
            }
        }
    }
    
    // Return users with names starting with name not including self
    func searchForUsers(uid: String, name: String, success: @escaping ([String]) -> (), failure: @escaping (Error) -> ()) {
        userFriendsCollection.document(uid).getDocument { (documentSnapshot, error) in
            if let error = error {
                failure(error)
            } else  {
                let userFriends = documentSnapshot?.data() ?? [String: Any]()
                
                self.userCollection.whereField("name", isGreaterThanOrEqualTo: name).getDocuments { (documentSnapshot, error) in
                    if let error = error {
                        failure(error)
                    } else if let documentSnapshot = documentSnapshot {
                        var users = [String]()
                        let userDocs = documentSnapshot.documents
                        for userDoc in userDocs {
                            let newUser = User(userDict: userDoc.data())
                            if newUser.userID != uid && userFriends[newUser.userID] == nil{
                                users.append(newUser.userID)
                            }
                        }
                        
                        success(users)
                    } else {
                        success([])
                    }
                }
            }
        }
    }

    // Used to set the privacy settings of a user's music, tv shows, or movies
    func setPrivacyFor(category: String, privacy: Bool, uid: String, completion: @escaping () -> ()) {
        userCollection.document(uid).getDocument { (snap, error) in
            if error == nil {
                var data = (snap?.data())!
                data["private\(category)"] = "\(privacy)"
                self.userCollection.document(uid).setData(data)
            }
        }
    }
    /**
     
     * Returns an array of all `User` objects. The users are
     * supplied to the callback handler.
     *
     *
     * - parameter handler: The callback handler that will be invoked with all the user IDs.
     */
    func getAllUsers(success: @escaping ([User]) -> (), failure: @escaping (Error) -> ()) {
        userCollection.getDocuments(completion: { (documentSnapshot, error) in
            if let error = error {
                failure(error)
            } else if let documentSnapshot = documentSnapshot {
                var users = [User]()
                let userDocs = documentSnapshot.documents
                for userDoc in userDocs {
                    users.append(User(userDict: userDoc.data()))
                }
                
                success(users)
            } else {
                success([])
            }
        })
    }
    
    /**
     * Adds a friend request entry for the user specified by their ID from the currently
     * authenticated user.
     *
     * - parameter friendUid: The user ID of the friend the current user requested to add.
     */
    func requestFriend(uid: String, friendUid: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let pendingFriendDoc = pendingFriendsCollection.document(friendUid)
        let notificationDoc = notificationCollection.document()
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.setData([uid: true], forDocument: pendingFriendDoc)
            transaction.setData(["uid": friendUid, "type": "friendRequest", "message": "You received a new friend request!"], forDocument: notificationDoc)

            return nil
        }) { (object, error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
//        pendingFriendsCollection.document(friendUid).setData([uid: true]) { (error) in
//            if let error = error {
//                failure(error)
//            } else {
//                success()
//            }
//        }
    }
    
    /**
     * Returns an array of `User` objects corresponding to users that have requested to be
     * friends with the current user. The users are supplied to the callback handler.
     *
     * - parameter handler: The callback handler that will be invoked with the incoming friend IDs.
     */
    func getIncomingFriendRequests(uid: String, success: @escaping ([String]) -> (), failure: @escaping (Error) -> ()) {
        pendingFriendsCollection.document(uid).getDocument  { (documentSnapshot, error) in
            if let error = error {
                failure(error)
            } else {
                var friendRequestIds = [String]()
                let friendRequests = documentSnapshot?.data() ?? [String: Any]()
                for (uid, _) in friendRequests {
                    friendRequestIds.append(uid)
                }
                
                success(friendRequestIds)
            }
        }
    }
    
    /**
     * Returns an array of `User` objects corresponding to users that the current user has
     * requested to be friends with. The users are supplied to the callback handler.
     *
     * - parameter handler: The callback handler that will be invoked with the outgoing friend IDs.
     */
//    func getOutgoingFriendRequests(handler: @escaping (_ outgoingFriends: [String]) -> ()) {
//        if let currentUid = Auth.auth().currentUser?.uid {
//            if currentUid == "" {
//                return
//            }
//            _REF_USERS_PENDING_FRIENDS.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
//                if let requestEntries = snapshot.value as? Dictionary<String, AnyObject> {
//                    if let friendUids = requestEntries[currentUid] as? [String] {
//                        handler(friendUids)
//                    }
//                }
//            })
//        }
//    }
    
    /**
     * Returns an array of `User` objects that the current user is friends with. The users are
     * supplied to the callback handler.
     *
     * - parameter handler: The callback handler that will be invoked with the user's friends.
     */
    func getFriends(uid: String, success: @escaping ([String]) -> (), failure: @escaping (Error) -> ()) {
        userFriendsCollection.document(uid).getDocument { (documentSnapshot, error) in
            if let error = error {
                failure(error)
            } else  {
                var friends = [String]()
                let friendList = documentSnapshot?.data() ?? [String: Any]()
                for (uid, _) in friendList {
                    friends.append(uid)
                }
                
                success(friends)
            }
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
    func respondFriendRequest(uid: String, friendUid: String, accept: Bool, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let userFriendsDoc = userFriendsCollection.document(uid)
        let friendFriendDoc = userFriendsCollection.document(friendUid)
        let userPendingFriendsDoc = pendingFriendsCollection.document(uid)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            var userPendingFriendsSnapshot: DocumentSnapshot
            do {
                userPendingFriendsSnapshot = try transaction.getDocument(userPendingFriendsDoc)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            if accept {
                transaction.setData([friendUid: true], forDocument: userFriendsDoc)
                transaction.setData([uid: true], forDocument: friendFriendDoc)
            }
            var pendingFriends = userPendingFriendsSnapshot.data() ?? [String: Any]()
            pendingFriends[friendUid] = nil
            
            transaction.setData(pendingFriends, forDocument: userPendingFriendsDoc)
            
            return nil
        }) { (object, error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }

    func setUserSpotifyPlaylist(uid: String, uri: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        spotifyPlaylistsCollection.document(uid).setData(["uri": uri]) { (error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    func getUserSpotifyPlaylist(uid: String, success: @escaping (String) -> (), failure: @escaping (Error)->()) {
        spotifyPlaylistsCollection.document(uid).getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
            } else {
                let uri = snapshot!.data()!["uri"] as! String
                success(uri)
            }
        }
    }
    
    private func getDocumentForContentType(uid: String, contentType: ContentType) -> DocumentReference {
        var contentCollection: CollectionReference
        switch contentType {
        case .AppleSong:
            contentCollection = userAppleMusicLikesCollection
        case .SpotifySong:
            contentCollection = userSpotifyLikesCollection
        case .Movie:
            contentCollection = userMovieLikesCollection
        case .Show:
            contentCollection = userShowLikesCollection
        }
        return contentCollection.document(uid)
    }
    
    func rateContent(uid: String,
                     contentType: ContentType,
                     contentId: String,
                     rating: Int,
                     success: @escaping () -> (),
                     failure: @escaping (Error) -> ()) {
        let contentDocument = getDocumentForContentType(uid: uid, contentType: contentType)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.updateData([contentId: rating], forDocument: contentDocument)
            return nil
        }) { (object, error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    func getRating(uid: String,
                   contentType: ContentType,
                   contentId: String,
                   success: @escaping (Int) -> (),
                   failure: @escaping (Error) -> ()) {
        let contentDocument = getDocumentForContentType(uid: uid, contentType: contentType)
        contentDocument.getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
                return
            }
            let ratingData = snapshot?.data() ?? [String: Any]()
            if let rating = ratingData[contentId] as? Int {
                success(rating)
            }
        }
    }
    
    func getContentWithRating(uid: String,
                              contentType: ContentType,
                              minimumRating: Int,
                              success: @escaping ([String]) -> (),
                              failure: @escaping (Error) -> ()) {
        let contentDocument = getDocumentForContentType(uid: uid, contentType: contentType)
        contentDocument.getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
                return
            }
            let ratingData = snapshot?.data() ?? [String: Any]()
            var filtered = [String]()
            for (id, rating) in ratingData {
                if let ratingNumber = rating as? Int {
                    if ratingNumber >= minimumRating {
                        filtered.append(id)
                    }
                }
            }
            success(filtered)
        }
    }
    
    func likeSongs(uid: String, appleMusicSongs: Set<String>, spotifySongs: Set<String>, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let userSpotifyLikes = userSpotifyLikesCollection.document(uid)
        let userAppleMusicLikes = userAppleMusicLikesCollection.document(uid)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            var userSpotifyLikesSnapshot: DocumentSnapshot?
            var userAppleMusicLikesSnapshot: DocumentSnapshot?
            
            do {
                if spotifySongs.count > 0 {
                    userSpotifyLikesSnapshot = try transaction.getDocument(userSpotifyLikes)
                }
                
                if appleMusicSongs.count > 0 {
                    userAppleMusicLikesSnapshot = try transaction.getDocument(userAppleMusicLikes)
                }
            } catch let fetchError as NSError {
                var userSLikes = [String: Int]()
                var userAPLikes = [String: Int]()
                for song in spotifySongs {
                    userSLikes[song] = 0
                }
                
                transaction.setData(userSLikes, forDocument: userSpotifyLikes)
                
                for song in appleMusicSongs {
                    userAPLikes[song] = 0
                }
                
                transaction.setData(userAPLikes, forDocument: userAppleMusicLikes)
                return nil
            }
            
            if var userLikes = userSpotifyLikesSnapshot?.data() {
                for song in spotifySongs {
                    userLikes[song] = 0
                }
                
                transaction.setData(userLikes, forDocument: userSpotifyLikes)
            }
            
            if var userLikes = userAppleMusicLikesSnapshot?.data() {
                for song in appleMusicSongs {
                    userLikes[song] = 0
                }
                
                transaction.setData(userLikes, forDocument: userAppleMusicLikes)
            }
            
            return nil
        }) { (object, error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
        
    }
    
    func getLikedSongs(uid: String, sucesss: @escaping ([(String, Song.SongType)]) -> (), failure: @escaping (Error) -> ()) {
        let userSpotifyLikes = userSpotifyLikesCollection.document(uid)
        let userAppleMusicLikes = userAppleMusicLikesCollection.document(uid)
        
        let likeGroup = DispatchGroup()
        
        likeGroup.enter()
        var result = [(String, Song.SongType)]()
        userAppleMusicLikes.getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
            } else {
                let appleMusicLikes = snapshot?.data() ?? [String: Any]()
                
                for (key, _) in appleMusicLikes {
                    result.append((key, Song.SongType.AppleMusic))
                }
                likeGroup.leave()
            }
        }
        
        
        likeGroup.enter()
        userSpotifyLikes.getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
            } else {
                let spotifyLikes = snapshot?.data() ?? [String: Any]()
                
                for (key, _) in spotifyLikes {
                    result.append((key, Song.SongType.Spotify))
                }
                likeGroup.leave()
            }
        }
        
        likeGroup.notify(queue: .global()) {
            sucesss(result)
        }
    }

    func getLikedSpotifySongs(uid: String, sucesss: @escaping ([String]) -> (), failure: @escaping (Error) -> ()) {
        let userSpotifyLikes = userSpotifyLikesCollection.document(uid)
        
        userSpotifyLikes.getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
            } else {
                let spotifyLikes = snapshot?.data() ?? [String: Any]()
                
                var result: [String] = []
                
                for (key, _) in spotifyLikes {
                    result.append(key)
                }
                
                sucesss(result)
            }
        }
    }
    
    func likeMovies(uid: String, movies: Set<Int>, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let userMovieLikes = userMovieLikesCollection.document(uid)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            var userMovieLikesSnapshot: DocumentSnapshot?
            
            do {
                userMovieLikesSnapshot = try transaction.getDocument(userMovieLikes)
            } catch let fetchError as NSError {
                var userLikes = [String: Int]()
                
                for movie in movies {
                    userLikes["\(movie)"] = 0
                }
                
                transaction.setData(userLikes, forDocument: userMovieLikes)
            
                return nil
            }
            
            var movieLikes = userMovieLikesSnapshot?.data() ?? [String: Any]()
            for movie in movies {
                movieLikes["\(movie)"] = 0
            }
            
            transaction.setData(movieLikes, forDocument: userMovieLikes)
            
            return nil
        }) { (object, error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    func getLikedMovies(uid: String, sucesss: @escaping ([(String)]) -> (), failure: @escaping (Error) -> ()) {
        let userMovieLikes = userMovieLikesCollection.document(uid)
        
        userMovieLikes.getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
            } else {
                let movieLikes = snapshot?.data() ?? [String: Any]()
                
                var result: [String] = []
                
                for (key, _) in movieLikes {
                    result.append(key)
                }
                
                sucesss(result)
            }
        }
    }

    func likeShows(uid: String, shows: Set<Int>, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let userShowLikes = userShowLikesCollection.document(uid)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            var userShowLikesSnapshot: DocumentSnapshot?
            
            do {
                userShowLikesSnapshot = try transaction.getDocument(userShowLikes)
            } catch let fetchError as NSError {
                var userLikes = [String: Int]()
                
                for show in shows {
                    userLikes["\(show)"] = 0
                }
                
                transaction.setData(userLikes, forDocument: userShowLikes)
                
                return nil
            }
            
            var showLikes = userShowLikesSnapshot?.data() ?? [String: Any]()
            for show in shows {
                showLikes["\(show)"] = 0
            }
            
            transaction.setData(showLikes, forDocument: userShowLikes)
            
            return nil
        }) { (object, error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }

    func getLikedShows(uid: String, sucesss: @escaping ([(String)]) -> (), failure: @escaping (Error) -> ()) {
        let userShowLikes = userShowLikesCollection.document(uid)
        
        userShowLikes.getDocument { (snapshot, error) in
            if let error = error {
                failure(error)
            } else {
                let showLikes = snapshot?.data() ?? [String: Any]()
                
                var result: [String] = []
                
                for (key, _) in showLikes {
                    result.append(key)
                }
                
                sucesss(result)
            }
        }
    }
    
    func setNotificationToken(uid: String, token: String, success: @escaping () ->(), failure: @escaping (Error) -> ()) {
        let userDoc = userCollection.document(uid)
        userDoc.updateData(["token": token], completion: { (error) in
            if let error = error {
                failure(error)
            }
            success()
        })
    }
}
