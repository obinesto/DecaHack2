import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Iter "mo:base/Iter";

actor Jobs {
    public type Job = { title : Text; description : Text; salary : Nat };
    public type Application = { jobId : Text; coverLetter : Text };

    private stable var jobsEntries : [(Principal, Job)] = [];
    private stable var applicationsEntries : [(Principal, Application)] = [];

    private var jobs = HashMap.HashMap<Principal, Job>(10, Principal.equal, Principal.hash);
    private var applications = HashMap.HashMap<Principal, Application>(10, Principal.equal, Principal.hash);

    system func preupgrade() {
        jobsEntries := Iter.toArray(jobs.entries());
        applicationsEntries := Iter.toArray(applications.entries());
    };

    system func postupgrade() {
        jobs := HashMap.fromIter<Principal, Job>(jobsEntries.vals(), 10, Principal.equal, Principal.hash);
        applications := HashMap.fromIter<Principal, Application>(applicationsEntries.vals(), 10, Principal.equal, Principal.hash);
        jobsEntries := [];
        applicationsEntries := [];
    };

    public shared({ caller }) func postJob(clientId : Principal, job : Job) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");
        jobs.put(clientId, job);
        #ok(true)
    };

    public shared({ caller }) func applyForJob(freelancerId : Principal, application : Application) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");
        applications.put(freelancerId, application);
        #ok(true)
    };

    public query func getJob(clientId : Principal) : async ?Job {
        jobs.get(clientId)
    };

    public query func getApplication(freelancerId : Principal) : async ?Application {
        applications.get(freelancerId)
    };
}