import { auth, db } from '../../firebase';
import { doc, setDoc } from 'firebase/firestore';
import { createUserWithEmailAndPassword, signInWithEmailAndPassword, GoogleAuthProvider, signInWithPopup } from 'firebase/auth';

// auth switch functions

export async function sendUserData(user) {
	console.log('user data is updated');
	const token = await user.getIdToken();
	// Сохраняем в Firestore
	await setDoc(doc(db, 'users', user.uid), {
	coins : "0",
	photoURL : "",
	uid : user.uid,
	lastLogin: new Date(),
	currentToken: token, // Сам токен
	tokenExpires: new Date(Date.now() + 3600 * 1000) // Через 1 час
	}, { merge: true }); // merge: true для обновления, а не перезаписи

	// console.log(`Текущий токен: ${token}`);
}

// sign up's functions
export async function createUserWithEmail (email, password) {
	await createUserWithEmailAndPassword(auth, email, password);
}

export async function createUserData(user){
		console.log('user is created and data sended');
		const token = await user.getIdToken();
		// Сохраняем в Firestore
		await setDoc(doc(db, 'users', user.uid), {
		coins : "0",
		photoURL : "",
		registeredAt: new Date(),
		uid : user.uid,
		username : "",
		email: user.email,
		lastLogin: new Date(),
		currentToken: token, // Сам токен
		tokenExpires: new Date(Date.now() + 3600 * 1000) // Через 1 час
		}, { merge: true });
}

export async function authWithGoogle(){
	const provider = new GoogleAuthProvider();
	await signInWithPopup(auth, provider);
}
// log in's functions
export async function loginWithEmail (email, password) {
	await signInWithEmailAndPassword(auth, email, password);
}