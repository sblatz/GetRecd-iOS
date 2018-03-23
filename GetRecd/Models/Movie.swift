//
//  Movie.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/22/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation

class Movie: NSObject {

    private(set) var id: Int!
    private(set) var name: String!
    private(set) var overview: String!
    private(set) var releaseDate: String!
    private(set) var posterPath: String!

    init(movieDict: [String:Any]) throws {

        guard let id = movieDict["id"] as? Int else {
            throw SerializationError.missing("id")
        }

        guard let name = movieDict["name"] as? String else {
            throw SerializationError.missing("name")
        }

        guard let overview = movieDict["overview"] as? String else {
            throw SerializationError.missing("overview")
        }

        guard let releaseDate = movieDict["releaseDate"] as? String else {
            throw SerializationError.missing("releaseDate")
        }

        guard let posterPath = movieDict["posterPath"] as? String else {
            throw SerializationError.missing("posterPath")
        }

        self.id = id
        self.name = name
        self.overview = overview
        self.releaseDate = releaseDate
        self.posterPath = posterPath
    }
}
