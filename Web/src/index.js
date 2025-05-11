import React from 'react';
import ReactDOM from 'react-dom/client';
import './mainView.css';
import reportWebVitals from './reportWebVitals.js';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import {AuthSwitch} from './components/auth/authPresenter.jsx';
import Dashboard from './components/dashboard.jsx';
import ProtectedRoute from './components/ProtectedRoute.jsx';
import { LanguageProvider } from './components/switchLanguage/languageContext.jsx';

function App() {
  return (
		<LanguageProvider>
			<BrowserRouter>
				<Routes>
					<Route path="/auth/*" element={<AuthSwitch />} />
					<Route 
						path="/dashboard" 
						element={
							<ProtectedRoute>
								<Dashboard />
							</ProtectedRoute>
						} 
					/>
					<Route path="/" element={<Navigate to="/auth" replace />} />
				</Routes>
			</BrowserRouter>
		</LanguageProvider>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
