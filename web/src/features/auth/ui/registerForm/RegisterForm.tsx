import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { registerUser, GoogleLoginButton } from "@features";

export const RegisterForm = () => {
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [displayName, setDisplayName] = useState("");

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [error, setError] = useState<string | undefined>();

  async function handleRegister(e: React.FormEvent) {
    e.preventDefault();
    setError(undefined);

    const res = await registerUser({
      email,
      password,
      name,
      displayName,
    });

    if (!res.ok) {
      setError(res.error);
      return;
    }

    navigate("/profile");
  }

  return (
    <>
      <form onSubmit={handleRegister}>
        <input
          type="text"
          placeholder="фио"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
        />

        <input
          type="email"
          placeholder="емеил"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />

        <input
          type="text"
          placeholder="дисплей нейм"
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          required
        />

        <input
          type="password"
          placeholder="пароль"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />

        <button type="submit">зарегистрироваться</button>

        {error && <div style={{ color: "red" }}>{error}</div>}
      </form>
      <GoogleLoginButton />
    </>
  );
};
