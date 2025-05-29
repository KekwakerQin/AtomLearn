import './UIButtonStyles.css'

export function Button ({children, className, type, isDisable, onClick}){
	return <button 
	type={type}
	className={className}
	disabled={isDisable}
	onClick= {onClick}
>
	{children}
</button>
}