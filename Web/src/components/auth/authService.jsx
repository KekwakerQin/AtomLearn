import { useState } from 'react';
import { auth } from '../../firebase';
import { createUserWithEmailAndPassword, signInWithEmailAndPassword, GoogleAuthProvider, signInWithPopup, getAuth } from 'firebase/auth';
import { translateFirebaseError } from '../../firebaseErrors';

// auth switch functions
export const auth = getAuth(app);

export async function sendUserData(user) {
				const token = await user.getIdToken();

				// Сохраняем в Firestore
				await setDoc(doc(db, 'users', user.uid), {
				uid : user.uid,
				username : "",
				photoURL : "",
				registeredAt : "",
				coins : "0",
				email: user.email,
				lastLogin: new Date(),
				currentToken: token, // Сам токен
				tokenExpires: new Date(Date.now() + 3600 * 1000) // Через 1 час
				}, { merge: true }); // merge: true для обновления, а не перезаписи

				// console.log(`Текущий токен: ${token}`);
				navigate('/dashboard');
		}

// sign up's functions
export async function createUserWithEmail (auth, email, password) {
	await createUserWithEmailAndPassword(auth, email, password);
}

export async function signUpWithGoogle(){
	const provider = new GoogleAuthProvider();
	await signInWithPopup(auth, provider);
}

// log in's functions
export async function loginWithEmail (auth, email, password) {
	await signInWithEmailAndPassword(auth, email, password);
}