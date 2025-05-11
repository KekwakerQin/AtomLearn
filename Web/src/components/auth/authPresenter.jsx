import React from 'react';
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { translateFirebaseError } from '../../firebaseErrors';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '../../firebase';
import { updateUserData, createUser, loginUser, googleAuth} from './authInteractor';
import { Button } from '../UI/UIButton'
import './authStyles.css';
import { useLanguage } from '../switchLanguage/languageContext';
import { translation } from '../switchLanguage/locales';

// authSwitch
export const AuthSwitch = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [isCheckingAuth, setIsCheckingAuth] = useState(true);
  const navigate = useNavigate();
	const {language, toggleLanguage} = useLanguage();
	const text = translation[language];

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
            <p>{text.authSwith}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`auth-switch-container ${isLogin ? 'login-view' : 'signup-view'}`}>
			<Button className = 'language-switch-button' type="submit" onClick={toggleLanguage}>
				{language === 'ru'? 'ENG' : 'RU'}
			</Button>
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
	const {language, toggleLanguage} = useLanguage();
	const text = translation[language];

  const handleSignup = async (e) => {
    e.preventDefault();
    
    if (password !== confirmPassword) {
      setError(text.signupPasswordError);
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
        <h1 className="auth-title">{text.authSignup.signupTitle}</h1>
        <p className="auth-subtitle">{text.authSignup.signupSubtitle}</p>
        
        <form className="auth-form" onSubmit={handleSignup}>
          {error && <div className="error-message">{error}</div>}
          
          <div className="input-group">
            <label htmlFor="email" className="input-label">{text.authSignup.signupEmail}</label>
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
            <label htmlFor="password" className="input-label">{text.authSignup.signupPassword}</label>
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
            <label htmlFor="confirmPassword" className="input-label">{text.authSignup.signupConfirmPassword}</label>
            <input
              id="confirmPassword"
              type={showPassword ? "text" : "password"}
              className="input-field"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />
          </div>
          
          <Button className = 'auth-button' type="submit" disable={loading}>
            {loading ? text.authSignup.signupButtonloading : text.authSignup.signupButton}
					</Button>
        </form>
        
        <div className="auth-footer">
				{text.authSignup.signupFooterQuestion}
          <span className="auth-link" onClick={switchToLogin}>
					{text.authSignup.signupFooterLoginSwitch}
          </span>
        </div>
        
        <div className="divider">{text.authSignup.signupFooterOr}</div>
        
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
	const {language, toggleLanguage} = useLanguage();
	const text = translation[language];
	console.log(text)

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
        <h1 className="auth-title">{text.authLogin.loginTitle}</h1>
        <p className="auth-subtitle">{text.authLogin.loginSubtitle}</p>
        
        <form className="auth-form" onSubmit={handleLogin}>
          {error && <div className="error-message">{error}</div>}
          
          <div className="input-group">
            <label htmlFor="email" className="input-label">{text.authLogin.loginEmail}v</label>
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
            <label htmlFor="password" className="input-label">{text.authLogin.loginPassword}</label>
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
          
          <Button className = 'auth-button' type="submit" disable={loading}>
						{loading ? text.authLogin.loginButtonLoading : text.authLogin.loginButton}
					</Button>
        </form>
        
        <div className="auth-footer">
				{text.authLogin.loginFooterQuestion} 
          <span className="auth-link" onClick={switchToSignup}>
					{text.authLogin.loginFooterSignupSwitch}
          </span>
        </div>
        
        <div className="divider">{text.authLogin.loginFooterOr}</div>
        
        <div className="social-buttons">
          <button className="social-button" onClick={handleGoogleLogin}>
            <img src="https://www.google.com/favicon.ico" alt="Google" width="24" />
          </button>
        </div>
      </div>
    </div>
  );
};
