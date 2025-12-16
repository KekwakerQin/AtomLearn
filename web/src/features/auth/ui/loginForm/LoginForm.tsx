import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { loginUser, GoogleLoginButton } from "@features";

export const LoginForm = () => {
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | undefined>();

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError(undefined);

    const res = await loginUser(email, password);

    if (!res.ok) {
      setError(res.error);
      return;
    }

    navigate("/profile");
  }

  return (
    <>
      <form onSubmit={handleLogin}>
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />

        <input
          type="password"
          placeholder="Пароль"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />

        <button type="submit">Войти</button>

        {error && <div style={{ color: "red" }}>{error}</div>}
      </form>
      <GoogleLoginButton />
    </>
  );
};
