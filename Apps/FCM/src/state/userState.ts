import { Context, createContext, useContext } from 'react';
import User from '../data/models/user';

interface UserState {
  user?: User;
  onUserStateChanged: (user?: User) => Promise<void>;
}

export const UserStateContextEmpty: UserState = {
  user: undefined,
  onUserStateChanged: async () => {},
};

export const UserStateContext: Context<UserState> = createContext(
  UserStateContextEmpty,
);

export function useUserStateContext(): UserState {
  return useContext(UserStateContext);
}
