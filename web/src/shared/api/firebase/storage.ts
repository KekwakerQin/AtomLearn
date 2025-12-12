import { storage } from "./config";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";

export const firebaseStorageApi = {
  upload: async (path: string, file: File) => {
    const fileRef = ref(storage, path);
    await uploadBytes(fileRef, file);
    return getDownloadURL(fileRef);
  },
};
