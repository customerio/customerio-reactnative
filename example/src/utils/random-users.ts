import 'react-native-get-random-values';
import { v4 as uuidv4 } from 'uuid';
import { User } from './data-types';

const randomUsers: User[] = [
  {
    id: uuidv4(),
    traits: {
      name: 'Alice',
      email: 'alice@cio.com',
    },
  },
  {
    id: uuidv4(),
    traits: {
      name: 'Bob',
      email: 'bob@cio.com',
    },
  },
  {
    id: uuidv4(),
    traits: {
      name: 'Charlie',
      email: 'charlie@cio.com',
    },
  },
  {
    id: uuidv4(),
    traits: {
      name: 'David',
      email: 'david@cio.com',
    },
  },
];

export const getRandomUser = () =>
  randomUsers[Math.floor(Math.random() * randomUsers.length)];
