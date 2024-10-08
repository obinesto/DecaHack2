import TrieMap "mo:base/TrieMap";

actor User{
type User = {
    username: Text;
    skills: [Text];
    rating: ?Float;
    wallet: Text;
    bio: Text;
};

stable var users : TrieMap.TrieMap<Text, User> = TrieMap.empty();

public func registerUser(userId: Text, username: Text, skills: [Text], wallet: Text, bio: Text): async Text {
    let newUser : User = { username; skills; rating = null; wallet; bio };
    users.put(userId, newUser);
    return "User registered successfully!";
};

public func getUser(userId: Text): async ?User {
    return users.get(userId);
};
}