export const getRoomId = (userId1, userId2) => {
  return [userId1, userId2].sort().join("_");
};
