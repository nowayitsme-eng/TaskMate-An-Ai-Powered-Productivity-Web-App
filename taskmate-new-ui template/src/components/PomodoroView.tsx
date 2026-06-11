import React, { useState, useEffect, useRef } from 'react';
import { Play, Pause, RotateCcw, CupSoda, Flame, Trophy, Award } from 'lucide-react';
import { motion } from 'motion/react';

interface PomodoroViewProps {
  onCompleteSession: (minutes: number) => void;
}

export default function PomodoroView({ onCompleteSession }: PomodoroViewProps) {
  const [mode, setMode] = useState<'work' | 'break' | 'longBreak'>('work');
  const [secondsLeft, setSecondsLeft] = useState(25 * 60);
  const [isActive, setIsActive] = useState(false);
  const [completedCycles, setCompletedCycles] = useState(0);

  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const presets = {
    work: 25 * 60,
    break: 5 * 60,
    longBreak: 15 * 60,
  };

  useEffect(() => {
    if (isActive) {
      intervalRef.current = setInterval(() => {
        setSecondsLeft((prev) => {
          if (prev <= 1) {
            // Completed!
            handleTimerComplete();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    } else {
      if (intervalRef.current) clearInterval(intervalRef.current);
    }

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [isActive]);

  const handleTimerComplete = () => {
    setIsActive(false);
    if (intervalRef.current) clearInterval(intervalRef.current);

    if (mode === 'work') {
      const minCompleted = Math.round(presets.work / 60);
      onCompleteSession(minCompleted);
      setCompletedCycles(prev => prev + 1);
      alert("🎉 Fantastic job! You completed a Pomodoro sprint. Your companion gained 40 XP!");
      // auto transition to break
      setMode('break');
      setSecondsLeft(presets.break);
    } else {
      alert("☀️ Break over! Ready to focus up again?");
      setMode('work');
      setSecondsLeft(presets.work);
    }
  };

  const setModeTimer = (newMode: 'work' | 'break' | 'longBreak') => {
    setIsActive(false);
    setMode(newMode);
    setSecondsLeft(presets[newMode]);
  };

  const toggleTimer = () => {
    setIsActive(!isActive);
  };

  const resetTimer = () => {
    setIsActive(false);
    setSecondsLeft(presets[mode]);
  };

  const formatTime = (totalSeconds: number) => {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div id="pomodoro-timer-screen" className="space-y-6">
      <div className="text-center">
        <h2 className="text-3xl font-extrabold text-slate-800 tracking-tight" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
          TaskMate
        </h2>
        <p className="text-slate-400 text-xs mt-1">Boost focus using scientific 25-minute intervals</p>
      </div>

      {/* Large visual Card representing Timer */}
      <div className="bg-white rounded-[32px] p-8 shadow-sm border border-slate-100/80 text-center relative max-w-sm mx-auto overflow-hidden">
        {/* Glow effect */}
        <div className="absolute top-0 inset-x-0 h-1.5 bg-gradient-to-r from-emerald-500 to-sky-500" />

        <div className="space-y-4 my-2">
          {/* Mode label */}
          <span className="text-indigo-400 font-bold uppercase text-xs tracking-[0.2em]">
            {mode === 'work' ? '🎓 WORK WORK' : mode === 'break' ? '☕ SHORT BREAK' : '🌴 RESTTIME'}
          </span>

          {/* Time digits */}
          <div className="text-7xl font-extrabold text-slate-800 tabular-nums select-none tracking-tight py-4">
            {formatTime(secondsLeft)}
          </div>

          {/* Core vertically stacked buttons shown in Mockup image */}
          <div className="space-y-3 max-w-xs mx-auto">
            {!isActive ? (
              <button 
                onClick={toggleTimer}
                className="w-full py-4 px-6 bg-emerald-500 hover:bg-emerald-600 text-white rounded-2xl font-semibold transition-all flex items-center justify-center gap-2 shadow-xs cursor-pointer active:scale-95"
              >
                <Play size={18} fill="white" /> Start
              </button>
            ) : (
              <button 
                onClick={toggleTimer}
                className="w-full py-4 px-6 bg-indigo-505 bg-slate-600 hover:bg-slate-700 text-white rounded-2xl font-semibold transition-all flex items-center justify-center gap-2 shadow-xs cursor-pointer active:scale-95"
              >
                <Pause size={18} fill="white" /> Pause
              </button>
            )}

            {secondsLeft !== presets[mode] && (
              <button 
                type="button"
                onClick={resetTimer}
                className="w-full py-3 px-6 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-2xl font-medium text-xs transition-colors flex items-center justify-center gap-1.5"
              >
                <RotateCcw size={14} /> Reset Segment
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Grid of presets exactly matching bottom of screenshot 4 */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {/* Work preset */}
        <button 
          onClick={() => setModeTimer('work')}
          className={`p-4 bg-white rounded-2xl border text-center transition-all cursor-pointer ${
            mode === 'work' ? 'border-emerald-400 ring-2 ring-emerald-50 shadow-xs' : 'border-slate-200/80 hover:bg-slate-50'
          }`}
        >
          <div className="mx-auto w-8 h-8 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-500 mb-2">
            <Flame size={16} />
          </div>
          <p className="text-xs font-bold text-slate-800">Work</p>
          <p className="text-[10px] text-slate-400 font-medium">25 min</p>
        </button>

        {/* Short Break preset */}
        <button 
          onClick={() => setModeTimer('break')}
          className={`p-4 bg-white rounded-2xl border text-center transition-all cursor-pointer ${
            mode === 'break' ? 'border-amber-400 ring-2 ring-amber-50 shadow-xs' : 'border-slate-200/80 hover:bg-slate-50'
          }`}
        >
          <div className="mx-auto w-8 h-8 rounded-full bg-amber-50 flex items-center justify-center text-amber-500 mb-2">
            <CupSoda size={16} />
          </div>
          <p className="text-xs font-bold text-slate-800">Break</p>
          <p className="text-[10px] text-slate-400 font-medium">5 min</p>
        </button>

        {/* Long Break preset */}
        <button 
          onClick={() => setModeTimer('longBreak')}
          className={`p-4 bg-white rounded-2xl border text-center transition-all cursor-pointer ${
            mode === 'longBreak' ? 'border-indigo-400 ring-2 ring-indigo-50 shadow-xs' : 'border-slate-200/80 hover:bg-slate-50'
          }`}
        >
          <div className="mx-auto w-8 h-8 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-500 mb-2">
            <RotateCcw size={16} />
          </div>
          <p className="text-xs font-bold text-slate-800">Long Break</p>
          <p className="text-[10px] text-slate-400 font-medium">15 min</p>
        </button>

        {/* Counter session card */}
        <div className="p-4 bg-white rounded-2xl border border-slate-200/80 text-center flex flex-col justify-center">
          <div className="mx-auto w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-slate-500 mb-2">
            <Trophy size={16} />
          </div>
          <p className="text-xs font-bold text-slate-800">Completed</p>
          <p className="text-[10px] text-indigo-600 font-extrabold">{completedCycles} Sessions</p>
        </div>
      </div>
    </div>
  );
}
