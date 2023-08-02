export const generateRandomNumber = (
  { max }: { max: number } = { max: 10 },
): number => {
  return Math.floor(Math.random() * max) + 1;
};
