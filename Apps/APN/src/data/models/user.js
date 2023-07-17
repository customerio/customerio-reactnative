export default class User {
  constructor(email, { name } = { name: '' }) {
    this.email = email;
    this.name = name;
  }
}
