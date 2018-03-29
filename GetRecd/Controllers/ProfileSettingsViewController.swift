//
//  ProfileSettingsViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/20/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseStorage

class ProfileSettingsViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var bioTextView: UITextView!

    var imagePicker: UIImagePickerController!
    var currentUser: User!
    var profilePictureImage: UIImage? = #imageLiteral(resourceName: "profile-pic")
    var profilePictureURL: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

            bioTextView.delegate = self

        //let button = SpotifyLoginButton(viewController: self, scopes: [.streaming, .userLibraryRead])
        //var cell = linkSpotifyButton.superview?.superview!
        //cell?.addSubview(button)
        //button.frame = linkSpotifyButton.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width/2
            self.profilePicture.image = self.profilePictureImage
            self.bioTextView.text = self.currentUser.bio
        }


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("in view will appear")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 2
        case 3:
            return 4
        default:
            return 0
        }
    }

    @IBAction func savePressed(_ sender: Any) {
        saveUserInfo()
        dismiss(animated: true, completion: nil)
    }
    
    
    func deleteAccount() {
        AuthService.instance.deleteAccount { (success) -> (Void) in
            if success {
                print("SUCCESS DELETE ACCOUNT")
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "SignIn", sender: self)
                }
            } else {
                print("DELETE ACCOUNT FAILED")
            }
        }
    }
    
    func saveUserInfo() {
        var userData = currentUser.userDict
        userData["bio"] = bioTextView.text
        
        if profilePictureURL != nil {
            userData["profilePictureURL"] = profilePictureURL
        }
        
        DataService.instance.createOrUpdateUser(uid: currentUser.userID, userData: userData)
        
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
            // Music Authorization
            case 2:
                switch indexPath.row {
                    case 0:
                        if (MusicService.sharedInstance.spotifyAuth.session != nil) {
                            MusicService.sharedInstance.setupSpotify()
                        } else {
                            let authURL = MusicService.sharedInstance.spotifyAuth.spotifyAppAuthenticationURL()
                            UIApplication.shared.open(authURL!, options: [:], completionHandler: nil)
                        }
                
                    case 1:
                        print("Authenticate with Apple music")
                        MusicService.sharedInstance.requestAppleCloudServiceAuthorization()
                        MusicService.sharedInstance.requestAppleMediaLibraryAuthorization()
                    default:
                        break
                    }
            // Account Deletion & Log Out
            case 3:
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
            default:
                break
        }
    }

    @IBAction func editPicturePressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.imagePicker = UIImagePickerController()
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
        
        profilePictureImage = selectedImage
        guard let profileImage = profilePictureImage, let imageData = UIImageJPEGRepresentation(profileImage, 0.2) else {
            return
        }
        
        let imageUID = NSUUID().uuidString
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        DataService.instance.REF_PROFILE_PICS.child(imageUID).putData(imageData, metadata: metaData) { (metaData, error) in
            
            if error != nil {
                print("IMAGE UPLOAD ERROR: Image wasn't uploaded to Firebase")
            } else {
                print("IMAGE UPLOAD SUCCESS: Image was uploaded to Firebase")
                guard let imageURL = metaData?.downloadURL()?.absoluteString else {
                    return
                }
                
                self.profilePictureURL = imageURL
                print("IMAGE URL: \(String(describing: self.profilePictureURL))")
                
            }
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
}
