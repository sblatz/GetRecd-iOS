//
//  Song.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class Song: NSObject {
    enum SongType {
        case AppleMusic
        case Spotify
    }
    private(set) var id: String!
    private(set) var type: SongType!
    private(set) var name: String!
    private(set) var artist: String!
    private(set) var artwork: String!
    private(set) var preview: String?
    //private(set) var genres: [String]!
    
    init(appleMusicData: [String: Any]) throws {
        guard let id = appleMusicData["id"] as? String else {
            throw SerializationError.missing("id")
        }
        
        guard let attributes = appleMusicData["attributes"] as? [String: Any] else {
            throw SerializationError.missing("attributes")
        }
        
        guard let name = attributes["name"] as? String else {
            throw SerializationError.missing("name")
        }
        
        let artist = attributes["artistName"] as? String ?? " "
        
        guard let artworkData = attributes["artwork"] as? [String: Any] else {
            throw SerializationError.missing("artwork")
        }
        
        guard let height = artworkData["height"] as? Int else {
            throw SerializationError.missing("height")
        }
        
        guard let width = artworkData["width"] as? Int else {
            throw SerializationError.missing("width")
        }
        
        guard let urlTemplateString = artworkData["url"] as? String else {
            throw SerializationError.missing("url")
        }
        
//        guard let genres = attributes["genreNames"] as? [String] else {
//            throw SerializationError.missing("genres")
//        }
        
        guard let previews = attributes["previews"] as? [[String: Any]] else {
            throw SerializationError.missing("previews")
        }
        
        self.type = .AppleMusic
        self.id = id
        self.name = name
        //self.genres = genres
        self.artist = artist
        
        self.artwork = urlTemplateString.replacingOccurrences(of: "{w}", with: "\(width)")
        
        // 2) Replace the "{h}" placeholder with the desired height as an integer value.
        self.artwork = self.artwork.replacingOccurrences(of: "{h}", with: "\(height)")
        
        // 3) Replace the "{f}" placeholder with the desired image format.
        self.artwork = self.artwork.replacingOccurrences(of: "{f}", with: "png")
        
        let preview = previews[0]
        self.preview = preview["url"] as! String
    }
    
    init(spotifyData: [String: Any]) throws {
        guard let id = spotifyData["id"] as? String else {
            throw SerializationError.missing("id")
        }
        
        guard let name = spotifyData["name"] as? String else {
            throw SerializationError.missing("name")
        }
        
        guard let artists = spotifyData["artists"] as? [[String: Any]] else {
            throw SerializationError.missing("name")
        }
        
        guard let artist = artists[0] as? [String: Any] else {
            throw SerializationError.missing("artist")
        }
        
        guard let album = spotifyData["album"] as? [String: Any] else {
            throw SerializationError.missing("album")
        }
        
        guard let images = album["images"] as? [[String: Any]] else {
            throw SerializationError.missing("images")
        }
        
        guard let image = images[0] as? [String: Any] else {
            throw SerializationError.missing("image")
        }
        
        guard let width = image["width"] as? Int else {
            throw SerializationError.missing("width")
        }
        
        guard let height = image["height"] as? Int else {
            throw SerializationError.missing("height")
        }
        
        
        guard let artworkUrl = image["url"] as? String else {
            throw SerializationError.missing("url")
        }
        
//        guard let genres = attributes["genreNames"] as? [String] else {
//            throw SerializationError.missing("genres")
//        }
        
        self.type = .Spotify
        self.id = id
        self.name = name
        //self.genres = genres
        self.artist = artist["name"] as! String
        
        self.artwork = artworkUrl
    }
}


