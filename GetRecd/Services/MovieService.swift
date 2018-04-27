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
    
    let baseURL = "https://api.themoviedb.org/3/movie/"

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
                        }
                    }

                    complete(movies, nil)

                } else {
                    complete(nil, nil)
                }
            }
        }
    }

    func getMovie(with id: String, completion: @escaping (Movie) -> ()) {
        MovieMDB.movie(movieID: Int(id)) { (apiReturn, movie) in
            if let movie = movie {
                var movieDictionary = [String: Any]()

                movieDictionary["id"] = movie.id
                movieDictionary["name"] = movie.title
                movieDictionary["releaseDate"] = movie.release_date
                movieDictionary["posterPath"] = movie.poster_path
                movieDictionary["overview"] = movie.overview
                
                do {
                    completion(try Movie(movieDict: movieDictionary))
                } catch {
                    fatalError("An error occurred: \(error.localizedDescription)")
                }

            }
        }
    }
    
    func getRecommendedMovies(id: String, success: @escaping ([Movie]) -> ()) {
        let urlString = "https://api.themoviedb.org/3/movie/\(id)/recommendations"
        var movies:[Movie] = []
        var urlComp = URLComponents(string: urlString)
        let qItems = [URLQueryItem(name: "api_key", value: TMDBConfig.apikey)]
        urlComp?.queryItems = qItems
        let url = urlComp!.url!
        let urlSession = URLSession(configuration: .default)
        let task = urlSession.dataTask(with: url, completionHandler: { (data, response, error) in
            if error == nil, let data = data {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? Dictionary<String, Any> {
                    let recommendations = responseDictionary["results"] as! [Dictionary<String, Any>]
                    
                    for rec in recommendations {
                        var movieDictionary = [String: Any]()
                        movieDictionary["id"] = rec["id"]
                        movieDictionary["name"] = rec["title"]
                        movieDictionary["releaseDate"] = rec["release_date"]
                        movieDictionary["posterPath"] = rec["poster_path"]
                        movieDictionary["overview"] = rec["overview"]
                        
                        do {
                            try movies.append(Movie(movieDict: movieDictionary))
                        } catch {
                            fatalError("An error occurred: \(error.localizedDescription)")
                        }
                    }
                    
                    success(movies)
                }
            }
        })
        task.resume()
    }
    
    func getVideo(id: Int, width: Int, height: Int, success: @escaping (String) -> (), failure: @escaping () -> ()) {
        let urlString = "\(baseURL)\(id)/videos"
        var urlComp = URLComponents(string: urlString)
        let qItems = [URLQueryItem(name: "api_key", value: TMDBConfig.apikey)]
        urlComp?.queryItems = qItems
        let url = urlComp!.url!
        let urlSession = URLSession(configuration: .default)
        
        let task = urlSession.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                failure()
            } else if let data = data {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? Dictionary<String, Any> {
                    if let videos = responseDictionary["results"] as? [Dictionary<String, Any>], videos.count > 0 {
                        let video = videos[0]
                        let key = video["key"] as! String
                        //let htm = "<!DOCTYPE HTML> <html xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:og=\"http://opengraphprotocol.org/schema/\" xmlns:fb=\"http://www.facebook.com/2008/fbml\"> <head></head> <body style=\"margin:0 0 0 0; padding:0 0 0 0;\"> <iframe width=\"\(width)\" height=\"\(height)\" src=\"http://www.youtube.com/embed/\(key)\" frameborder=\"0\"></iframe> </body> </html> "
                        
                        let htm = "<!DOCTYPE html><html><head><style>body{margin:0px 0px 0px 0px;}</style></head> <body> <div id=\"player\"></div> <script> var tag = document.createElement('script'); tag.src = \"http://www.youtube.com/player_api\"; var firstScriptTag = document.getElementsByTagName('script')[0]; firstScriptTag.parentNode.insertBefore(tag, firstScriptTag); var player; function onYouTubePlayerAPIReady() { player = new YT.Player('player', { width:'\(width)', height:'\(height)', videoId:'\(key)', events: { 'onReady': onPlayerReady, } }); } function onPlayerReady(event) { event.target.playVideo(); } </script> </body> </html>"
                        success(htm)
                    } else {
                        failure()
                    }
                }
            }
        })
        task.resume()
    }
    
    // Function to login to TMDB
    func loginToTMDB() {
    }
}
