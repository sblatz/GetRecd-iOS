//
//  GetRecdUITests.swift
//  GetRecdUITests
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import XCTest

class GetRecdUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEditProfile() {
        let app = XCUIApplication()
        let signInButton = app.buttons["SIGN IN"]
        signInButton.tap()

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("d@m.com")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("123123")
        signInButton.tap()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Profile"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["settings"]/*[[".cells.buttons[\"settings\"]",".buttons[\"settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["edit button"]/*[[".cells.buttons[\"edit button\"]",".buttons[\"edit button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

    }

    func testDeleteAccount() {
        let app = XCUIApplication()
        let signInButton = app.buttons["SIGN IN"]
        signInButton.tap()

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("d@m.com")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("123123")
        signInButton.tap()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Profile"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["settings"]/*[[".cells.buttons[\"settings\"]",".buttons[\"settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["edit button"]/*[[".cells.buttons[\"edit button\"]",".buttons[\"edit button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.swipeUp()
    }

    // MARK - Account Sign in Tests
    func testValidSignIn() {
        let app = XCUIApplication()
        app.buttons["SIGN IN"].tap()

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("sblatz@purdue.edu")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("password")

        app.buttons["SIGN IN"].tap()
    }

    func testInvalidSignIn() {
        let app = XCUIApplication()
        app.buttons["SIGN IN"].tap()

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("sblatz@purdue.edu")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("garbagePassword")

        app.buttons["SIGN IN"].tap()

        let errorLabel = app.staticTexts.element(matching: .any, identifier: "errorLabel").label

    }
    // MARK - Account Creation Tests

    // Test error case for an email being taken
    func testEmailTaken() {
        let app = XCUIApplication()
        app.buttons["GET STARTED"].tap()

        let nameTextField = app.textFields["Name"]
        nameTextField.tap()
        nameTextField.typeText("Sawyer")

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("sdblatz@gmail.com")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("password")

        let confirmPasswordSecureTextField = app.secureTextFields["Confirm Password"]
        confirmPasswordSecureTextField.tap()
        confirmPasswordSecureTextField.typeText("password")

        app.buttons["SIGN UP"].tap()

        let errorLabel = app.staticTexts.element(matching: .any, identifier: "errorLabel").label
        assert(errorLabel == "The email address is already in use by another account.")
    }

    // Test error case of passwords not matching
    func testPasswordMismatch() {
        let app = XCUIApplication()
        app.buttons["GET STARTED"].tap()

        let nameTextField = app.textFields["Name"]
        nameTextField.tap()
        nameTextField.typeText("Sawyer")

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("sdblatz@gmail.com")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("password")

        let confirmPasswordSecureTextField = app.secureTextFields["Confirm Password"]
        confirmPasswordSecureTextField.tap()
        confirmPasswordSecureTextField.typeText("1234345345")

        app.buttons["SIGN UP"].tap()

        let errorLabel = app.staticTexts.element(matching: .any, identifier: "errorLabel").label
        assert(errorLabel == "Please ensure passwords match.")
    }

    // Test error case of no email entered
    func testMissingEmail() {
        let app = XCUIApplication()
        app.buttons["GET STARTED"].tap()

        let nameTextField = app.textFields["Name"]
        nameTextField.tap()
        nameTextField.typeText("Sawyer")

        app.buttons["SIGN UP"].tap()
    }

    // TODO: Make this test actually check for segue (button is not being detected!!)
    // Test successful account creation
    func testSuccessfulLogin() {
        let app = XCUIApplication()
        app.buttons["GET STARTED"].tap()

        let nameTextField = app.textFields["Name"]
        nameTextField.tap()
        nameTextField.typeText("Sawyer")

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("t@ma.com")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("password")

        let confirmPasswordSecureTextField = app.secureTextFields["Confirm Password"]
        confirmPasswordSecureTextField.tap()
        confirmPasswordSecureTextField.typeText("password")
        
        app.buttons["SIGN UP"].tap()
    }
    
    // User Profile Settings/Profile Picture Test
    func testEditProfile() {
        let app = XCUIApplication()
        let signInButton = app.buttons["SIGN IN"]
        signInButton.tap()
        
        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("d@m.com")
        
        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("123123")
        signInButton.tap()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Profile"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["settings"]/*[[".cells.buttons[\"settings\"]",".buttons[\"settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["edit button"]/*[[".cells.buttons[\"edit button\"]",".buttons[\"edit button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
    }
    
    func testDeleteAccount() {
        let app = XCUIApplication()
        let signInButton = app.buttons["SIGN IN"]
        signInButton.tap()
        
        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("d@m.com")
        
        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("123123")
        signInButton.tap()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Profile"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["settings"]/*[[".cells.buttons[\"settings\"]",".buttons[\"settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["edit button"]/*[[".cells.buttons[\"edit button\"]",".buttons[\"edit button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.swipeUp()
    }
}
