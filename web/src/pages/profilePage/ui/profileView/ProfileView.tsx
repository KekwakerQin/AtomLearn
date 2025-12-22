import type { User } from "@entities";

interface ProfileViewProps {
  user: User;
  isOwn: boolean;
}

export const ProfileView = ({ user, isOwn }: ProfileViewProps) => {
  return (
    <div>
      <h1>{isOwn ? "Мой профиль" : `Профиль ${user.displayName}`}</h1>

      <img
        src={user.avatarURL ?? "/avatar-placeholder.png"}
        alt="avatar"
        width={120}
      />

      <p>
        <b>Username:</b> {user.username}
      </p>
      <p>
        <b>Email:</b> {user.email ?? "—"}
      </p>
      <p>
        <b>Роль:</b> {user.roles.join(", ")}
      </p>

      <p>
        <b>XP:</b> {user.gamification.xp}
      </p>
      <p>
        <b>Level:</b> {user.gamification.level}
      </p>

      {isOwn && (
        <>
          <hr />
          <button>Редактировать профиль</button>
          <button>Настройки</button>
        </>
      )}
    </div>
  );
};
