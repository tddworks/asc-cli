import { User } from '../User.ts';

export function mockUsers(): User[] {
  return [
    new User('u-1', 'John', 'Doe', 'john@example.com', ['ADMIN', 'APP_MANAGER'], true, true, {}),
    new User('u-2', 'Jane', 'Smith', 'jane@example.com', ['DEVELOPER'], false, true, {}),
    new User('u-3', 'Bob', 'Wilson', 'bob@example.com', ['MARKETING'], false, false, {}),
  ];
}
