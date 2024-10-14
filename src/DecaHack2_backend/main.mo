import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Env "env";
import Debug "mo:base/Debug";
import Char "mo:base/Char";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Time "mo:base/Time";

// Actor
actor Marketplace {

    // Admin Principal
    private let admin = Principal.fromText(Env.ADMIN);

    // Types
    type User = {
        username : Text;
        hashedPassword : Text;
        role : Role;
    };

    type Role = { #Client; #Freelancer };

    type Payment = {
        clientId : Principal;
        freelancerId : Principal;
        amount : Nat;
        var status : Status;
    };

    type Application = {
        jobId : Text;
        coverLetter : Text;
    };

    type Job = {
        title : Text;
        description : Text;
        salary : Nat;
    };

    type Status = {
        #pending;
        #released;
        #failed;
        #Open;
        #UnderReview;
        #Resolved;
        #Rejected;
    };

    type Evidence = {
        submittedBy : Principal;
        description : Text;
        fileLink : ?Text;
    };

    type Dispute = {
        clientId : Principal;
        freelancerId : Principal;
        reason : Text;
        evidence : Buffer.Buffer<Evidence>;
        status : Buffer.Buffer<Status>;
    };

    // To return immutable dispute details (convert Buffer to array)
    type ImmutableDispute = {
        clientId : Principal;
        freelancerId : Principal;
        reason : Text;
        evidence : [Evidence];
        status : [Status];
    };

    // Users
    private let users = HashMap.HashMap<Principal, User>(0, Principal.equal, Principal.hash);
    // Username to Principal map
    private let usernameMap = HashMap.HashMap<Text, Principal>(0, Text.equal, Text.hash);
    // Disputes
    private let disputes = HashMap.HashMap<Principal, Dispute>(10, Principal.equal, Principal.hash);
    // Payments
    private let payments = HashMap.HashMap<Principal, Payment>(10, Principal.equal, Principal.hash);
    // Sessions HashMap
    private let sessions = HashMap.HashMap<Principal, Time.Time>(0, Principal.equal, Principal.hash);
    // User Functions
    private stable var hashSecret : Text = Env.SECRET;

    // Check if the caller is the admin
    private func isAdmin(caller : Principal) : Bool {
        return caller == admin;
    };

    public query (msg) func isLoggedIn(userId : Principal) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        let sessionTime = sessions.get(userId);
        switch (sessionTime) {
            case null { return #ok(false) };
            case (?time) {
                let currentTime = Time.now();
                let duration = currentTime - time;
                let twoHours = 2 * 60 * 60 * 1000000000; // 2 hours in nanoseconds
                if (duration > twoHours) {
                    sessions.delete(userId);
                    return #ok(false);
                } else {
                    return #ok(true);
                };
            };
        };
    };

    public query (msg) func getUserRole(userId : Principal) : async Result.Result<?Role, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        let user = users.get(userId);
        switch (user) {
            case null { return #ok(null) };
            case (?u) { return #ok(?u.role) };
        };
    };

    private func registerUser(userId : Principal, user : User) : async Result.Result<Bool, Text> {
        if (users.get(userId) != null or usernameMap.get(user.username) != null) {
            Debug.print("User already exists");
            return #err("User already exists");
        };
        try {
            users.put(userId, user);
            usernameMap.put(user.username, userId);
            return #ok(true);
        } catch (e) {
            Debug.print("Error registering user: " # Error.message(e));
            return #err("Error registering user");
        };
    };

    private func hashPassword(password : Text) : async Result.Result<Text, Text> {
        var hashedPassword = "";
        try {
            for (characters in password.chars()) {
                hashedPassword #= debug_show (Char.toNat32(characters) * 221) # hashSecret;
            };
            return #ok(hashedPassword);
        } catch (e) {
            Debug.print("Error hashing password: " # Error.message(e));
            return #err("Hashing password failed");
        };
    };

    public shared (msg) func signup(username : Text, password : Text, role : Role) : async Result.Result<Principal, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access: kindly login" # Principal.toText(msg.caller));
        };
        let hashedPasswordResult = await hashPassword(password);
        switch (hashedPasswordResult) {
            case (#err(e)) { return #err(e) };
            case (#ok(hashedPasswordText)) {
                let newUserId = msg.caller;
                Debug.print("Using Principal: " # Principal.toText(newUserId));
                let user = {
                    username = username;
                    hashedPassword = hashedPasswordText;
                    role = role;
                };
                let registerResult = await registerUser(newUserId, user);
                switch (registerResult) {
                    case (#err(e)) { return #err(e) };
                    case (#ok(success)) {
                        if (success) {
                            return #ok(newUserId);
                        } else {
                            return #err("Signup failed");
                        };
                    };
                };
            };
        };
    };

    public shared (msg) func login(usernameOrPrincipal : Text, password : Text) : async Result.Result<?Principal, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        let hashedPasswordResult = await hashPassword(password);
        switch (hashedPasswordResult) {
            case (#err(e)) { return #err(e) };
            case (#ok(hashedPassword)) {
                // Check if login input is a username or Principal
                let maybeUserId = usernameMap.get(usernameOrPrincipal);
                let userId = switch maybeUserId {
                    case (?id) id;
                    case null {
                        // Try to parse as Principal if not found in usernameMap
                        let parsedPrincipal = Option.make(Principal.fromText(usernameOrPrincipal));
                        switch (parsedPrincipal) {
                            case (null) { return #ok(null) }; // Invalid Principal or username not found
                            case (?p) { p };
                        };
                    };
                };
                let userRoleResult = await getUserRole(userId);
                switch (userRoleResult) {
                    case (#err(e)) { return #err(e) };
                    case (#ok(userRole)) {
                        let isValidResult = await validateCredentials(userId, hashedPassword);
                        switch (isValidResult) {
                            case (#err(e)) { return #err(e) };
                            case (#ok(isValid)) {
                                if (userRole != null and isValid) {
                                    // Set session timestamp
                                    sessions.put(userId, Time.now());
                                    return #ok(?userId);
                                } else {
                                    return #ok(null);
                                };
                            };
                        };
                    };
                };
            };
        };
    };

    private func validateCredentials(userId : Principal, hashedPassword : Text) : async Result.Result<Bool, Text> {
        let user = users.get(userId);
        switch (user) {
            case null { return #ok(false) };
            case (?u) {
                return #ok(u.hashedPassword == hashedPassword);
            };
        };
    };

    public query (msg) func getUsers() : async Result.Result<[User], Text> {
        if (not isAdmin(msg.caller)) {
            Debug.print("Unauthorized access, Admin only");
            return #err("Unauthorized access, Admin only");
        };
        return #ok(Iter.toArray(users.vals()));
    };

    // logout function
    public shared (msg) func logout(userId : Principal) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        if (sessions.get(userId) != null) {
            sessions.delete(userId);
            return #ok(true);
        } else {
            return #ok(false);
        };
    };

    // Deleting users
    public shared (msg) func deleteUser(userId : Principal) : async Result.Result<Bool, Text> {
        if (not isAdmin(msg.caller)) {
            Debug.print("Unauthorized access, Admin only");
            return #err("Unauthorized access, Admin only");
        };
        let user = users.get(userId);
        switch (user) {
            case null {
                Debug.print("User not found");
                return #ok(false);
            };
            case (?u) {
                users.delete(userId);
                usernameMap.delete(u.username);
                Debug.print("User deleted successfully");
                return #ok(true);
            };
        };
    };

    // Job Functions
    private let jobs = HashMap.HashMap<Principal, Job>(10, Principal.equal, Principal.hash);

    public shared (msg) func postJob(clientId : Principal, job : Job) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        jobs.put(clientId, job);
        return #ok(true);
    };

    public query (msg) func getJob(clientId : Principal) : async Result.Result<?Job, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        return #ok(jobs.get(clientId));
    };

    public shared (msg) func deleteJob(clientId : Principal) : async Result.Result<Bool, Text> {
        if (not isAdmin(msg.caller)) {
            Debug.print("Unauthorized access, Admin only");
            return #err("Unauthorized access, Admin only");
        };
        jobs.delete(clientId);
        return #ok(true);
    };

    // Job Applications
    private let applications = HashMap.HashMap<Principal, Application>(10, Principal.equal, Principal.hash);

    public shared (msg) func applyForJob(freelancerId : Principal, application : Application) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        applications.put(freelancerId, application);
        return #ok(true);
    };

    public query (msg) func getApplications(freelancerId : Principal) : async Result.Result<?Application, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        return #ok(applications.get(freelancerId));
    };

    // Escrow Functions
    public shared (msg) func createEscrow(clientId : Principal, freelancerId : Principal, amount : Nat) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        let payment : Payment = {
            clientId = clientId;
            freelancerId = freelancerId;
            amount = amount;
            var status = #pending;
        };
        payments.put(clientId, payment);
        return #ok(true);
    };

    public shared (msg) func releasePayment(clientId : Principal) : async Result.Result<Bool, Text> {
        if (not isAdmin(msg.caller)) {
            Debug.print("Unauthorized access, Admin only");
            return #err("Unauthorized access, Admin only");
        };
        let payment = payments.get(clientId);
        switch (payment) {
            case (?p) {
                p.status := #released;
                return #ok(true);
            };
            case null {
                return #ok(false);
            };
        };
    };

    // Dispute Resolution Functions
    public shared (msg) func initiateDispute(clientId : Principal, freelancerId : Principal, reason : Text) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        if (Option.isSome(disputes.get(clientId))) {
            return #ok(false); // A dispute is already ongoing for this client
        };
        let dispute : Dispute = {
            clientId = clientId;
            freelancerId = freelancerId;
            reason = reason;
            evidence = Buffer.Buffer<Evidence>(0); // Start with an empty buffer
            status = Buffer.Buffer<Status>(1);
        };
        dispute.status.add(#Open);
        disputes.put(clientId, dispute);
        return #ok(true);
    };

    public shared (msg) func submitEvidence(clientId : Principal, submittedBy : Principal, description : Text, fileLink : ?Text) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return #ok(false) }; // No ongoing dispute for this client
            case (?d) {
                let newEvidence : Evidence = {
                    submittedBy = submittedBy;
                    description = description;
                    fileLink = fileLink;
                };
                d.evidence.add(newEvidence); // Add to buffer
                return #ok(true);
            };
        };
    };

    public shared (msg) func changeDisputeStatus(clientId : Principal, newStatus : Status) : async Result.Result<Bool, Text> {
        if (not isAdmin(msg.caller)) {
            Debug.print("Unauthorized access, Admin only");
            return #err("Unauthorized access, Admin only");
        };
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return #ok(false) }; // No ongoing dispute for this client
            case (?d) {
                d.status.clear();
                d.status.add(newStatus);
                return #ok(true);
            };
        };
    };

    public query (msg) func getDispute(clientId : Principal) : async Result.Result<?ImmutableDispute, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return #ok(null) };
            case (?d) {
                return #ok(
                    ?{
                        clientId = d.clientId;
                        freelancerId = d.freelancerId;
                        reason = d.reason;
                        evidence = Buffer.toArray(d.evidence); // Convert Buffer to Array
                        status = Buffer.toArray(d.status); // Convert Buffer to Array
                    }
                );
            };
        };
    };

    public shared (msg) func resolveDispute(clientId : Principal, decision : Status) : async Result.Result<Bool, Text> {
        if (not isAdmin(msg.caller)) {
            Debug.print("Unauthorized access, Admin only");
            return #err("Unauthorized access, Admin only");
        };
        if (decision == #Resolved or decision == #Rejected) {
            return await changeDisputeStatus(clientId, decision);
        };
        return #ok(false);
    };

    public query (msg) func getDisputeStatus(clientId : Principal) : async Result.Result<?Status, Text> {
        if (Principal.isAnonymous(msg.caller)) {
            Debug.print("Unauthorized access");
            return #err("Unauthorized access");
        };
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return #ok(null) };
            case (?d) {
                let statusArr = Buffer.toArray(d.status);
                return switch (statusArr.size()) {
                    case 0 { #ok(null) };
                    case _ { #ok(?statusArr[0]) };
                };
            };
        };
    };

    public query (msg) func listAllDisputes() : async Result.Result<[(Principal, ImmutableDispute)], Text> {
        if (not isAdmin(msg.caller)) {
            Debug.print("Unauthorized access, Admin only");
            return #err("Unauthorized access, Admin only");
        };
        return #ok(
            Array.map<(Principal, Dispute), (Principal, ImmutableDispute)>(
                Iter.toArray(disputes.entries()),
                func(entry : (Principal, Dispute)) : (Principal, ImmutableDispute) {
                    let (key, dispute) = entry;
                    return (
                        key,
                        {
                            clientId = dispute.clientId;
                            freelancerId = dispute.freelancerId;
                            reason = dispute.reason;
                            evidence = Buffer.toArray(dispute.evidence); // Convert to array
                            status = Buffer.toArray(dispute.status); // Convert to array
                        },
                    );
                },
            )
        );
    };
};
