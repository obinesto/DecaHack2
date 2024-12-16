import React, { useState, useEffect, useLo } from "react";
import { useNavigate } from "react-router-dom";
import { AuthClient } from "@dfinity/auth-client";
import { DecaHack2_backend } from "declarations/DecaHack2_backend";

const Auth = ({ notify }) => {
  const [authClient, setAuthClient] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [role, setRole] = useState("Client");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const initAuth = async () => {
      const client = await AuthClient.create();
      setAuthClient(client);

      const isLoggedIn = await client.isAuthenticated();
      setIsAuthenticated(isLoggedIn);

      if (isLoggedIn) {
        initActor(client);
      }
    };

    initAuth();
  }, []);

  const handleSignup = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const result = await DecaHack2_backend.signup(username, password, {
        [role]: null,
      });
      if ("ok" in result) {
        console.log("Signup successful");
        notify("Signup successful", "success");
        setIsAuthenticated(true);
        navigate("/no-dashboard-yet");
      } else {
        console.error("Signup failed:", result.err);
        setError(result.err);
        notify("Signup failed", "error");
      }
    } catch (error) {
      console.error("Signup error:", error);  
      notify("Signup error", "error");
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const result = await DecaHack2_backend.login(username, password);
      if ("ok" in result) {
        console.log("Login successful");
        notify("Login successful", "success");
        setIsAuthenticated(true);
        navigate("/no-dashboard-yet");
      } else {
        console.error("Login failed:", result.err);
        setError(result.err);
        notify("Login failed", "error");
      }
    } catch (error) {
      console.error("Login error:", error);
      notify("Login error", "error");
    } finally {
      setLoading(false);
    }
  };

  if (!authClient)
    return (
      <div className="flex justify-center items-center h-screen">
        Loading...
      </div>
    );

  return (
    <div className="flex justify-center items-center min-h-screen bg-purple-300">
      <div className="bg-white p-8 rounded-lg shadow-md w-full max-w-md">
        <div>
          <h2 className="text-2xl font-bold mb-6 text-center">
            {isAuthenticated ? "Login" : "Signup"}
          </h2>
          {error && (
          <p className="text-red-600 text-center mb-4 text-sm font-medium">
            {error}
          </p>
        )}
          <form
            onSubmit={isAuthenticated ? handleLogin : handleSignup}
            className="space-y-4"
          >
            <input
              type="text"
              placeholder="Username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-700"
            />
            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-700"
            />
            {!isAuthenticated && (
              <select
                value={role}
                onChange={(e) => setRole(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-700"
              >
                <option value="Client">Client</option>
                <option value="Freelancer">Freelancer</option>
              </select>
            )}
            <button
              type="submit"
              disabled={loading}
              className={`w-full bg-indigo-700 text-white py-2 px-4 rounded hover:bg-indigo-600 transition duration-300 ${
                loading
                  ? "bg-indigo-600 cursor-not-allowed"
                  : "bg-indigo-700 hover:bg-indigo-600"
              }`}
            >
              {loading ? (
                <div className="flex justify-center items-center">
                  <div className="w-5 h-5 border-4 border-t-transparent border-gray-300 rounded-full animate-spin"></div>
                </div>
              ) : isAuthenticated ? (
                "Login"
              ) : (
                "Register"
              )}
            </button>
          </form>
          <p className="mt-4 text-center text-sm text-gray-600">
            {isAuthenticated
              ? "Don't have an account? "
              : "Already have an account? "}
            <button
              onClick={() => setIsAuthenticated(!isAuthenticated)}
              className="text-indigo-700 hover:underline"
            >
              {isAuthenticated ? "Sign up" : "Log in"}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Auth;
