// Firebase Cloud Messaging Service Worker for Tashil Real Estate Web
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAFdowgW1gwx_PU6d19KCC_jiQl5NTMRuc',
  appId: '1:534001947779:web:f8c9c5bc18ce69947ff7b6',
  messagingSenderId: '534001947779',
  projectId: 'tashil-proptech-os',
  authDomain: 'tashil-proptech-os.firebaseapp.com',
  storageBucket: 'tashil-proptech-os.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background push notification received: ', payload);
  const notificationTitle = payload.notification ? payload.notification.title : (payload.data ? payload.data.title : 'تسهيل عقار - Tashil Aqar');
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : (payload.data ? payload.data.body : ''),
    icon: '/favicon.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
