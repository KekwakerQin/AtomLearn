import { ref, uploadBytes, getDownloadURL } from "firebase/storage";

import { storage } from "@shared";

export const firebaseStorageApi = {
  upload: async (path: string, file: File) => {
    const fileRef = ref(storage, path);
    await uploadBytes(fileRef, file);
    return getDownloadURL(fileRef);
  },
};
