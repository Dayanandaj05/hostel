const admin = require("firebase-admin");
try {
  admin.initializeApp({ projectId: "psg-hostel-app" });
  admin.auth().getUserByEmail('admin@psgtech.hostel')
    .then(async (u) => {
      console.log("Found admin user with UID:", u.uid);
      await admin.auth().updateUser(u.uid, { email: 'admin@psgtech.ac.in' });
      console.log("Auth email updated to admin@psgtech.ac.in");

      const db = admin.firestore();
      await db.collection('users').doc(u.uid).update({ email: 'admin@psgtech.ac.in' });
      console.log("Firestore email updated to admin@psgtech.ac.in");
      
      process.exit(0);
    })
    .catch(e => {
      console.error("Firebase error:", e.message);
      process.exit(1);
    });
} catch(e) {
  console.error("Init error:", e.message);
  process.exit(1);
}
