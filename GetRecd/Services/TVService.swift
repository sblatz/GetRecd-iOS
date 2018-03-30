//
//  File.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import TMDBSwift

class TVService: NSObject {

    static var sharedInstance = TVService()

    override init() {
        super.init()
        TMDBConfig.apikey = "ea90c2a3942b798ebea3a03f2f7c54b5"
    }

    func searchTMDB(forShow: String, completion: (([Show]?, Error?) -> Void)? = nil) {
        SearchMDB.tv(query: forShow, page: 1, language: "en", first_air_date_year: nil) { (data, shows) in
            if let complete = completion {
                if let tmdbShowArray = shows {
                    var shows = [Show]()
                    for tmdbShow in tmdbShowArray {
                        var showDictionary = [String: Any]()

                        showDictionary["id"] = tmdbShow.id
                        showDictionary["name"] = tmdbShow.name
                        showDictionary["releaseDate"] = tmdbShow.first_air_date
                        showDictionary["posterPath"] = tmdbShow.poster_path
                        showDictionary["overview"] = tmdbShow.overview

                        do {
                            try shows.append(Show(showDict: showDictionary))
                        }
                        catch {
                            print(error)
                        }
                    }

                    complete(shows, nil)

                } else {
                    complete(nil, nil)
                }
            }
        }
    }

    func getShow(with id: String, completion: @escaping (Show) -> ()) {
        TVMDB.tv(tvShowID: Int(id), language: "en") { (apiReturn, tvShow) in
            if let show = tvShow {
                var showDictionary = [String: Any]()

                showDictionary["id"] = show.id
                showDictionary["name"] = show.name
                showDictionary["releaseDate"] = show.first_air_date
                showDictionary["posterPath"] = show.poster_path
                showDictionary["overview"] = show.overview

                do {
                    completion(try Show(showDict: showDictionary))
                } catch {
                    fatalError("An error occurred: \(error.localizedDescription)")
                }

            }
        }
    }

    func getRecommendedTV(id: String, success: @escaping ([Show]) -> ()) {
        let urlString = "https://api.themoviedb.org/3/tv/\(id)/recommendations"
        var shows:[Show] = []
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
                        var showDictionary = [String: Any]()
                        showDictionary["id"] = rec["id"]
                        showDictionary["name"] = rec["title"]
                        showDictionary["releaseDate"] = rec["release_date"]
                        showDictionary["posterPath"] = rec["poster_path"]
                        showDictionary["overview"] = rec["overview"]

                        do {
                            try shows.append(Show(showDict: showDictionary))

                        } catch {
                            fatalError("An error occurred: \(error.localizedDescription)")
                        }
                    }

                    success(shows)
                }
            }
        })
        task.resume()
    }
}
