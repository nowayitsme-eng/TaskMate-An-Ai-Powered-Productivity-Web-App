import React, { useState } from 'react';
import { Sparkles, X, Heart, Award } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface CompanionCardProps {
  xp: number;
  level: number;
  name: string;
  onInteract?: () => void;
}

export default function CompanionCard({ xp, level, name, onInteract }: CompanionCardProps) {
  const [showSpeechBubble, setShowSpeechBubble] = useState(false);
  const [speechText, setSpeechText] = useState("Let's crush our goals today! 🚀");
  const [showCompanionModal, setShowCompanionModal] = useState(false);

  const companionPhrases = [
    "You are doing amazing, keep it up! 🌱",
    "Ready for a quick 25-minute Pomodoro sprint? ⏱️",
    "Every tiny task completed feeds my growth! ☀️",
    "Did you know? Active recall increases retentivity by 150%! 🧠",
    "I'm so proud to be your study partner! 💚",
    "Drinking water while studying helps cognitive speed! 💧",
    "Make sure to schedule breaks, mental rest is crucial! 🌸",
  ];

  const handleCompanionClick = () => {
    const randomPhrase = companionPhrases[Math.floor(Math.random() * companionPhrases.length)];
    setSpeechText(randomPhrase);
    setShowSpeechBubble(true);
    // Auto hide bubble after 3.5 seconds
    setTimeout(() => {
      setShowSpeechBubble(false);
    }, 4000);

    setShowCompanionModal(true);
    if (onInteract) onInteract();
  };

  const nextLevelXp = 100;
  const progressPercent = Math.min((xp / nextLevelXp) * 100, 100);

  return (
    <>
      <div 
        id="companion-container"
        className="relative bg-gradient-to-r from-emerald-50 via-sky-50 to-indigo-50 border border-slate-100/80 rounded-3xl p-4 shadow-sm hover:shadow-md cursor-pointer transition-all duration-300 transform active:scale-95"
        onClick={handleCompanionClick}
      >
        <div className="flex items-center gap-4">
          {/* Cute Plant Sprout Avatar */}
          <div className="relative flex-shrink-0 w-16 h-16 rounded-full bg-gradient-to-tr from-emerald-200 to-sky-100 flex items-center justify-content border-2 border-white shadow-sm overflow-hidden">
            {/* Custom SVG Sprout Illustration (No remote fetch failure risks) */}
            <svg viewBox="0 0 100 100" className="w-full h-full p-1">
              {/* Cute Plant Bean */}
              <ellipse cx="50" cy="58" rx="26" ry="24" fill="#a7f3d0" />
              {/* Cheeks */}
              <ellipse cx="36" cy="62" rx="4" ry="2" fill="#fda4af" />
              <ellipse cx="64" cy="62" rx="4" ry="2" fill="#fda4af" />
              {/* Shiny Eyes */}
              <circle cx="40" cy="54" r="3.5" fill="#1e293b" />
              <circle cx="39" cy="52.5" r="1.5" fill="#ffffff" />
              <circle cx="60" cy="54" r="3.5" fill="#1e293b" />
              <circle cx="59" cy="52.5" r="1.5" fill="#ffffff" />
              {/* Cute Smile */}
              <path d="M 47 62 Q 50 65 53 62" stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" fill="none" />
              {/* Sprout Stem */}
              <path d="M 50 34 C 50 24, 45 22, 40 22 C 45 22, 50 26, 50 34" stroke="#059669" strokeWidth="3" fill="none" />
              <path d="M 50 32 C 50 22, 55 20, 60 20 C 55 20, 50 24, 50 32" stroke="#059669" strokeWidth="3" fill="none" />
              {/* Leaf Details */}
              <path d="M 45 22 Q 40 16 34 22 Q 41 26 45 22" fill="#34d399" />
              <path d="M 55 20 Q 60 14 66 20 Q 59 24 55 20" fill="#34d399" />
            </svg>
            <span className="absolute bottom-1 right-1 flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
          </div>

          {/* Details */}
          <div className="flex-1 min-w-0">
            <div className="flex justify-between items-center mb-1">
              <p className="text-sm font-semibold text-slate-700">Your Companion • <span className="text-slate-500 text-xs font-normal">Tap to interact</span></p>
            </div>
            
            {/* Custom progress bar and level */}
            <div className="flex items-center gap-3">
              <div className="flex-1 h-3 bg-slate-200/80 rounded-full overflow-hidden p-[2px]">
                <div 
                  className="h-full bg-gradient-to-r from-emerald-400 to-sky-400 rounded-full transition-all duration-500 animate-pulse" 
                  style={{ width: `${progressPercent}%` }}
                />
              </div>
              <span className="bg-slate-100 text-slate-700 text-[10px] font-bold px-2 py-0.5 rounded-full shadow-sm border border-slate-200">
                Lv {level}
              </span>
            </div>
          </div>
        </div>

        {/* Floating Bubble feedback */}
        <AnimatePresence>
          {showSpeechBubble && (
            <motion.div 
              initial={{ opacity: 0, y: 10, scale: 0.9 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 5, scale: 0.95 }}
              className="absolute -top-12 left-6 z-10 bg-slate-800 text-white text-xs px-3 py-1.5 rounded-xl shadow-lg font-medium max-w-[210px] pointer-events-none"
            >
              <div className="absolute -bottom-1.5 left-8 w-3 h-3 bg-slate-800 rotate-45" />
              {speechText}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Companion Details Dialogue Modal */}
      <AnimatePresence>
        {showCompanionModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="relative w-full max-w-sm bg-white rounded-3xl p-6 shadow-xl border border-slate-100 text-center"
            >
              <button 
                onClick={(e) => {
                  e.stopPropagation();
                  setShowCompanionModal(false);
                }}
                className="absolute top-4 right-4 p-1.5 bg-slate-100 text-slate-500 rounded-full hover:bg-slate-200"
              >
                <X size={16} />
              </button>

              <div className="mx-auto w-24 h-24 rounded-full bg-gradient-to-tr from-emerald-200 to-sky-100 flex items-center justify-center border-4 border-slate-50 shadow-md overflow-hidden my-4">
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

              <h3 className="text-xl font-bold text-slate-800">Sprouty the Study Buddy</h3>
              <p className="text-slate-500 text-xs mt-1">Sprouty grows as you complete goals!</p>

              <div className="mt-5 p-4 rounded-2xl bg-emerald-50 border border-emerald-100 text-sm italic text-slate-700 font-medium">
                "{speechText}"
              </div>

              <div className="mt-5 space-y-3">
                <div className="flex justify-between items-center text-xs font-semibold text-slate-600 px-1">
                  <span>Current Level: {level}</span>
                  <span>{xp}/100 XP to Level {level+1}</span>
                </div>
                <div className="h-4 bg-slate-100 rounded-full overflow-hidden p-[3px] border border-slate-200">
                  <div 
                    className="h-full bg-gradient-to-r from-emerald-400 to-sky-400 rounded-full transition-all duration-500" 
                    style={{ width: `${progressPercent}%` }}
                  />
                </div>
              </div>

              <div className="mt-6 flex flex-col gap-2">
                <button 
                  onClick={() => {
                    const r = companionPhrases[Math.floor(Math.random() * companionPhrases.length)];
                    setSpeechText(r);
                  }}
                  className="py-2.5 px-4 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-sm font-semibold transition-colors flex items-center justify-center gap-1.5 shadow-xs"
                >
                  <Sparkles size={16} /> Tap to pet Sprouty (+5 XP)
                </button>
                <button 
                  onClick={() => setShowCompanionModal(false)}
                  className="py-2 px-4 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-xl text-xs font-semibold transition-colors"
                >
                  Close Room
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </>
  );
}
