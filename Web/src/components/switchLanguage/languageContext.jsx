import React, {createContext, useContext, useState} from 'react'

const LanguageContext = createContext();

export const LanguageProvider = ({children}) => {
	const [language, setLanguage] = useState(localStorage.getItem('appLanguage') || 'en') // язык по умолчанию 'ru' 

	const toggleLanguage = () => {
		const newLanguage = language === 'ru' ? 'en' : 'ru';
		setLanguage(newLanguage);
		localStorage.setItem('appLanguage', newLanguage);
		console.log(newLanguage)
	}
	return (
		<LanguageContext.Provider value={{language, toggleLanguage}}>
			{children}
		</LanguageContext.Provider>
	)
}

export const useLanguage = () => useContext(LanguageContext);