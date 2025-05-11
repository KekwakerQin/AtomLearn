

export function Button ({children, className, type, isDisable, clickFunction}){
	return <button 
	type={type}
	className={className}
	disabled={isDisable}
	onClick= {clickFunction}
>
	{children}
</button>
}