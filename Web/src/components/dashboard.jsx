// src/components/Dashboard.jsx
import { useEffect, useState } from 'react';
import { auth, onIdTokenChanged, db } from '../firebase';
import { doc, setDoc } from 'firebase/firestore';
import { useNavigate } from 'react-router-dom';
import { Button } from './UIComponents/UIButton';

const Dashboard = () => {
  const navigate = useNavigate();
  const [userEmail] = useState('');

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

  const handleLogout = async () => {
    await auth.signOut();
    navigate('/auth');
  };

  return (
    <div className="dashboard">
      <h1>Добро пожаловать, {userEmail}!</h1>
			<Button className="logout-button" type="button" disabled="false" onClick={handleLogout}>
				Выйти
			</Button>
    </div>
  );
};

export default Dashboard;