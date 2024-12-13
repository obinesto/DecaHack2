import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Iter "mo:base/Iter";

actor Escrow {
    public type Payment = {
        clientId : Principal;
        freelancerId : Principal;
        amount : Nat;
        status : { #pending; #released };
    };

    private stable var paymentsEntries : [(Principal, Payment)] = [];
    private var payments = HashMap.HashMap<Principal, Payment>(10, Principal.equal, Principal.hash);

    system func preupgrade() {
        paymentsEntries := Iter.toArray(payments.entries());
    };

    system func postupgrade() {
        payments := HashMap.fromIter<Principal, Payment>(paymentsEntries.vals(), 10, Principal.equal, Principal.hash);
        paymentsEntries := [];
    };

    public shared({ caller }) func createEscrow(clientId : Principal, freelancerId : Principal, amount : Nat) : async Result.Result<Bool, Text> {
        if (Principal.isAnonymous(caller)) return #err("Unauthorized access");
        payments.put(clientId, { clientId; freelancerId; amount; status = #pending });
        #ok(true)
    };

    // Additional function to get payment details
    public query func getPayment(clientId : Principal) : async ?Payment {
        payments.get(clientId)
    };

    // Function to release payment (you might want to add more checks here)
    public shared({ caller }) func releasePayment(clientId : Principal) : async Result.Result<Bool, Text> {
        switch (payments.get(clientId)) {
            case (null) { #err("Payment not found") };
            case (?payment) {
                if (caller != payment.clientId and caller != payment.freelancerId) {
                    return #err("Unauthorized to release payment");
                };
                let updatedPayment = {
                    clientId = payment.clientId;
                    freelancerId = payment.freelancerId;
                    amount = payment.amount;
                    status = #released;
                };
                payments.put(clientId, updatedPayment);
                #ok(true)
            };
        }
    };
}