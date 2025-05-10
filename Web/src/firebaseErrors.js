export const firebaseErrorsRu = {
    "auth/invalid-email": "Неверный формат email",
    "auth/user-not-found": "Пользователь не найден",
    "auth/wrong-password": "Неверный пароль",
    "auth/email-already-in-use": "Email уже занят",
    "auth/weak-password": "Пароль слишком простой (минимум 6 символов)",
    "auth/popup-closed-by-user": "Вы закрыли окно авторизации",
    // Добавьте все нужные ошибки из документации Firebase
  };
  
  export const translateFirebaseError = (errorCode) => {
    return firebaseErrorsRu[errorCode] || "Произошла неизвестная ошибка";
  };