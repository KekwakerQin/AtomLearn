import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../UI/UIButton';
import './boards.css';
import {translation} from '../switchLanguage/locales'
import { useLanguage } from '../switchLanguage/languageContext';

export const Boards = () => {
  const navigate = useNavigate();
  const [userEmail, setUserEmail] = useState('');
	const {language, toggleLanguage} = useLanguage();
	const text = translation[language];

	function random() {
  return Math.floor(Math.random() * 1000);
}

	function NewBoard () {
		return (
									<div className="board">
							<div className="board-name-container">
								<img src="../../images/default-user-img.png" alt="default-user-img" className="default-user-img" />
								<span className="board-name">board1</span>
							</div>
							<span className="board-process">{random()}</span>
							<span className="board-learn">{random()}</span>
							<span className="board-all">{random()}</span>
						</div>
		)
	}

	return(
		<div className="boards">
			<header className="boards-header">
				<div className="logo-container">
					<span className="logo-text">
						{text.mainPage.mainPageLogo}
					</span>
				</div>
				<Button className = 'language-switch-button standart-button' type="submit" onClick={toggleLanguage}>
					{language === 'ru'? 'ENG' : 'RU'}
				</Button>
			</header>
			<section className="boards-container">
				<div className="boards-list-container">
					<div className="boards-filter">
						<span className="boards-filter-my-boards">{text.boards.boardsFilterName}</span>
						<span className="boards-filter-filter">{text.boards.boardsFilter}</span>
						<span className="boards-filter-process">{text.boards.boardsFilterProcess}</span>
						<span className="boards-filter-learn">{text.boards.boardsFilterLearn}</span>
						<span className="boards-filter-all">{text.boards.boardsFilterAll}</span>
					</div>
					<div className="boards-list">
						<NewBoard></NewBoard>
						<NewBoard></NewBoard>
						<NewBoard></NewBoard>
						<NewBoard></NewBoard>
						<NewBoard></NewBoard>
					</div>
				</div>
				<Button className="create-board-button standart-button" type="button">
					{text.boards.boardsCreateButton}
				</Button>
			</section>
			<footer className="footer">
				<div className="footer-navbar-container">
					<Button className = 'footer-button boards-button' type="button" onClick={toggleLanguage}>
					<svg width="39" height="45" viewBox="0 0 39 45" fill="none" xmlns="http://www.w3.org/2000/svg">
						<path d="M12.7656 12.8984C10.4609 12.8984 9.36719 11.8438 9.36719 9.59766V4.07031C9.36719 1.82422 10.4609 0.769531 12.7656 0.769531H26.0078C28.293 0.769531 29.4062 1.82422 29.4062 4.07031V9.59766C29.4062 11.8438 28.293 12.8984 26.0078 12.8984H12.7656ZM7.12109 44.0117C6.04688 44.0117 5.59766 43.3867 5.59766 42.5859C5.59766 42.332 5.63672 42.1562 5.69531 41.9609L8.80078 30.2617H7.58984C5.01172 30.2617 3.42969 28.7383 3.42969 26.1602V18.8359H2.12109C1.125 18.8359 0.480469 18.25 0.480469 17.332C0.480469 16.4141 1.08594 15.8086 2.02344 15.8086H36.3984C37.3945 15.8086 38.0391 16.3945 38.0391 17.332C38.0391 18.25 37.375 18.8359 36.3203 18.8359H29.2891V20.2812C29.2891 22.5078 28.1953 23.543 25.9297 23.543H12.8438C10.5586 23.543 9.46484 22.5078 9.46484 20.2812V18.8359H6.45703V24.1875C6.45703 25.5938 7.29688 26.3555 8.76172 26.3555H31.0664C32.3359 26.3555 33.1953 27.1367 33.1953 28.3477C33.1953 29.4609 32.2383 30.2617 30.9688 30.2617H29.8359L32.9609 41.9609C33.0195 42.1758 33.0391 42.3711 33.0391 42.5664C33.0391 43.4258 32.5312 44.0117 31.5156 44.0117C30.6758 44.0117 30.2461 43.5039 30.0117 42.6641L28.3711 36.4531H10.2656L8.625 42.6641C8.41016 43.5039 8.03906 44.0117 7.12109 44.0117ZM11.0859 33.4062H27.5508L26.7305 30.2617H11.9062L11.0859 33.4062Z" fill="black"/>
					</svg>
				</Button>
				<Button className = 'footer-button friends-button' type="button" onClick={toggleLanguage}>
					<svg width="36" height="38" viewBox="0 0 36 38" fill="none" xmlns="http://www.w3.org/2000/svg">
						<path d="M18.3438 19.0938C13.5 19.0938 9.61328 14.8945 9.61328 9.66016C9.61328 4.5625 13.5391 0.382812 18.3438 0.382812C23.168 0.382812 27.0938 4.52344 27.0938 9.64062C27.0938 14.875 23.1875 19.0938 18.3438 19.0938ZM18.3438 14.9727C20.8047 14.9727 22.8359 12.7461 22.8359 9.64062C22.8359 6.67188 20.8047 4.52344 18.3438 4.52344C15.9219 4.52344 13.8516 6.69141 13.8516 9.66016C13.8516 12.7656 15.9023 14.9727 18.3438 14.9727ZM6.33203 37.4141C2.75781 37.4141 0.980469 36.2031 0.980469 33.6445C0.980469 27.9219 8.05078 21.125 18.3438 21.125C28.6172 21.125 35.707 27.9219 35.707 33.6445C35.707 36.2031 33.9297 37.4141 30.3555 37.4141H6.33203ZM6.17578 33.2734H30.4922C30.8828 33.2734 31 33.1172 31 32.8438C31 30.2266 26.3906 25.2656 18.3438 25.2656C10.2969 25.2656 5.6875 30.2266 5.6875 32.8438C5.6875 33.1172 5.80469 33.2734 6.17578 33.2734Z" fill="black"/>
					</svg>
				</Button>
				<Button className = 'footer-button dashboard-button' type="button" onClick={toggleLanguage}>
					<svg width="41" height="28" viewBox="0 0 41 28" fill="none" xmlns="http://www.w3.org/2000/svg">
						<path d="M2.91406 4.05469C1.83984 4.05469 0.980469 3.17578 0.980469 2.12109C0.980469 1.02734 1.83984 0.167969 2.91406 0.167969H6.25391C7.32812 0.167969 8.20703 1.02734 8.20703 2.12109C8.20703 3.17578 7.32812 4.05469 6.25391 4.05469H2.91406ZM14.0273 3.68359C13.1289 3.68359 12.4453 3 12.4453 2.12109C12.4453 1.22266 13.1289 0.539062 14.0273 0.539062H38.7344C39.6133 0.539062 40.3359 1.22266 40.3359 2.12109C40.3359 3 39.6133 3.68359 38.7344 3.68359H14.0273ZM2.91406 15.8711C1.83984 15.8711 0.980469 14.9922 0.980469 13.918C0.980469 12.8438 1.83984 11.9844 2.91406 11.9844H6.25391C7.32812 11.9844 8.20703 12.8438 8.20703 13.918C8.20703 14.9922 7.32812 15.8711 6.25391 15.8711H2.91406ZM14.0273 15.5C13.1289 15.5 12.4453 14.7969 12.4453 13.918C12.4453 13.0391 13.1289 12.3555 14.0273 12.3555H38.7344C39.6133 12.3555 40.3359 13.0391 40.3359 13.918C40.3359 14.7969 39.6133 15.5 38.7344 15.5H14.0273ZM2.91406 27.668C1.83984 27.668 0.980469 26.7891 0.980469 25.7344C0.980469 24.6406 1.83984 23.7812 2.91406 23.7812H6.25391C7.32812 23.7812 8.20703 24.6406 8.20703 25.7344C8.20703 26.7891 7.32812 27.668 6.25391 27.668H2.91406ZM14.0273 27.2969C13.1289 27.2969 12.4453 26.6133 12.4453 25.7344C12.4453 24.8359 13.1289 24.1523 14.0273 24.1523H38.7344C39.6133 24.1523 40.3359 24.8359 40.3359 25.7344C40.3359 26.6133 39.6133 27.2969 38.7344 27.2969H14.0273Z" fill="black"/>
					</svg>
				</Button>
				</div>
			</footer>
		</div>
	)
}