# `DecaHack2`

Welcome to the `DecaHack2` project and the Internet Computer development community! This project implements a decentralized marketplace using the Motoko programming language, providing functionalities for user management, job postings, escrow payments, and dispute resolution.

---

## 🗂 Project Overview

By default, this project includes template files to get you started. You can customize these files and add your own code to accelerate development.

### Useful Resources

Explore these resources to learn more about developing on the Internet Computer:

- [Quick Start Guide](https://internetcomputer.org/docs/current/developer-docs/setup/deploy-locally)
- [SDK Developer Tools](https://internetcomputer.org/docs/current/developer-docs/setup/install)
- [Motoko Programming Language Guide](https://internetcomputer.org/docs/current/motoko/main/motoko)
- [Motoko Language Quick Reference](https://internetcomputer.org/docs/current/motoko/main/language-manual)

### Getting Started

To begin working on the project:

1. **Navigate to the project directory**:
   ```bash
   cd DecaHack2/
   ```

2. **Check available commands**:
   ```bash
   dfx help
   dfx canister --help
   ```

---

## 🚀 Running the Project Locally

Follow these steps to test your project locally:

1. **Start the replica**:
   ```bash
   dfx start --background
   ```

2. **Deploy canisters**:
   ```bash
   dfx deploy
   ```

   Your application will then be accessible at:
   ```
   http://localhost:4943?canisterId={asset_canister_id}
   ```

3. **Generate the Candid interface** (if backend changes occur):
   ```bash
   npm run generate
   ```

4. **Start the frontend development server**:
   ```bash
   npm start
   ```
   Access the frontend at `http://localhost:8080`.

---

## 🔧 Features

### User Management
- **Admin Controls**: Verify admin status, manage users.
- **Authentication**: Register, login, update, delete and logout users.
- **User Roles**: Differentiate roles (e.g., Client, Freelancer).
- **Session Management**: Track logged-in users.
- **Password Hashing**: Custom secure hashing.

### Job Management
- **Post Jobs**: Clients can post jobs.
- **Manage Jobs**: View, update, or delete job postings.
- **Applications**: Freelancers can apply for jobs.

### Escrow Payments
- **Payment Handling**: Create and release escrow payments.
- **Secure Transactions**: Funds are held securely until task completion.

### Dispute Resolution
- **Raise Disputes**: Address issues between clients and freelancers.
- **Evidence Submission**: Provide evidence to support claims.
- **Admin Adjudication**: Resolve disputes with admin intervention.

---

## 🔑 Key Concepts and Data Structures

### User
Defines a platform user, including:
- **Username**: Unique identifier.
- **Password**: Securely hashed.
- **Role**: Defines permissions and actions.

### Job
Represents job postings with:
- **Title & Description**: Key details about the job.
- **Salary**: Offered payment.

### Payment
Details of escrow payments, including:
- **Client & Freelancer IDs**: Identifies involved parties.
- **Amount & Status**: Transaction details.

### Dispute
Handles conflicts with:
- **Parties Involved**: Client and freelancer.
- **Evidence**: Provided documentation.
- **Status**: Tracks resolution progress.

---

## 💃 Data Storage
The project uses `HashMap` for efficient data storage:
- **Users**: Store registered users and roles.
- **Jobs**: Manage job postings and applications.
- **Escrows**: Handle payment transactions.
- **Disputes**: Track conflict cases.

---

## 📝 Notes
- **Frontend Variables**: Configure `DFX_NETWORK` to `ic` or manage `process.env.DFX_NETWORK` manually.
- **Environment Variables**: `Env.mo` added to `.gitignore`. Create new `Env.mo` and define custom module for admin and canisters ID variables. E.g `module{public let admin = "aaaaa-aa"}`

---