import {
  getBoardsByCollaborator,
  getBoardsByOwner,
  type Board,
} from "@entities";

export const getUserBoards = async (uid: string) => {
  const [owned, collaborated] = await Promise.all([
    getBoardsByOwner(uid),
    getBoardsByCollaborator(uid),
  ]);

  const map = new Map<string, Board>();

  [...owned, ...collaborated].forEach((board) => {
    map.set(board.id, board);
  });

  return Array.from(map.values());
};
