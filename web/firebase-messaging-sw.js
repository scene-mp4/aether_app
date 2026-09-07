// web/firebase-messaging-sw.js
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Replace these values with your Firebase project config
// Found in Firebase Console → Project Settings → General → Your apps → Web app
firebase.initializeApp({
  apiKey: "AIzaSyAKC8511MGgxkEoKVsVPxdK8NUQ8z_iM1Y",
  authDomain: "pollutracker-bf276.firebaseapp.com",
  projectId: "pollutracker-bf276",
  storageBucket: "pollutracker-bf276.firebasestorage.app",
  messagingSenderId: "1059412108912",
  appId: "1:1059412108912:web:1300dbb20cc6aff189b6b5",
  measurementId: "G-3HHL2W240B"
});

const messaging = firebase.messaging();

// Handle background messages on web
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message received:', payload);
  const { title, body } = payload.notification;
  self.registration.showNotification(title, { body });
});