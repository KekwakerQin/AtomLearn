import { useNavigate } from "react-router-dom";

import { signInWithGoogle } from "@features";

export function GoogleLoginButton() {
  const navigate = useNavigate();

  const handleClick = async () => {
    const res = await signInWithGoogle();

    if (res.ok) {
      navigate("/");
    } else {
      alert(res.message);
    }
  };

  return <button onClick={handleClick}>Войти через Google</button>;
}
