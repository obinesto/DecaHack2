import React, { useState, useEffect } from 'react';
import { Actor, HttpAgent } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';
import { idlFactory } from '../../../../declarations/users/users.did';

const Auth = () => {
  const [authClient, setAuthClient] = useState(null);
  const [actor, setActor] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('Client');
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

  const initActor = async (client) => {
    const agent = new HttpAgent({ identity: client.getIdentity() });
    const actor = Actor.createActor(idlFactory, {
      agent,
      canisterId: process.env.USERS_CANISTER_ID,
    });
    setActor(actor);
  };

  const handleSignup = async (e) => {
    e.preventDefault();
    try {
      const result = await actor.signup(username, password, { [role]: null });
      if ('ok' in result) {
        console.log('Signup successful');
        setIsAuthenticated(true);
      } else {
        console.error('Signup failed:', result.err);
      }
    } catch (error) {
      console.error('Signup error:', error);
    }
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const result = await actor.login(username, password);
      if ('ok' in result) {
        console.log('Login successful');
        setIsAuthenticated(true);
      } else {
        console.error('Login failed:', result.err);
      }
    } catch (error) {
      console.error('Login error:', error);
    }
  };

  const handleLogout = async () => {
    try {
      const result = await actor.logout();
      if ('ok' in result) {
        console.log('Logout successful');
        setIsAuthenticated(false);
        authClient.logout();
      } else {
        console.error('Logout failed:', result.err);
      }
    } catch (error) {
      console.error('Logout error:', error);
    }
  };
  if (!authClient) return <div className="flex justify-center items-center h-screen">Loading...</div>;

  return (
    <div className="flex justify-center items-center min-h-screen bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-md w-full max-w-md">
        {isAuthenticated ? (
          <div className="text-center">
            <p className="text-2xl font-semibold mb-4">Welcome, {username}!</p>
            <button 
              onClick={handleLogout}
              className="w-full bg-red-500 text-white py-2 px-4 rounded hover:bg-red-600 transition duration-300"
            >
              Logout
            </button>
          </div>
        ) : (
          <div>
            <h2 className="text-2xl font-bold mb-6 text-center">{isAuthenticated ? 'Login' : 'Signup'}</h2>
            <form onSubmit={isAuthenticated ? handleLogin : handleSignup} className="space-y-4">
              <input
                type="text"
                placeholder="Username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              {!isAuthenticated && (
                <select 
                  value={role} 
                  onChange={(e) => setRole(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="Client">Client</option>
                  <option value="Freelancer">Freelancer</option>
                </select>
              )}
              <button 
                type="submit"
                className="w-full bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600 transition duration-300"
              >
                {isAuthenticated ? 'Login' : 'Signup'}
              </button>
            </form>
            <p className="mt-4 text-center text-sm text-gray-600">
              {isAuthenticated ? "Don't have an account? " : "Already have an account? "}
              <button 
                onClick={() => setIsAuthenticated(!isAuthenticated)}
                className="text-blue-500 hover:underline"
              >
                {isAuthenticated ? 'Sign up' : 'Log in'}
              </button>
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Auth;