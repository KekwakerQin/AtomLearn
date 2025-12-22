import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";

import { useUserById, ProfileView } from "@pages";

import { selectUser, selectUserInitialized } from "@entities";

export const ProfilePage = () => {
  const { profileId } = useParams<{ profileId?: string }>();

  const currentUser = useSelector(selectUser);
  const authReady = useSelector(selectUserInitialized);

  const isOwnProfile =
    !!currentUser && (!profileId || profileId === currentUser.uid);

  const shouldFetch = !!profileId && !isOwnProfile;

  const { data: fetchedUser, loading } = useUserById(
    shouldFetch ? profileId : undefined
  );

  if (!authReady) {
    return <div>Загрузка сессии...</div>;
  }

  if (shouldFetch && loading) {
    return <div>Загрузка профиля...</div>;
  }

  if (shouldFetch && !loading && !fetchedUser) {
    return <div>Пользователь не найден</div>;
  }

  const profileUser = isOwnProfile ? currentUser : fetchedUser;

  if (!profileUser) {
    return <div>Пользователь не найден</div>;
  }

  return <ProfileView user={profileUser} isOwn={isOwnProfile} />;
};
