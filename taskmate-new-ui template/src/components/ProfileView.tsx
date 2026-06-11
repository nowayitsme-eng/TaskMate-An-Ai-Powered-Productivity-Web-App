import React from 'react';
import { Calendar, Settings, Lock, Check, TrendingUp, KeyRound, Trash2, Shield, CalendarCheck } from 'lucide-react';
import { motion } from 'motion/react';
import { User, ActivityDay } from '../types';

interface ProfileViewProps {
  user: User;
  onConnectCalendar: () => void;
  onLogout: () => void;
}

export default function ProfileView({ user, onConnectCalendar, onLogout }: ProfileViewProps) {
  // Mock contribution calendar study data
  const generateMockActivity = (): ActivityDay[] => {
    const days: ActivityDay[] = [];
    const baseDate = new Date();
    for (let i = 60; i >= 0; i--) {
      const d = new Date();
      d.setDate(baseDate.getDate() - i);
      const intensity = Math.floor(Math.random() * 5); // 0 to 4
      days.push({
        date: d.toISOString().split('T')[0],
        intensity: intensity,
        minutes: intensity * 15
      });
    }
    return days;
  };

  const activityDays = generateMockActivity();

  // Badges list matching Mockup 9
  const badgesData = [
    {
      id: 'first-step',
      title: 'First Step',
      description: 'Complete your very first task',
      icon: '🌱',
      requirement: 1,
      unlocked: true // Ali starts with 1 badge earned
    },
    {
      id: 'early-bird',
      title: 'Early Bird',
      description: 'Complete a task before 8 AM',
      icon: '⏰',
      requirement: 1,
      unlocked: false
    },
    {
      id: 'night-owl',
      title: 'Night Owl',
      description: 'Complete a task after 11 PM',
      icon: '🦉',
      requirement: 1,
      unlocked: false
    },
    {
      id: 'deep-focus',
      title: 'Deep Focus',
      description: 'Complete 4 Pomodoro sessions',
      icon: '🧠',
      requirement: 4,
      unlocked: false
    },
    {
      id: 'seven-day-streak',
      title: '7-Day Streak',
      description: 'Stay active 7 days in a row',
      icon: '🔥',
      requirement: 7,
      unlocked: false
    },
    {
      id: 'century-club',
      title: 'Century Club',
      description: 'Complete 100 tasks total',
      icon: '🛡️',
      requirement: 100,
      unlocked: false
    }
  ];

  const getHeatmapColor = (intensity: number) => {
    switch (intensity) {
      case 0: return 'bg-slate-100';
      case 1: return 'bg-emerald-100';
      case 2: return 'bg-emerald-200';
      case 3: return 'bg-emerald-300';
      case 4: return 'bg-emerald-500';
      default: return 'bg-slate-100';
    }
  };

  return (
    <div id="gamified-profile-screen" className="space-y-6">
      {/* Top Header */}
      <div className="flex justify-between items-center bg-white p-3 rounded-2xl shadow-xs border border-slate-100">
        <h2 className="text-lg font-extrabold text-slate-800 tracking-tight" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
          Gamified Profile
        </h2>
        <button 
          onClick={onLogout}
          className="p-2 text-rose-500 hover:bg-rose-50 rounded-xl transition-all font-bold text-xs"
        >
          Sign Out
        </button>
      </div>

      {/* Visual profile detail banner matching Screenshot 9 */}
      <div className="bg-gradient-to-tr from-indigo-100 via-indigo-50 to-purple-100 rounded-3xl p-6 border border-indigo-100/50 shadow-sm flex items-center gap-5">
        {/* Plant avatar */}
        <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-emerald-300 to-sky-200 flex items-center justify-center border-2 border-white shadow-md overflow-hidden flex-shrink-0">
          <svg viewBox="0 0 100 100" className="w-[110%] h-[110%] mt-1">
            <ellipse cx="50" cy="58" rx="26" ry="24" fill="#a7f3d0" />
            <ellipse cx="36" cy="62" rx="4" ry="2" fill="#fda4af" />
            <ellipse cx="64" cy="62" rx="4" ry="2" fill="#fda4af" />
            <circle cx="40" cy="54" r="3.5" fill="#1e293b" />
            <circle cx="39" cy="52.5" r="1.5" fill="#ffffff" />
            <circle cx="60" cy="54" r="3.5" fill="#1e293b" />
            <circle cx="59" cy="52.5" r="1.5" fill="#ffffff" />
            <path d="M 47 62 Q 50 65 53 62" stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" fill="none" />
            <path d="M 50 34 C 50 24, 45 22, 40 22 C 45 22, 50 26, 50 34" stroke="#059669" strokeWidth="3" fill="none" />
            <path d="M 50 32 C 50 22, 55 20, 60 20 C 55 20, 50 24, 50 32" stroke="#059669" strokeWidth="3" fill="none" />
            <path d="M 45 22 Q 40 16 34 22 Q 41 26 45 22" fill="#34d399" />
            <path d="M 55 20 Q 60 14 66 20 Q 59 24 55 20" fill="#34d399" />
          </svg>
        </div>

        {/* Level metrics details */}
        <div className="flex-grow min-w-0">
          <h3 className="text-2xl font-black text-indigo-950 truncate">{user.name}</h3>
          
          <div className="flex justify-between items-center text-xs font-semibold text-slate-500 mt-1">
            <span>Level {user.level}</span>
            <span>{user.xp} / 100 XP</span>
          </div>

          <div className="h-2.5 bg-white/60 border border-indigo-200/40 rounded-full overflow-hidden p-[2px] mt-1.5">
            <div className="h-full bg-gradient-to-r from-emerald-400 to-indigo-500 rounded-full" style={{ width: `${user.xp}%` }} />
          </div>

          <p className="text-[10px] text-indigo-700/80 font-bold mt-2">
            1/6 Badges Earned • {user.xp + ((user.level - 1) * 100)} total lifetime XP
          </p>
        </div>
      </div>

      {/* Badges Section */}
      <div className="space-y-3">
        <h4 className="text-sm font-bold text-slate-500 uppercase tracking-wider pl-1">Earned Badges</h4>
        
        <div className="grid grid-cols-2 gap-3">
          {badgesData.map(badge => {
            // override unlocked state using actual user model logs for high accuracy
            const isUnlocked = badge.id === 'first-step' || user.badges.includes(badge.id);

            return (
              <div 
                key={badge.id}
                className={`p-4 rounded-2xl border text-left flex items-start gap-3 relative overflow-hidden transition-all duration-300 ${
                  isUnlocked 
                    ? 'bg-gradient-to-tr from-indigo-50 to-purple-50 hover:from-indigo-100 hover:to-purple-100 border-indigo-200 text-indigo-900 shadow-xs' 
                    : 'bg-slate-100/70 border-slate-200/80 text-slate-500 opacity-80'
                }`}
              >
                {/* SVG Badge circles matching mockup */}
                <div className={`w-11 h-11 rounded-full flex-shrink-0 flex items-center justify-center text-lg ${
                  isUnlocked ? 'bg-indigo-600 shadow-sm' : 'bg-slate-200'
                }`}>
                  {isUnlocked ? badge.icon : '🔒'}
                </div>

                <div className="min-w-0">
                  <p className="font-extrabold text-xs sm:text-sm truncate">{badge.title}</p>
                  <p className="text-[10px] text-slate-400 font-medium leading-relaxed mt-0.5">{badge.description}</p>
                </div>

                {isUnlocked && (
                  <span className="absolute top-2 right-2 bg-indigo-200 text-indigo-800 text-[8px] font-extrabold px-1.5 py-0.5 rounded-full">
                    EARNED
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Contribution Grid Heatmap exactly as shown in Screenshot 9 */}
      <div className="bg-white rounded-3xl p-5 shadow-sm border border-slate-100/80 space-y-3">
        <h4 className="text-sm font-bold text-slate-700">Study Activity Heatmap</h4>
        
        {/* Contributions map cells */}
        <div className="grid grid-flow-col grid-rows-4 gap-1.5 overflow-x-auto py-1 scrollbar-none justify-start">
          {activityDays.map((d, index) => (
            <div 
              key={index}
              title={`${new Date(d.date).toLocaleDateString()}: Focused for ${d.minutes}m`}
              className={`w-3.5 h-3.5 rounded-sm transition-transform hover:scale-125 ${getHeatmapColor(d.intensity)}`}
            />
          ))}
        </div>

        <div className="flex justify-between items-center text-[10px] text-slate-400 font-bold px-1.5">
          <span>60 days ago</span>
          <div className="flex items-center gap-1">
            <span>Less</span>
            <div className="w-2.5 h-2.5 rounded bg-slate-100" />
            <div className="w-2.5 h-2.5 rounded bg-emerald-100" />
            <div className="w-2.5 h-2.5 rounded bg-emerald-300" />
            <div className="w-2.5 h-2.5 rounded bg-emerald-500" />
            <span>More</span>
          </div>
          <span>Today</span>
        </div>
      </div>

      {/* Bar Chart of Study Analytics matching mockup 9 */}
      <div className="bg-white rounded-3xl p-5 shadow-sm border border-slate-100/80 space-y-4">
        <h4 className="text-sm font-bold text-slate-700">Study Analytics (Focus Hours)</h4>
        
        {/* CSS Chart flexbars */}
        <div className="flex items-end justify-between h-28 pt-4 px-2">
          {[
            { day: 'Mo', hrs: 1.5 },
            { day: 'Tu', hrs: 3.2 },
            { day: 'We', hrs: 2.1 },
            { day: 'Th', hrs: 1.8 },
            { day: 'Fr', hrs: 4.5 },
            { day: 'Sa', hrs: 2.8 },
            { day: 'Su', hrs: 1.0 },
          ].map((item, index) => {
            const heightPct = (item.hrs / 5) * 100;
            return (
              <div key={index} className="flex flex-col items-center gap-2 flex-grow">
                <div className="relative w-7 bg-slate-100 rounded-t-lg h-full flex items-end">
                  <div 
                    className="w-full bg-gradient-to-t from-indigo-500 to-indigo-600 rounded-t-lg transition-all duration-500 hover:opacity-85"
                    style={{ height: `${heightPct}%` }}
                    title={`${item.hrs} hours`}
                  />
                </div>
                <span className="text-[10px] font-bold text-slate-400">{item.day}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Settings section matching screenshot 9 */}
      <div className="bg-white rounded-3xl p-1.5 shadow-sm border border-slate-100/80">
        <div className="divide-y divide-slate-100">
          {/* Calendar row */}
          <button 
            onClick={onConnectCalendar}
            className="w-full flex items-center justify-between p-4 hover:bg-slate-50 transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-50 text-indigo-600 rounded-xl">
                <CalendarCheck size={18} />
              </div>
              <div>
                <p className="text-sm font-bold text-slate-800">Connect Google Calendar</p>
                <p className="text-[10px] text-slate-400 font-medium">Sync task deadlines to Google Calendar</p>
              </div>
            </div>
            <span className="text-xs bg-slate-100 text-slate-500 font-bold px-2 py-0.5 rounded-full">
              NOT LINKED
            </span>
          </button>

          {/* Password row */}
          <button 
            onClick={() => alert("Simulated: Password update workflow triggered.")}
            className="w-full flex items-center justify-between p-4 hover:bg-slate-50 transition-colors text-left font-medium"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-slate-100 text-slate-600 rounded-xl">
                <KeyRound size={18} />
              </div>
              <div>
                <p className="text-sm font-bold text-slate-800">Change Password</p>
              </div>
            </div>
          </button>

          {/* Delete account row */}
          <button 
            onClick={() => {
              if (confirm("Are you sure you want to delete your account? All XP logs will be cleared.")) {
                onLogout();
                alert("Account deleted.");
              }
            }}
            className="w-full flex items-center justify-between p-4 hover:bg-rose-50/50 transition-colors text-left font-medium"
          >
            <div className="flex items-center gap-3 text-rose-600">
              <div className="p-2 bg-rose-50 text-rose-600 rounded-xl">
                <Trash2 size={18} />
              </div>
              <div>
                <p className="text-sm font-bold">Delete Account</p>
              </div>
            </div>
          </button>
        </div>
      </div>
    </div>
  );
}
