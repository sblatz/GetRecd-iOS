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
        print(attributes["artwork"])
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
        
//        guard let previews = attributes["previews"] as? [[String: Any]] else {
//            throw SerializationError.missing("previews")
//        }
        
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
        
        //let preview = previews[0]
        //self.preview = preview["url"] as! String
    }
    
    init(spotifyData: SPTPartialTrack) throws {
        
        
        guard let artists = spotifyData.artists as? [SPTPartialArtist] else {
            throw SerializationError.missing("artists")
        }
        
        guard let artist = artists[0] as? SPTPartialArtist else {
            throw SerializationError.missing("artist")
        }
        
        guard let album = spotifyData.album as? SPTPartialAlbum else {
            throw SerializationError.missing("album")
        }
        
        guard let images = album.covers as? [SPTImage] else {
            throw SerializationError.missing("images")
        }
        
        guard let image = images[0] as? SPTImage else {
            throw SerializationError.missing("image")
        }
    
        
//        guard let genres = attributes["genreNames"] as? [String] else {
//            throw SerializationError.missing("genres")
//        }
        
        self.id = spotifyData.identifier
        self.name = spotifyData.name
        self.type = .Spotify
        self.id = spotifyData.identifier
        self.name = spotifyData.name
        //self.genres = genres
        self.artist = artist.name
        
        self.artwork = image.imageURL.absoluteString
    }
}


