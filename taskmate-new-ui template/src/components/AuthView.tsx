import React, { useState } from 'react';
import { Eye, EyeOff, Mail, Lock, User as UserIcon } from 'lucide-react';
import { motion } from 'motion/react';
import { User } from '../types';

interface AuthViewProps {
  onAuthSuccess: (user: User) => void;
}

export default function AuthView({ onAuthSuccess }: AuthViewProps) {
  const [isLogin, setIsLogin] = useState(true);
  const [fullName, setFullName] = useState('Ali');
  const [email, setEmail] = useState('alisani9898@gmail.com');
  const [password, setPassword] = useState('password123');
  const [confirmPassword, setConfirmPassword] = useState('password123');
  
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');

    if (!email || !password) {
      setErrorMsg('Please load all fields.');
      return;
    }

    if (!isLogin) {
      if (!fullName) {
        setErrorMsg('Please provide your full name.');
        return;
      }
      if (password !== confirmPassword) {
        setErrorMsg('Passwords do not match.');
        return;
      }
    }

    // Try localStorage
    const savedUsersStr = localStorage.getItem('taskmate_users') || '[]';
    const savedUsers: any[] = JSON.parse(savedUsersStr);

    if (isLogin) {
      // Find user
      const foundUser = savedUsers.find(u => u.email.toLowerCase() === email.toLowerCase());
      if (foundUser) {
        onAuthSuccess(foundUser);
      } else {
        // Since it's a prototype/simulation, let's create a fresh account on the fly so they are never locked out!
        const newUser: User = {
          id: 'user-' + Date.now(),
          name: fullName || 'Ali',
          email: email,
          xp: 30,
          level: 1,
          badges: ['first-step'],
          studyMinutes: 0,
          streak: 1,
          lastActiveDate: new Date().toISOString().split('T')[0]
        };
        savedUsers.push(newUser);
        localStorage.setItem('taskmate_users', JSON.stringify(savedUsers));
        onAuthSuccess(newUser);
      }
    } else {
      // Sign up
      const existing = savedUsers.find(u => u.email.toLowerCase() === email.toLowerCase());
      if (existing) {
        setErrorMsg('An account with this email already exists.');
        return;
      }

      const newUser: User = {
        id: 'user-' + Date.now(),
        name: fullName,
        email: email,
        xp: 30,
        level: 1,
        badges: ['first-step'],
        studyMinutes: 0,
        streak: 1,
        lastActiveDate: new Date().toISOString().split('T')[0]
      };

      savedUsers.push(newUser);
      localStorage.setItem('taskmate_users', JSON.stringify(savedUsers));
      onAuthSuccess(newUser);
    }
  };

  return (
    <div id="auth-view-screen" className="min-h-screen bg-slate-50/60 flex items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0, y: 15 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-sm bg-white rounded-[32px] p-8 shadow-xl border border-slate-100"
      >
        <div className="text-center mb-8">
          <h1 className="text-4xl font-extrabold text-indigo-600 tracking-tight" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
            TaskMate
          </h1>
          <p className="text-slate-500 text-sm mt-3 font-medium">
            {isLogin 
              ? "Login to check in with your study partner!" 
              : "Create your account to start your journey!"}
          </p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-100 text-rose-600 text-xs rounded-xl font-medium">
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {!isLogin && (
            <div>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                  <UserIcon size={18} />
                </span>
                <input 
                  type="text" 
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Full Name"
                  className="w-full pl-11 pr-4 py-3 bg-white border border-slate-200 rounded-xl text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                />
              </div>
            </div>
          )}

          <div>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                <Mail size={18} />
              </span>
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Email"
                className="w-full pl-11 pr-4 py-3 bg-white border border-slate-200 rounded-xl text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
              />
            </div>
          </div>

          <div>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                <Lock size={18} />
              </span>
              <input 
                type={showPassword ? "text" : "password"} 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Password"
                className="w-full pl-11 pr-11 py-3 bg-white border border-slate-200 rounded-xl text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
              />
              <button 
                type="button" 
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-0 flex items-center pr-3.5 text-slate-400 hover:text-slate-600 focus:outline-none"
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          {!isLogin && (
            <div>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                  <Lock size={18} />
                </span>
                <input 
                  type={showConfirmPassword ? "text" : "password"} 
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Confirm Password"
                  className="w-full pl-11 pr-11 py-3 bg-white border border-slate-200 rounded-xl text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                />
                <button 
                  type="button" 
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute inset-y-0 right-0 flex items-center pr-3.5 text-slate-400 hover:text-slate-600 focus:outline-none"
                >
                  {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
          )}

          <button 
            type="submit" 
            className="w-full py-3.5 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-semibold transition-colors shadow-sm mt-2"
          >
            {isLogin ? "Sign In" : "Sign Up"}
          </button>
        </form>

        <div className="text-center mt-6">
          <button 
            onClick={() => {
              setErrorMsg('');
              setIsLogin(!isLogin);
            }}
            className="text-indigo-600 hover:text-indigo-800 text-xs font-semibold"
          >
            {isLogin 
              ? "New to TaskMate? Create account" 
              : "Already have an account? Login"}
          </button>
        </div>
      </motion.div>
    </div>
  );
}
