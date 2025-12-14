import { useSelector } from "react-redux";

import type { RootState } from "@app";

export const ProfilePage = () => {
  const { data: user, loading } = useSelector((state: RootState) => state.user);

  if (loading) return <div>Загрузка...</div>;
  if (!user) return <div>Нет данных</div>;

  return (
    <div>
      <h1>{user.displayName}</h1>
      <p>Email: {user.email}</p>
    </div>
  );
};
