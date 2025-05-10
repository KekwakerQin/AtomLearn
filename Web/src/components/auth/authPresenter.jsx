import { useState, useEffect } from 'react';
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { translateFirebaseError } from '../../firebaseErrors';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '../../firebase';
import { updateUserData, createUser, loginUser, googleAuth} from './authInteractor';
import './authStyles.css';

// authSwitch
export const AuthSwitch = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [isCheckingAuth, setIsCheckingAuth] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
				navigate('/dashboard');
				await updateUserData(user);
      } else {
        setIsCheckingAuth(false);
      }
    });

    return () => unsubscribe();
  }, [navigate]);

  if (isCheckingAuth) {
    return (
      <div className="auth-container">
        <div className="auth-card">
          <div className="auth-loading">
            <div className="auth-spinner"></div>
            <p>Checking authentication...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`auth-switch-container ${isLogin ? 'login-view' : 'signup-view'}`}>
      {isLogin ? (
        <Login 
          switchToSignup={() => {
            setIsLogin(false);
            window.scrollTo(0, 0);
          }} 
          onSuccess={() => navigate('/dashboard')}
        />
      ) : (
        <Signup 
          switchToLogin={() => {
            setIsLogin(true);
            window.scrollTo(0, 0);
          }} 
          onSuccess={() => navigate('/dashboard')}
        />
      )}
    </div>
  );
};

// Signup
const Signup = ({ switchToLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleSignup = async (e) => {
    e.preventDefault();
    
    if (password !== confirmPassword) {
      setError("Пароли не совпадают");
      return;
    }
    
    setLoading(true);
    setError('');
    
		const isUserCreated = await createUser(email, password);
		
		if(isUserCreated.status === false){
			setError(translateFirebaseError(isUserCreated.errorMessage))
			setLoading(false);
		}
  };

  const handleGoogleSignup = async () => {
		const isGoogleSigned = await googleAuth()
		if(isGoogleSigned.status === false){
			setError(isGoogleSigned.errorMessage)
		}
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <h1 className="auth-title">Создать аккаунт</h1>
        <p className="auth-subtitle">Заполните форму для регистрации</p>
        
        <form className="auth-form" onSubmit={handleSignup}>
          {error && <div className="error-message">{error}</div>}
          
          <div className="input-group">
            <label htmlFor="email" className="input-label">Email</label>
            <input
              id="email"
              type="email"
              className="input-field"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          
          <div className="input-group">
            <label htmlFor="password" className="input-label">Пароль</label>
            <div className="password-input-container">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                className="input-field"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button 
                type="button" 
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? "🙈" : "👁️"}
              </button>
            </div>
          </div>
          
          <div className="input-group">
            <label htmlFor="confirmPassword" className="input-label">Подтвердите пароль</label>
            <input
              id="confirmPassword"
              type={showPassword ? "text" : "password"}
              className="input-field"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />
          </div>
          
          <button 
            type="submit" 
            className="auth-button"
            disabled={loading}
          >
            {loading ? "Регистрация..." : "Зарегистрироваться"}
          </button>
        </form>
        
        <div className="auth-footer">
          Уже есть аккаунт?{' '}
          <span className="auth-link" onClick={switchToLogin}>
            Войти
          </span>
        </div>
        
        <div className="divider">или</div>
        
        <div className="social-buttons">
          <button className="social-button" onClick={handleGoogleSignup}>
            <img src="https://www.google.com/favicon.ico" alt="Google" width="24" />
          </button>
        </div>
      </div>
    </div>
  );
};

// Login
const Login = ({ switchToSignup }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
		const isUserLogined = await loginUser(email, password);
		
		if(isUserLogined.status === false){
			setError(translateFirebaseError(isUserLogined.errorMessage))
			setLoading(false);
		}
  };

  const handleGoogleLogin= async () => {
		const isGoogleSigned = await googleAuth()
		if(isGoogleSigned.status === false){
			setError(isGoogleSigned.errorMessage)
		}
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <h1 className="auth-title">Вход в аккаунт</h1>
        <p className="auth-subtitle">Введите свои данные для входа</p>
        
        <form className="auth-form" onSubmit={handleLogin}>
          {error && <div className="error-message">{error}</div>}
          
          <div className="input-group">
            <label htmlFor="email" className="input-label">Email</label>
            <input
              id="email"
              type="email"
              className="input-field"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          
          <div className="input-group">
            <label htmlFor="password" className="input-label">Пароль</label>
            <div className="password-input-container">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                className="input-field"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button 
                type="button" 
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? "🙈" : "👁️"}
              </button>
            </div>
          </div>
          
          <button 
            type="submit" 
            className="auth-button"
            disabled={loading}
          >
            {loading ? "Вход..." : "Войти"}
          </button>
        </form>
        
        <div className="auth-footer">
          Нет аккаунта?{' '}
          <span className="auth-link" onClick={switchToSignup}>
            Зарегистрироваться
          </span>
        </div>
        
        <div className="divider">или</div>
        
        <div className="social-buttons">
          <button className="social-button" onClick={handleGoogleLogin}>
            <img src="https://www.google.com/favicon.ico" alt="Google" width="24" />
          </button>
        </div>
      </div>
    </div>
  );
};
