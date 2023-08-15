export default class User {
  email: string;
  name: string;

  constructor(email: string, { name }: { name?: string } = {}) {
    this.email = email;
    this.name = name ?? '';
  }
}
