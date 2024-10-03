import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Hash "mo:base/Hash";

actor UserDatabase {
  type User = {
    username: Text;
    email: Text;
    password: Text; // Note: Password is stored in plain text (NOT SECURE)
  };

  // Initialize an empty HashMap to store users
  stable var users: HashMap.HashMap<Text, User> = HashMap.HashMap<Text, User>(0, Text.equal, Text.hash);

  // Function to add a user with basic email validation
  public func addUser(username: Text, email: Text, password: Text): async Bool {
    if (await validateEmail(email)) {
      // **Important:** Currently, passwords are stored in plain text. This is insecure!

      // Create a new user record
      let user: User = { username; email; password };

      // Add the user to the HashMap
      users.put(username, user);
      return true;
    } else {
      return false; // Invalid email format
    }
  };

  // Improved email validation using a regular expression
  public func validateEmail(email: Text): async Bool {
    let emailRegex = Text.fromUtf8("^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$");
    return Text.match(email, emailRegex);
  }
}