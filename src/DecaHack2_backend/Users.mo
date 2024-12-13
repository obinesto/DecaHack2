import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Env "Env";

actor Users {
    public type Role = { #Client; #Freelancer };
    public type User = {
        username : Text;
        hashedPassword : Text;
        role : Role;
    };

    private stable var usersEntries : [(Principal, User)] = [];
    private stable var usernameMapEntries : [(Text, Principal)] = [];
    private stable var sessionsEntries : [(Principal, Time.Time)] = [];
    private stable var hashSecret : Text = Env.SECRET;

    private var users = HashMap.HashMap<Principal, User>(0, Principal.equal, Principal.hash);
    private var usernameMap = HashMap.HashMap<Text, Principal>(0, Text.equal, Text.hash);
    private var sessions = HashMap.HashMap<Principal, Time.Time>(0, Principal.equal, Principal.hash);

    system func preupgrade() {
        usersEntries := Iter.toArray(users.entries());
        usernameMapEntries := Iter.toArray(usernameMap.entries());
        sessionsEntries := Iter.toArray(sessions.entries());
    };

    system func postupgrade() {
        users := HashMap.fromIter<Principal, User>(usersEntries.vals(), 1, Principal.equal, Principal.hash);
        usernameMap := HashMap.fromIter<Text, Principal>(usernameMapEntries.vals(), 1, Text.equal, Text.hash);
        sessions := HashMap.fromIter<Principal, Time.Time>(sessionsEntries.vals(), 1, Principal.equal, Principal.hash);
        usersEntries := [];
        usernameMapEntries := [];
        sessionsEntries := [];
    };

    private func hashPassword(password : Text) : async Result.Result<Text, Text> {
        var hashedPassword = "";
        for (char in password.chars()) {
            hashedPassword #= debug_show (Char.toNat32(char) * 221) # hashSecret;
        };
        #ok(hashedPassword);
    };

    private func isSessionValid(userId : Principal) : Bool {
        switch (sessions.get(userId)) {
            case (?lastLogin) {
                let now = Time.now();
                let sessionDuration = 24 * 60 * 60 * 1000000000; // 24 hours in nanoseconds
                now - lastLogin < sessionDuration;
            };
            case null false;
        };
    };

    public shared ({ caller }) func signup(username : Text, password : Text, role : Role) : async Result.Result<Principal, Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");
        if (username.size() < 3) return #err("Username must be at least 3 characters long");
        if (password.size() < 8) return #err("Password must be at least 8 characters long");

        let hashedPassword = await hashPassword(password);
        switch (hashedPassword) {
            case (#ok(hashed)) {
                if (users.get(caller) != null) return #err("User with this principal already exists");
                if (usernameMap.get(username) != null) return #err("Username already taken");

                users.put(caller, { username; hashedPassword = hashed; role });
                usernameMap.put(username, caller);
                #ok(caller);
            };
            case (#err(e)) #err(e);
        };
    };

    public shared ({ caller }) func login(usernameOrPrincipal : Text, password : Text) : async Result.Result<Principal, Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");
        let hashedPassword = await hashPassword(password);
        switch (hashedPassword) {
            case (#ok(hashed)) {
                let userId = switch (usernameMap.get(usernameOrPrincipal)) {
                    case (?id) id;
                    case null Principal.fromText(usernameOrPrincipal);
                };
                switch (users.get(userId)) {
                    case (?user) {
                        if (user.hashedPassword == hashed) {
                            sessions.put(userId, Time.now());
                            #ok(userId);
                        } else #err("Invalid password");
                    };
                    case null #err("User not found");
                };
            };
            case (#err(e)) #err(e);
        };
    };

    public shared query func isLoggedIn(userId : Principal) : async Bool {
        if (Principal.isAnonymous(userId)) {
            false;
        } else {
            isSessionValid(userId);
        };
    };

    public shared query func getUsers() : async [User] {
        Iter.toArray(users.vals());
    };

    public shared ({ caller }) func deleteUser(userId : Principal) : async Result.Result<(), Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");
        if (not isSessionValid(caller)) return #err("User not logged in");

        switch (users.get(userId)) {
            case (?user) {
                users.delete(userId);
                usernameMap.delete(user.username);
                sessions.delete(userId);
                #ok();
            };
            case null #err("User not found");
        };
    };

    public shared ({ caller }) func updateUser(userId : Principal, newUsername : ?Text, newPassword : ?Text, newRole : ?Role) : async Result.Result<(), Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");
        if (not isSessionValid(caller)) return #err("User not logged in");
        if (caller != userId) return #err("You can only update your own profile");

        switch (users.get(userId)) {
            case (?user) {
                var updatedUser = user;

                switch (newUsername) {
                    case (?username) {
                        if (username.size() < 3) return #err("Username must be at least 3 characters long");
                        if (usernameMap.get(username) != null) return #err("Username already taken");
                        usernameMap.delete(user.username);
                        usernameMap.put(username, userId);
                        updatedUser := { updatedUser with username = username };
                    };
                    case null {};
                };

                switch (newPassword) {
                    case (?password) {
                        if (password.size() < 8) return #err("Password must be at least 8 characters long");
                        let hashedPassword = await hashPassword(password);
                        switch (hashedPassword) {
                            case (#ok(hashed)) {
                                updatedUser := {
                                    updatedUser with hashedPassword = hashed
                                };
                            };
                            case (#err(e)) return #err(e);
                        };
                    };
                    case null {};
                };

                switch (newRole) {
                    case (?role) {
                        updatedUser := { updatedUser with role = role };
                    };
                    case null {};
                };

                users.put(userId, updatedUser);
                #ok();
            };
            case null #err("User not found");
        };
    };

    public shared ({ caller }) func logout() : async Result.Result<(), Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");

        switch (sessions.get(caller)) {
            case (?_) {
                sessions.delete(caller);
                #ok();
            };
            case null #err("User not logged in");
        };
    };
};
