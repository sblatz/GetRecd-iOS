//
//  ProfileMovieViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth
import WebKit

class ProfileMovieViewController: UITableViewController {

    var movieIds = [(String)]()

    let blurEffectView = UIVisualEffectView(effect: nil)
    
    
    var videoView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blurEffectView.isUserInteractionEnabled = true
        blurEffectView.effect = UIBlurEffect(style: .dark)
        //always fill the view
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.blurEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimissTrailer)))
        
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(userScript)
        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController
        wkWebConfig.requiresUserActionForMediaPlayback = false
        
        videoView = WKWebView(frame: CGRect(x: 8, y: (self.view.frame.height / 2) - ((self.view.frame.width - 16) * (9 / 32)), width: self.view.frame.width - 16, height: (self.view.frame.width - 16) * (9 / 16)), configuration: wkWebConfig)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        DataService.sharedInstance.getLikedMovies(uid: uid, sucesss: { (movieIds) in
            self.movieIds = movieIds
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) { (error) in
            // TODO: Show error
            print(error.localizedDescription)
        }
    }
    
    @IBAction func onCheck(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 1
        }
        return movieIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "BarCell", for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

        let movie = movieIds[indexPath.row]

        cell.artworkView.tag = indexPath.row
        cell.artworkView.isUserInteractionEnabled = true
        cell.artworkView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTrailer(_:))))
        MovieService.sharedInstance.getMovie(with: movie) { (movie) in
            cell.movie = movie
        }

        return cell
    }
    
    @objc func dimissTrailer() {
        
        videoView.removeFromSuperview()
        blurEffectView.removeFromSuperview()
        
        
    }
    
    @objc func showTrailer(_ sender: Any) {
        let tap = sender as! UITapGestureRecognizer
        let artworkView = tap.view!
        
        let movieId = movieIds[artworkView.tag]
        MovieService.sharedInstance.getVideo(id: Int(movieId)!, width: Int(view.frame.width - 16), height: Int((view.frame.width - 16) * (9 / 16)), success: { (htm) in
            
            
            DispatchQueue.main.async {
                
                
                self.blurEffectView.frame = self.view.bounds
                self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                self.view.addSubview(self.blurEffectView) //if you have more UIViews, use an insertSubview
                
                self.videoView.loadHTMLString(htm, baseURL: nil)
                
                self.view.addSubview(self.videoView)
            }
        }) {
            print("Error loading video")
        }
    }
}
