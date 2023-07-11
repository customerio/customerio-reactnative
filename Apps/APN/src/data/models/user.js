export default class User {
  constructor(email, { name, isGuest } = { name: '', isGuest: false }) {
    this.email = email;
    this.name = name;
    this.isGuest = isGuest;
  }
}
