const functions = require('firebase-functions');
const apn = require('apn');
const admin = require('firebase-admin');

var serviceAccount = require("./serviceKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://getrecd-1652a.firebaseio.com"
});

var db = admin.firestore();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

let provider = new apn.Provider({
  token: {
    key: "AuthKey_53V77267W6.p8",
    keyId: "53V77267W6",
    teamId: "3YC9K4952Y"
  },
  production: false
});


var query = db.collection("Notifications");

var observer = query.onSnapshot(querySnapshot => {
  console.log(`Received query snapshot of size ${querySnapshot.size}`);
  querySnapshot.docChanges.forEach(function(change) {
            if (change.type === "added") {
                let type = change.doc.data().type;
                let uid = change.doc.data().uid;
		        let message = change.doc.data().message;
                if (type == "friendRequest") {
                  db.collection("Users").doc(uid).get().then(function(userInfo) {
                      let data = userInfo.data();

                      let deviceToken = data.token;
                      if (deviceToken !== undefined) {

                      var note = new apn.Notification();

                      note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
                      note.badge = 1;
                      note.sound = "ping.aiff";
                      note.alert = message;
                      //note.payload = {"uid": change.doc.data().event};

                      note.topic = "com.cs407.GetRecd";
                      provider.send(note, deviceToken).then( (result) => {
                        // see documentation for an explanation of result
                        console.log(result);
                      });
                    }

                  });

                  query.doc(change.doc.id).delete();
                }
            }
        });
}, err => {
  console.log(`Encountered error: ${err}`);
});
// exports.eventEdited = functions.firestore
//   .document("events/{eventId}").onUpdate((event) => {
//     // ... Your code here
//     console.log(eventId);
//   });
