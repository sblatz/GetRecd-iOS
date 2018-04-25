//
//  ProfileSettingsViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/20/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth
import MessageUI

class ProfileSettingsViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var spotifyAuthCell: UITableViewCell!
    @IBOutlet weak var appleMusicAuthCell: UITableViewCell!
    @IBOutlet weak var navbarCell: UITableViewCell!
    
    var imagePicker: UIImagePickerController!
    var currentUser: User!
    var profilePictureImage: UIImage? = #imageLiteral(resourceName: "profile-pic")
    var profilePictureURL: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        self.navigationItem.hidesBackButton = true
        
        
        let saveButton = UIButton(type: .custom)
        saveButton.frame = CGRect(x: 0.0, y: 0.0, width: 35, height: 35)
        saveButton.setImage(UIImage(named:"save-button"), for: .normal)
        saveButton.addTarget(self, action: #selector(savePressed(_:)), for: .touchUpInside)
        
        let navBarItem = UIBarButtonItem(customView: saveButton)
        let currWidth = navBarItem.customView?.widthAnchor.constraint(equalToConstant: 24)
        currWidth?.isActive = true
        let currHeight = navBarItem.customView?.heightAnchor.constraint(equalToConstant: 24)
        currHeight?.isActive = true
        self.navigationItem.rightBarButtonItem = navBarItem
        
        bioTextView.delegate = self
        
        if MusicService.sharedInstance.isSpotifyLoggedIn() {
            spotifyAuthCell.textLabel?.text = "Unlink Spotify"
        }
        
        if MusicService.sharedInstance.isAppleMusicLoggedIn() {
            appleMusicAuthCell.textLabel?.text = "Unlink Apple Music"
        }
        
        getCurrentUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //
        //        DispatchQueue.main.async {
        //            self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width/2
        //            self.profilePicture.image = self.profilePictureImage
        //            self.bioTextView.text = self.currentUser.bio
        //        }

        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("in view will appear")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "SpotifyLoggedIn"), object: nil, queue: OperationQueue.main) { (notification) in
            self.spotifyAuthCell.textLabel?.text = "Unlink Spotify"
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "AppleMusicLoggedIn"), object: nil, queue: OperationQueue.main) { (notification) in
            self.appleMusicAuthCell.textLabel?.text = "Unlink Apple Music"
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "SpotifyLoggedIn"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AppleMusicLoggedIn"), object: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 2
        case 2:
            return 4
        case 3:
            return 1
        default:
            return 0
        }
    }

    @IBAction func savePressed(_ sender: Any) {
        saveUserInfo()
        navigationController?.popViewController(animated: true)
    }
    
    
    func deleteAccount() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Tell user account not signed in
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "SignIn", sender: self)
            }
            return
        }
        DataService.sharedInstance.deleteUser(uid: uid, success: {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "SignIn", sender: self)
            }
        }) { (error) in
            // TODO: Show error deleting user
            print(error.localizedDescription)
        }
    }
    
    func saveUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Tell user account not signed in
            return
        }
        
        var newUserData = [String: Any]()
        
        if let bio = bioTextView.text {
            newUserData["bio"] = bioTextView.text
        }
        
        DataService.sharedInstance.updateUser(uid: uid, userData: newUserData, success: { (user) in
            // TODO: Notify user that ccount is updated
            print("Updated")
        }) { (error) in
            
            // TODO: Show error in updating user
            print(error.localizedDescription)
        }
        
        if let image = profilePicture.image {
            DataService.sharedInstance.setProfilePicture(uid: uid, image: image, success: { (url) in
                print(url)
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
    }
    
    func logOut() {
        AuthService.instance.signOut { (success) -> (Void) in
            if success {
                print("SUCCESS SIGN OUT")
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "SignIn", sender: self)
                }
            } else {
                print("SIGN OUT FAILED")
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section: \(indexPath.section), Cell: \(indexPath.row)")


        switch indexPath.section {
        case 0:
            guard let uid = Auth.auth().currentUser?.uid else {
                // TODO: Tell user account not signed in
                return
            }
            switch indexPath.row {
            // Movies Privacy
            case 0:
                
                let alertController = UIAlertController(title: "Movie Privacy", message:"Who should be able to see movies you like as well as movies recommended to you?", preferredStyle: UIAlertControllerStyle.alert)

                alertController.addAction(UIAlertAction(title: "Only Me", style: .default, handler: { (action) in
                    // Call backend function to update privacy preferences
                    DataService.sharedInstance.setPrivacyFor(category: "Movie", privacy: true, uid: uid, completion: {
                        print("completed privacy!")
                    })
                }))

                alertController.addAction(UIAlertAction(title: "Friends", style: .default, handler: { (action) in
                    // Call backend function to update privacy preferences
                    DataService.sharedInstance.setPrivacyFor(category: "Movie", privacy: false, uid: uid, completion: {
                        print("completed privacy!")
                    })
                }))

                present(alertController, animated: true, completion: nil)

            // TV Show Privacy
            case 1:
                let alertController = UIAlertController(title: "Show Privacy", message:"Who should be able to see tv shows you like as well as shows recommended to you?", preferredStyle: UIAlertControllerStyle.alert)

                alertController.addAction(UIAlertAction(title: "Only Me", style: .default, handler: { (action) in
                    // Call backend function to update privacy preferences
                    DataService.sharedInstance.setPrivacyFor(category: "Show", privacy: true, uid: uid, completion: {
                        print("completed privacy!")
                    })
                }))

                alertController.addAction(UIAlertAction(title: "Friends", style: .default, handler: { (action) in
                    // Call backend function to update privacy preferences
                    DataService.sharedInstance.setPrivacyFor(category: "Show", privacy: false, uid: uid, completion: {
                        print("completed privacy!")
                    })
                }))
                present(alertController, animated: true, completion: nil)

            // Music Privacy
            case 2:
                let alertController = UIAlertController(title: "Music Privacy", message:"Who should be able to see music you like as well as music recommended to you?", preferredStyle: UIAlertControllerStyle.alert)

                alertController.addAction(UIAlertAction(title: "Only Me", style: .default, handler: { (action) in
                    // Call backend function to update privacy preferences
                    DataService.sharedInstance.setPrivacyFor(category: "Music", privacy: true, uid: uid, completion: {
                        print("completed privacy!")
                    })
                }))

                alertController.addAction(UIAlertAction(title: "Friends", style: .default, handler: { (action) in
                    // Call backend function to update privacy preferences
                    DataService.sharedInstance.setPrivacyFor(category: "Music", privacy: false, uid: uid, completion: {
                        print("completed privacy!")
                    })
                }))
                present(alertController, animated: true, completion: nil)

            default:
                break
            }

        // Music Authorization
        case 1:
            switch indexPath.row {
            case 0:
                if MusicService.sharedInstance.isSpotifyLoggedIn() {
                    MusicService.sharedInstance.deAuthenticateSpotify()
                    spotifyAuthCell.textLabel?.text = "Link Spotify"
                } else {
                    if MusicService.sharedInstance.spotifyAuth.session != nil {
                        MusicService.sharedInstance.setupSpotify()
                    } else {
                        MusicService.sharedInstance.authenticateSpotify()
                    }
                }
            case 1:
                if MusicService.sharedInstance.isAppleMusicLoggedIn() {
                    MusicService.sharedInstance.deAuthenticateAppleMusic()
                    appleMusicAuthCell.textLabel?.text = "Link Apple Music"
                } else {
                    MusicService.sharedInstance.requestAppleCloudServiceAuthorization(success: { (success) in
                        print("Apple music authorized \(success)")
                        if success {
                            DispatchQueue.main.async {
                                self.appleMusicAuthCell.textLabel?.text = "Unlink Apple Music"
                            }
                        }
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                }
            default:
                break
            }
        // Account Deletion & Log Out
        case 2:
            switch indexPath.row {
            case 2:
                let alert = UIAlertController(title: "Deleting Account", message: "Are you sure you want to delete your account? This cannot be undone!", preferredStyle: .alert)
                let yes = UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
                    self.deleteAccount()
                })

                let no = UIAlertAction(title: "No", style: .default, handler: { (action) in
                    alert.dismiss(animated: true, completion: nil)
                })

                alert.addAction(yes)
                alert.addAction(no)
                self.present(alert, animated: true, completion: nil)
            case 3:
                print("logging out")
                logOut()
            default:
                break
            }
            
        // Sending Feedback
        case 3:
            switch indexPath.row {
            case 0:
                let mailComposeViewController = configureMailController()
                if(MFMailComposeViewController.canSendMail()){
                    self.present(mailComposeViewController, animated: true, completion: nil)
                } else{
                    showMailError()
                }
            default:
                break
            }
            
        default:
            break
        }
    }

    @IBAction func editPicturePressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.imagePicker = UIImagePickerController()
            self.imagePicker.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: "OpenSans-Bold", size: 16.0)!]
            self.imagePicker.navigationBar.tintColor = .white
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.imagePicker.allowsEditing = true
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage else {
            print("A VALID IMAGE WAS NOT SELECTED")
            return
        }
        
        DispatchQueue.main.async {
            self.profilePicture.image = selectedImage
        }
        
        DispatchQueue.main.async {
            self.imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        let count = bioTextView.text.count
        if range.length + range.location > count {
            return false
        }
        
        let newLength = count + text.count - range.length
        return newLength <= 140
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func getCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // TODO: Show error in getting current user's uid
            return
        }
        DataService.sharedInstance.getUser(uid: uid, success: { (user) in
            DispatchQueue.main.async {
                self.bioTextView.text = user.bio ?? "No Bio"
            }
            
        }) { (error) in
            // TODO: Show error in retrieivng user
            print(error.localizedDescription)
        }
        
        DataService.sharedInstance.getProfilePicture(uid: uid, success: { (exists, image) in
            DispatchQueue.main.async {
                self.profilePicture.image = image
            }
        }) { (error) in
            // TODO: Show error in retrieivng user picture
            print(error.localizedDescription)
        }
    }
    
    func configureMailController() -> MFMailComposeViewController{
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["cs407getrecd@gmail.com"])
        mailComposerVC.setSubject("Feedback")
        return mailComposerVC
    }
    
    func showMailError(){
        let sendMailErrorAlert = UIAlertController(title: "Could not send email", message: "Your device couldn't send the email", preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "OK", style: .default, handler: nil)
        sendMailErrorAlert.addAction(dismiss)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
