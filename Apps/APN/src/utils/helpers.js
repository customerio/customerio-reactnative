export const generateRandomNumber = ({ max } = { max: 10 }) => {
  return Math.floor(Math.random() * max) + 1;
};
