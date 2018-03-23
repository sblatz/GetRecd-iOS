//
//  MovieService.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/22/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import TMDBSwift

class MovieService: NSObject {

    static var sharedInstance = MovieService()

    override init() {
        super.init()
        TMDBConfig.apikey = "ea90c2a3942b798ebea3a03f2f7c54b5"
    }

    func searchTMDB(forMovie: String, completion: (([Movie]?, Error?) -> Void)? = nil) {
        SearchMDB.movie(query: forMovie, language: "en", page: 1, includeAdult: false, year: nil, primaryReleaseYear: nil) { (data, movies) in
            if let complete = completion {
                if let tmdbMovieArray = movies {
                    var movies = [Movie]()
                    for tmdbMovie in tmdbMovieArray {
                        var movieDictionary = [String: Any]()

                        movieDictionary["id"] = tmdbMovie.id
                        movieDictionary["name"] = tmdbMovie.title
                        movieDictionary["releaseDate"] = tmdbMovie.release_date
                        movieDictionary["posterPath"] = tmdbMovie.poster_path
                        movieDictionary["overview"] = tmdbMovie.overview

                        do {
                            try movies.append(Movie(movieDict: movieDictionary))
                        }
                        catch {
                            print(error)
                            return
                        }
                    }

                    complete(movies, nil)

                } else {
                    complete(nil, nil)
                }
            }
        }
    }

    // Function to login to TMDB
    func loginToTMDB() {
    }
}
