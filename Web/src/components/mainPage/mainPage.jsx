// src/components/Dashboard.jsx
import { useEffect, useState } from 'react';
import { auth, onIdTokenChanged, db } from '../../firebase';
import { doc, setDoc } from 'firebase/firestore';
import { useNavigate } from 'react-router-dom';
import { Button } from '../UI/UIButton';
import './mainPage.css';
import {translation} from '../switchLanguage/locales'
import { useLanguage } from '../switchLanguage/languageContext';

const MainPage = () => {
  const navigate = useNavigate();
  // const [userEmail] = useState('');
	const {language, toggleLanguage} = useLanguage();
	const text = translation[language];

  useEffect(() => {
    const handleTokenRefresh = async (user) => {
      const token = await user.getIdToken(true); // Принудительное обновление
      
      await setDoc(doc(db, 'users', user.uid), {
        currentToken: token,
        tokenLastUpdated: new Date()
      }, { merge: true });
    };

    const unsubscribe = onIdTokenChanged(auth, async (user) => {
      if (user) {
        await handleTokenRefresh(user);
        // Интервал для проверки: 5 минут.
        const interval = setInterval(() => handleTokenRefresh(user), 300000);
        return () => clearInterval(interval);
      }
    });

    return () => unsubscribe();
  }, [navigate]);

  // const handleLogout = async () => {
  //   await auth.signOut();
  //   navigate('/auth');
  // };

  return (
    <div className="mainpage">
			<header className="mainpage-header">
				<div className="logo-container">
					<span className="logo-text">
						{text.ru.mainPage.mainPageLogo}
					</span>
				</div>
				<Button className = 'language-switch-button' type="submit" onClick={toggleLanguage}>
					{language === 'ru'? 'ENG' : 'RU'}
				</Button>
			</header>
			<section className="mainpage-section">
				<div className="mainpage-text">
					<h1 className="mainpage-title">
						{text.ru.mainPage.mainPageTitle}
					</h1>
					<span className="mainpage-subtitle">
						{text.ru.mainPage.mainPageSubtitle}
					</span>
				</div>
				<img src="./logo.svg" alt="mainpage-image" className="mainpage-img" />
			</section>
			<footer className="mainpage-footer">
				<Button className = 'mainpage-footer-button boards-button' type="button" onClick={toggleLanguage}>
					<img src="" alt="" />
				</Button>
				<Button className = 'mainpage-footer-button friends-button' type="button" onClick={toggleLanguage}>
					<img src="" alt="" />
				</Button>
				<Button className = 'mainpage-footer-button dashboard-button' type="button" onClick={toggleLanguage}>
					<img src="" alt="" />
				</Button>
			</footer>
    </div>
  );
};

export default MainPage;