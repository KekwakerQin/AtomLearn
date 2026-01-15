import { registerUser } from "@features";
import { useState } from "react";

export const App = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | undefined>("");

  async function handleRegister(e: React.FormEvent) {
    e.preventDefault();
    const res = await registerUser(email, password);

    if (!res.ok) {
      setError(res.error);
    } else {
      console.log("Регистрация прошла успешно:", res.user);
    }
  }
  return (
    <form onSubmit={handleRegister}>
      <input
        type="email"
        placeholder="Email"
        onChange={(e) => setEmail(e.target.value)}
      />

      <input
        type="password"
        placeholder="Пароль"
        onChange={(e) => setPassword(e.target.value)}
      />

      <button type="submit">Зарегистрироваться</button>

      {error && <div style={{ color: "red" }}>{error}</div>}
    </form>
  );
};
