import React from "react";
import { Link } from "react-router-dom";

export default function HomePage() {
  return (
    <div className="min-h-screen flex flex-col justify-center items-center text-center bg-purple-300">
      <h1 className="text-2xl font-bold">welcome to TrueWork</h1>
      <h2 className="text-xl font-semibold">
        A decentralized freelance marketplace
      </h2>
      <p className="text-lg">
        TrueWork is a platform that connects freelancers with clients, allowing
        them to work together on projects and earn rewards.
      </p>
      <Link
        to="/login"
        className="bg-indigo-700 hover:bg-indigo-800 text-white font-bold py-2 px-4 rounded"
      >
        Get Started
      </Link>
    </div>
  );
}
