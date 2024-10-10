import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Sha256 "mo:sha2/Sha256";

// Actor
actor Marketplace {

    // Types
    type User = {
        username : Text;
        hashedPassword : [Nat8];
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

    // User Functions
    private stable var hashSecret : Text = "";

    private func init(secret : Text) {
        hashSecret := secret; // This Initializes hashSecret from passed argument
    };

    public query func isLoggedIn(userId : Principal) : async Bool {
        return users.get(userId) != null;
    };

    public query func getUserRole(userId : Principal) : async ?Role {
        let user = users.get(userId);
        switch (user) {
            case null { return null };
            case (?u) { return ?u.role };
        };
    };

    private func registerUser(userId : Principal, user : User) : async Bool {
        if (users.get(userId) != null or usernameMap.get(user.username) != null) {
            Debug.print("User already exists");
            return false; // Either userId or username already exists
        };
        try {
            users.put(userId, user);
            usernameMap.put(user.username, userId);
            return true;
        } catch (e) {
            Debug.print("Error registering user: " # Error.message(e));
            return false;
        };
    };

    private func hashPassword(password : Text) : async Text {
        init(hashSecret);
        let hashedSecret = hashSecret;
        var hashedPassword = "";
        try {
            for (characters in password.chars()) {
                hashedPassword #= debug_show (Char.toNat32(characters) * 221) # hashedSecret;
            };
            return hashedPassword;
        } catch (e) {
            Debug.print("Error hashing password: " # Error.message(e));
            throw Error.reject("Hashing password failed");
        };
    };

    private func generatePrincipalFromUsername(username : Text) : async Principal {
        try {
            let hash = Sha256.fromBlob(#sha256, Text.encodeUtf8(username));
            // Truncating the hash to 28 bytes (224 bits) to fit the Principal size limit
            let truncatedHash = Array.subArray(Blob.toArray(hash), 0, 28);
            return Principal.fromBlob(Blob.fromArray(truncatedHash));
        } catch (e) {
            Debug.print("Error generating principal from username: " # Error.message(e));
            throw Error.reject("Generating principal failed");
        };
    };

    public func signup(username : Text, password : Text, role : Role) : async Principal {
        let hashedPasswordText = await hashPassword(password);

        // Generating user ID from username
        let newUserId = await generatePrincipalFromUsername(username);
        Debug.print("Generated Principal: " # Principal.toText(newUserId));

        let user = {
            username = username;
            hashedPassword = Iter.toArray(Text.encodeUtf8(hashedPasswordText).vals());
            role = role;
        };

        let success = await registerUser(newUserId, user);
        if (success) {
            return newUserId;
        } else {
            throw Error.reject("Signup failed");
        };
    };

    public func login(usernameOrPrincipal : Text, password : Text) : async ?Principal {
        let hashedPassword = await hashPassword(password);

        // Check if login input is a username or Principal
        let maybeUserId = usernameMap.get(usernameOrPrincipal);
        let userId = switch maybeUserId {
            case (?id) id;
            case null {
                // Try to parse as Principal if not found in usernameMap
                let parsedPrincipal = Option.make(Principal.fromText(usernameOrPrincipal));
                switch (parsedPrincipal) {
                    case (null) { return null }; // Invalid Principal or username not found
                    case (?p) { p };
                };
            };
        };

        let userRole = await getUserRole(userId);
        let isValid = await validateCredentials(userId, hashedPassword);
        if (userRole != null and isValid) {
            return ?userId;
        } else {
            return null;
        };
    };

    private func validateCredentials(userId : Principal, hashedPassword : Text) : async Bool {
        let user = users.get(userId);
        switch (user) {
            case null { return false };
            case (?u) {
                return u.hashedPassword == Iter.toArray(Text.encodeUtf8(hashedPassword).vals());
            };
        };
    };

    public query func getUsers() : async [User] {
        return Iter.toArray(users.vals());
    };

    // Deleting users
    public func deleteUser(userId : Principal) : async Bool {
        let user = users.get(userId);
        switch (user) {
            case null {
                Debug.print("User not found");
                return false;
            };
            case (?u) {
                users.delete(userId);
                usernameMap.delete(u.username);
                Debug.print("User deleted successfully");
                return true;
            };
        };
    };

    // Job Functions
    private let jobs = HashMap.HashMap<Principal, Job>(10, Principal.equal, Principal.hash);

    public func postJob(clientId : Principal, job : Job) : async Bool {
        jobs.put(clientId, job);
        return true;
    };

    public query func getJob(clientId : Principal) : async ?Job {
        return jobs.get(clientId);
    };

    public func deleteJob(clientId : Principal) : async Bool {
        jobs.delete(clientId);
        return true;
    };

    // Job Applications
    private let applications = HashMap.HashMap<Principal, Application>(10, Principal.equal, Principal.hash);

    public func applyForJob(freelancerId : Principal, application : Application) : async Bool {
        applications.put(freelancerId, application);
        return true;
    };

    public query func getApplications(freelancerId : Principal) : async ?Application {
        return applications.get(freelancerId);
    };

    // Escrow Functions
    public func createEscrow(clientId : Principal, freelancerId : Principal, amount : Nat) : async Bool {
        let payment : Payment = {
            clientId = clientId;
            freelancerId = freelancerId;
            amount = amount;
            var status = #pending;
        };
        payments.put(clientId, payment);
        return true;
    };

    public func releasePayment(clientId : Principal) : async Bool {
        let payment = payments.get(clientId);
        switch (payment) {
            case (?p) {
                p.status := #released;
                return true;
            };
            case null {
                return false;
            };
        };
    };

    // Dispute Resolution Functions
    public func initiateDispute(clientId : Principal, freelancerId : Principal, reason : Text) : async Bool {
        if (Option.isSome(disputes.get(clientId))) {
            return false; // A dispute is already ongoing for this client
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
        return true;
    };

    public func submitEvidence(clientId : Principal, submittedBy : Principal, description : Text, fileLink : ?Text) : async Bool {
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return false }; // No ongoing dispute for this client
            case (?d) {
                let newEvidence : Evidence = {
                    submittedBy = submittedBy;
                    description = description;
                    fileLink = fileLink;
                };

                d.evidence.add(newEvidence); // Add to buffer
                return true;
            };
        };
    };

    public func changeDisputeStatus(clientId : Principal, newStatus : Status) : async Bool {
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return false }; // No ongoing dispute for this client
            case (?d) {
                d.status.clear();
                d.status.add(newStatus);
                return true;
            };
        };
    };

    public query func getDispute(clientId : Principal) : async ?ImmutableDispute {
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return null };
            case (?d) {
                return ?{
                    clientId = d.clientId;
                    freelancerId = d.freelancerId;
                    reason = d.reason;
                    evidence = Buffer.toArray(d.evidence); // Convert Buffer to Array
                    status = Buffer.toArray(d.status); // Convert Buffer to Array
                };
            };
        };
    };

    public func resolveDispute(clientId : Principal, decision : Status) : async Bool {
        if (decision == #Resolved or decision == #Rejected) {
            return await changeDisputeStatus(clientId, decision);
        };
        return false;
    };

    public query func getDisputeStatus(clientId : Principal) : async ?Status {
        let dispute = disputes.get(clientId);
        switch (dispute) {
            case null { return null };
            case (?d) {
                let statusArr = Buffer.toArray(d.status);
                return switch (statusArr.size()) {
                    case 0 { null };
                    case _ { ?statusArr[0] };
                };
            };
        };
    };

    public query func listAllDisputes() : async [(Principal, ImmutableDispute)] {
        return Array.map<(Principal, Dispute), (Principal, ImmutableDispute)>(
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
        );
    };
};
