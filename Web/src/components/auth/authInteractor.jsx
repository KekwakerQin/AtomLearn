import { createUserWithEmail, loginWithEmail, authWithGoogle, sendUserData } from './authService';

export async function updateUserData (user){
	const result = {
		status: false,
		errorMessage: ''
	}
		try {
			await sendUserData(user);
			result.status = true;
		} catch (err) {
			console.log(err);
			result.errorMessage = err.code;
		}
	return result;
}


// sign up's functions
export async function createUser(email, password) {
	const result = {
		status: false,
		errorMessage: ''
	}
		try {
			await createUserWithEmail(email, password);
			result.status = true;
		} catch (err) {
			console.log(err);
			result.errorMessage = err.code;
		}
	return result;
	};

	export async function googleAuth (){
		const result = {
			status: false,
			errorMessage: ''
		}

		try {
			await authWithGoogle()
			result.status = true;
    } catch (err) {
			console.log(err);
			result.errorMessage = err.code;
    }
		return result;
	}

	// log in's functions
	export async function loginUser(email, password) {
		const result = {
			status: false,
			errorMessage: ''
		}
			try {
				await loginWithEmail(email, password);
				result.status = true;
			} catch (err) {
				console.log(err);
				result.errorMessage = err.code;
			}
		return result;
		};