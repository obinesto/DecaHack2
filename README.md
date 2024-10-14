# `DecaHack2`

Welcome to your new `DecaHack2` project and to the Internet Computer development community. By default, creating a new project adds this README and some template files to your project directory. You can edit these template files to customize your project and to include your own code to speed up the development cycle.

To get started, you might want to explore the project directory structure and the default configuration file. Working with this project in your development environment will not affect any production deployment or identity tokens.

To learn more before you start working with `DecaHack2`, see the following documentation available online:

- [Quick Start](https://internetcomputer.org/docs/current/developer-docs/setup/deploy-locally)
- [SDK Developer Tools](https://internetcomputer.org/docs/current/developer-docs/setup/install)
- [Motoko Programming Language Guide](https://internetcomputer.org/docs/current/motoko/main/motoko)
- [Motoko Language Quick Reference](https://internetcomputer.org/docs/current/motoko/main/language-manual)

If you want to start working on your project right away, you might want to try the following commands:

```bash
cd DecaHack2/
dfx help
dfx canister --help
```

## Running the project locally

If you want to test your project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
dfx start --background

# Deploys your canisters to the replica and generates your candid interface
dfx deploy
```

Once the job completes, your application will be available at `http://localhost:4943?canisterId={asset_canister_id}`.

If you have made changes to your backend canister, you can generate a new candid interface with

```bash
npm run generate
```

at any time. This is recommended before starting the frontend development server, and will be run automatically any time you run `dfx deploy`.

If you are making frontend changes, you can start a development server with

```bash
npm start
```

Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 4943.

### Note on frontend environment variables

If you are hosting frontend code somewhere without using DFX, you may need to make one of the following adjustments to ensure your project does not fetch the root key in production:

- set`DFX_NETWORK` to `ic` if you are using Webpack
- use your own preferred method to replace `process.env.DFX_NETWORK` in the autogenerated declarations
  - Setting `canisters -> {asset_canister_id} -> declarations -> env_override to a string` in `dfx.json` will replace `process.env.DFX_NETWORK` with the string in the autogenerated declarations
- Write your own `createActor` constructor

# Marketplace Actor

This project defines a `Marketplace` actor in Motoko, a language used for programming on the Internet Computer. The `Marketplace` actor manages a marketplace where clients and freelancers can interact, post jobs, apply for jobs, and handle payments and disputes.

## Imports and Actor Definition

The code begins by importing various modules from the Motoko base library, such as [`Principal`], `HashMap`, `Buffer`, and others. These modules provide essential functionalities like handling principals (unique identifiers for users), hash maps, buffers, and cryptographic operations.

## Types and Data Structures

Several types are defined to structure the data used in the marketplace:

- **User**: Represents a user with a username, hashed password, and role (either `Client` or `Freelancer`).
- **Role**: An enumeration for user roles.
- **Payment**: Represents a payment with client and freelancer IDs, amount, and status.
- **Application**: Represents a job application with a job ID and cover letter.
- **Job**: Represents a job with a title, description, and salary.
- **Status**: An enumeration for various statuses like `pending`, `released`, `failed`, etc.
- **Evidence**: Represents evidence in a dispute with a description and optional file link.
- **Dispute**: Represents a dispute with client and freelancer IDs, reason, evidence, and status.
- **ImmutableDispute**: A version of `Dispute` with immutable arrays for evidence and status.

## Data Storage

The actor uses several hash maps to store data:

- **users**: Maps principals to user data.
- **usernameMap**: Maps usernames to principals.
- **disputes**: Maps principals to disputes.
- **payments**: Maps principals to payments.
- **sessions**: Maps principals to session timestamps.
- **jobs**: Maps principals to jobs.
- **applications**: Maps principals to job applications.

## User Functions

- **isAdmin**: Checks if the caller is the admin.
- **isLoggedIn**: Checks if a user is logged in by verifying their session timestamp.
- **getUserRole**: Retrieves the role of a user.
- **registerUser**: Registers a new user if they don't already exist.
- **hashPassword**: Hashes a password using a secret.
- **generatePrincipalFromUsername**: Generates a principal from a username.
- **signup**: Registers a new user by hashing their password and generating a principal.
- **login**: Authenticates a user by verifying their credentials and setting a session timestamp.
- **validateCredentials**: Validates a user's credentials.
- **getUsers**: Retrieves all users (admin only).
- **logout**: Logs out a user by deleting their session.
- **deleteUser**: Deletes a user (admin only).

## Job Functions

- **postJob**: Posts a new job.
- **getJob**: Retrieves a job by client ID.
- **deleteJob**: Deletes a job (admin only).

## Job Application Functions

- **applyForJob**: Submits a job application.
- **getApplications**: Retrieves job applications for a freelancer.

## Escrow Functions

- **createEscrow**: Creates an escrow payment.
- **releasePayment**: Releases a payment (admin only).

## Dispute Resolution Functions

- **initiateDispute**: Initiates a dispute.
- **submitEvidence**: Submits evidence for a dispute.
- **changeDisputeStatus**: Changes the status of a dispute (admin only).
- **getDispute**: Retrieves a dispute.
- **resolveDispute**: Resolves a dispute (admin only).
- **getDisputeStatus**: Retrieves the status of a dispute.
- **listAllDisputes**: Lists all disputes (admin only).

## Summary

The `Marketplace` actor provides a comprehensive set of functionalities to manage users, jobs, applications, payments, and disputes in a decentralized marketplace. It ensures secure interactions through authentication, authorization, and cryptographic operations.

*Env.mo added to gitignore. Create custom env.mo for hash and admin functionality*
  