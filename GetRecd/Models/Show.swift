//
//  Show.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation

class Show: NSObject {

    private(set) var id: Int!
    private(set) var name: String!
    private(set) var overview: String!
    private(set) var releaseDate: String!
    private(set) var posterPath: String!

    init(showDict: [String:Any]) throws {

        guard let id = showDict["id"] as? Int else {
            throw SerializationError.missing("id")
        }

        guard let name = showDict["name"] as? String else {
            throw SerializationError.missing("name")
        }

        guard let overview = showDict["overview"] as? String else {
            throw SerializationError.missing("overview")
        }

        guard let releaseDate = showDict["releaseDate"] as? String else {
            throw SerializationError.missing("releaseDate")
        }

        guard let posterPath = showDict["posterPath"] as? String else {
            throw SerializationError.missing("posterPath")
        }

        self.id = id
        self.name = name
        self.overview = overview
        self.releaseDate = releaseDate
        self.posterPath = posterPath
    }
}
