// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries
const firebaseConfig = {
    apiKey: "AIzaSyCRTi0kvX8t16QIzPz3QOLwOCRizNeITpM",
    authDomain: "sps-bus-tracker.firebaseapp.com",
    databaseURL: "https://sps-bus-tracker-default-rtdb.firebaseio.com",
    projectId: "sps-bus-tracker",
    storageBucket: "sps-bus-tracker.appspot.com",
    messagingSenderId: "1005772135057",
    appId: "1:1005772135057:web:c81a978c4861352b7afd30",
    measurementId: "G-DV370G49WL"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
