import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Env "Env";

actor Marketplace {
    private let admin = Principal.fromText(Env.ADMIN);

    public query ({ caller : Principal }) func getCaller() : async Principal {
        return caller;
    };

    // Actor references
    private let usersCanister : actor {
        signup : (username : Text, password : Text, role : { #Client; #Freelancer }) -> async Result.Result<Principal, Text>;
        login : (usernameOrPrincipal : Text, password : Text) -> async Result.Result<Principal, Text>;
        isLoggedIn : (userId : Principal) -> async Bool;
        getUsers : () -> async [(Principal, { username : Text; role : { #Client; #Freelancer } })];
        deleteUser : (userId : Principal) -> async Result.Result<(), Text>;
        updateUser : (userId : Principal, newUsername : ?Text, newPassword : ?Text, newRole : ?{ #Client; #Freelancer }) -> async Result.Result<(), Text>;
        logout : () -> async Result.Result<(), Text>;
    } = actor (Env.USERS_CANISTER_ID);

    private let jobsCanister : actor {
        postJob : (clientId : Principal, job : { title : Text; description : Text; salary : Nat }) -> async Result.Result<Bool, Text>;
        applyForJob : (freelancerId : Principal, application : { jobId : Text; coverLetter : Text }) -> async Result.Result<Bool, Text>;
        getJob : (clientId : Principal) -> async ?{
            title : Text;
            description : Text;
            salary : Nat;
        };
        getApplication : (freelancerId : Principal) -> async ?{
            jobId : Text;
            coverLetter : Text;
        };
    } = actor (Env.JOBS_CANISTER_ID);

    private let escrowCanister : actor {
        createEscrow : (clientId : Principal, freelancerId : Principal, amount : Nat) -> async Result.Result<Bool, Text>;
        getPayment : (clientId : Principal) -> async ?{
            clientId : Principal;
            freelancerId : Principal;
            amount : Nat;
            status : { #pending; #released };
        };
        releasePayment : (clientId : Principal) -> async Result.Result<Bool, Text>;
    } = actor (Env.ESCROW_CANISTER_ID);

    // Helper function to check if the caller is admin
    private func isAdmin(caller : Principal) : Bool {
        Principal.equal(caller, admin);
    };

    // Delegates to Users canister
    public shared func signup(username : Text, password : Text, role : { #Client; #Freelancer }) : async Result.Result<Principal, Text> {
        await usersCanister.signup(username, password, role);
    };

    public shared func login(usernameOrPrincipal : Text, password : Text) : async Result.Result<Principal, Text> {
        await usersCanister.login(usernameOrPrincipal, password);
    };

    public shared func isLoggedIn(userId : Principal) : async Bool {
        await usersCanister.isLoggedIn(userId);
    };

    public shared({caller}) func getUsers() : async Result.Result<[(Principal, { username : Text; role : { #Client; #Freelancer } })], Text> {
        if (not isAdmin(caller)) {
            return #err("Access denied. Only admin can get users.");
        };
        try {
            let users = await usersCanister.getUsers();
            #ok(users);
        } catch (error) {
            #err("Error fetching users: " # Error.message(error));
        };
    };

    public shared func deleteUser(userId : Principal) : async Result.Result<(), Text> {
        await usersCanister.deleteUser(userId);
    };

    public shared func updateUser(userId : Principal, newUsername : ?Text, newPassword : ?Text, newRole : ?{ #Client; #Freelancer }) : async Result.Result<(), Text> {
        await usersCanister.updateUser(userId, newUsername, newPassword, newRole);
    };

    public shared func logout() : async Result.Result<(), Text> {
        await usersCanister.logout();
    };

    // Delegates to Jobs canister
    public shared ({ caller }) func postJob(clientId : Principal, job : { title : Text; description : Text; salary : Nat }) : async Result.Result<Bool, Text> {
        if (not isAdmin(caller) and not Principal.equal(caller, clientId)) {
            return #err("Access denied. Only admin or the client can post a job.");
        };
        await jobsCanister.postJob(clientId, job);
    };

    public shared ({ caller }) func applyForJob(freelancerId : Principal, application : { jobId : Text; coverLetter : Text }) : async Result.Result<Bool, Text> {
        if (not Principal.equal(caller, freelancerId)) {
            return #err("Access denied. Only the freelancer can apply for a job.");
        };
        await jobsCanister.applyForJob(freelancerId, application);
    };

    // Delegates to Escrow canister
    public shared ({ caller }) func createEscrow(clientId : Principal, freelancerId : Principal, amount : Nat) : async Result.Result<Bool, Text> {
        if (not isAdmin(caller) and not Principal.equal(caller, clientId)) {
            return #err("Access denied. Only admin or the client can create an escrow.");
        };
        await escrowCanister.createEscrow(clientId, freelancerId, amount);
    };
};
