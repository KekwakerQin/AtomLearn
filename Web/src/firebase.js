import { initializeApp } from 'firebase/app';
import { 
    getAuth,
    onAuthStateChanged,
    onIdTokenChanged
} from 'firebase/auth';
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
    apiKey: "AIzaSyCke3Npx4gRUPj0a4J0qRZZyh_7-ZMk7LA",
    authDomain: "atomlearn-e0788.firebaseapp.com",
    projectId: "atomlearn-e0788",
    storageBucket: "atomlearn-e0788.firebasestorage.app",
    messagingSenderId: "136846674490",
    appId: "1:136846674490:web:687811f345b49f75fbc303",
    measurementId: "G-D4X7ERS6BR"
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app)
export const auth = getAuth(app);

export { onAuthStateChanged, onIdTokenChanged }