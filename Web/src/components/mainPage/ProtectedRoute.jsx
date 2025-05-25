// src/components/Dashboard.jsx
import { useEffect, useState } from 'react';
import { auth } from '../../firebase';
import { useNavigate } from 'react-router-dom';

const Dashboard = () => {
  const navigate = useNavigate();
  const [userEmail, setUserEmail] = useState('');

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(user => {
      if (!user) {
        navigate('/auth');
      } else {
        setUserEmail(user.email);
        // Проверяем токен каждые 5 минут
        const interval = setInterval(async () => {
          await user.getIdToken(true); // Принудительное обновление
        }, 300000);
        
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
      <button onClick={handleLogout}>Выйти</button>
    </div>
  );
};

export default Dashboard;