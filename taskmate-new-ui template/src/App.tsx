import React, { useState, useEffect } from 'react';
import { 
  LayoutGrid, 
  ClipboardList, 
  Timer, 
  Calculator, 
  MessageSquare, 
  BookOpen, 
  User as UserIcon, 
  Plus, 
  Play, 
  Bot, 
  Sparkles, 
  Loader2, 
  Info,
  CalendarDays,
  X,
  CheckCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

// Subcomponents import
import CompanionCard from './components/CompanionCard';
import TasksView from './components/TasksView';
import PomodoroView from './components/PomodoroView';
import GpaView from './components/GpaView';
import AiChatView from './components/AiChatView';
import StudyHubView from './components/StudyHubView';
import ProfileView from './components/ProfileView';
import AuthView from './components/AuthView';

import { User, Task, Subject, Message } from './types';

export default function App() {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'tasks' | 'pomodoro' | 'gpa' | 'chat' | 'study_hub' | 'profile'>('dashboard');
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  
  // Data State
  const [tasks, setTasks] = useState<Task[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [chatMessages, setChatMessages] = useState<Message[]>([]);
  const [chatLoading, setChatLoading] = useState(false);

  // Insight modal state
  const [insightReport, setInsightReport] = useState<string | null>(null);
  const [isGeneratingInsight, setIsGeneratingInsight] = useState(false);

  // Load from local storage
  useEffect(() => {
    const savedUserStr = localStorage.getItem('taskmate_current_user');
    const savedTasksStr = localStorage.getItem('taskmate_tasks');
    const savedSubjectsStr = localStorage.getItem('taskmate_subjects');
    const savedChatStr = localStorage.getItem('taskmate_chats');

    if (savedUserStr) {
      setCurrentUser(JSON.parse(savedUserStr));
    } else {
      // Create initial guest user named Ali to match the screenshot greeting!
      const defaultGuest: User = {
        id: 'guest-' + Date.now(),
        name: 'Ali',
        email: 'alisani9898@gmail.com',
        xp: 30, // Starts at 30 XP as in the mockup screenshot!
        level: 1,
        badges: ['first-step'], // 1 badge earned initially!
        studyMinutes: 0,
        streak: 1,
        lastActiveDate: new Date().toISOString().split('T')[0]
      };
      setCurrentUser(defaultGuest);
      localStorage.setItem('taskmate_current_user', JSON.stringify(defaultGuest));
    }

    if (savedTasksStr) {
      setTasks(JSON.parse(savedTasksStr));
    } else {
      // Default tasks as seen in screen 2
      const defaultTasks: Task[] = [
        {
          id: 'task-1',
          userId: 'guest',
          description: 'Math Exam prep',
          category: 'maths',
          type: 'Exam',
          dueDate: '2026-06-17',
          priority: 'high',
          done: false,
          createdAt: new Date().toISOString()
        }
      ];
      setTasks(defaultTasks);
      localStorage.setItem('taskmate_tasks', JSON.stringify(defaultTasks));
    }

    if (savedSubjectsStr) {
      setSubjects(JSON.parse(savedSubjectsStr));
    }

    if (savedChatStr) {
      setChatMessages(JSON.parse(savedChatStr));
    }
  }, []);

  // Save changes helper
  const saveUserData = (updatedUser: User) => {
    setCurrentUser(updatedUser);
    localStorage.setItem('taskmate_current_user', JSON.stringify(updatedUser));
  };

  // 1. ADD REWARDS (XP) loop with dynamic Levels
  const handleEarnXp = (amount: number) => {
    if (!currentUser) return;
    
    let updatedXp = currentUser.xp + amount;
    let updatedLevel = currentUser.level;
    let leveledUp = false;

    while (updatedXp >= 100) {
      updatedXp -= 100;
      updatedLevel += 1;
      leveledUp = true;
    }

    const updatedUser = {
      ...currentUser,
      xp: updatedXp,
      level: updatedLevel
    };

    saveUserData(updatedUser);
    
    if (leveledUp) {
      alert(`🎉 Level Up! Sprouty has grown to Level ${updatedLevel}! Keep setting and smashing goals!`);
    }
  };

  // Task Handlers
  const handleAddTask = (newTaskData: Omit<Task, 'id' | 'createdAt' | 'userId'>) => {
    if (!currentUser) return;

    const newTask: Task = {
      ...newTaskData,
      id: 'task-' + Date.now(),
      userId: currentUser.id,
      createdAt: new Date().toISOString()
    };

    const newTasks = [newTask, ...tasks];
    setTasks(newTasks);
    localStorage.setItem('taskmate_tasks', JSON.stringify(newTasks));
    
    // Earn 10 XP on logging a new goal
    handleEarnXp(10);
  };

  const handleToggleTask = (id: string) => {
    const updated = tasks.map(t => {
      if (t.id === id) {
        const nextState = !t.done;
        if (nextState) {
          // Completed! Earn 25 XP
          handleEarnXp(25);
        }
        return { ...t, done: nextState };
      }
      return t;
    });
    setTasks(updated);
    localStorage.setItem('taskmate_tasks', JSON.stringify(updated));
  };

  const handleDeleteTask = (id: string) => {
    const filtered = tasks.filter(t => t.id !== id);
    setTasks(filtered);
    localStorage.setItem('taskmate_tasks', JSON.stringify(filtered));
  };

  // GPA Calculator Handlers
  const handleAddSubject = (newSubData: Omit<Subject, 'id' | 'userId'>) => {
    if (!currentUser) return;

    const newSub: Subject = {
      ...newSubData,
      id: 'subject-' + Date.now(),
      userId: currentUser.id
    };

    const newSubs = [newSub, ...subjects];
    setSubjects(newSubs);
    localStorage.setItem('taskmate_subjects', JSON.stringify(newSubs));

    // Earn 15 XP
    handleEarnXp(15);
  };

  const handleDeleteSubject = (id: string) => {
    const filtered = subjects.filter(s => s.id !== id);
    setSubjects(filtered);
    localStorage.setItem('taskmate_subjects', JSON.stringify(filtered));
  };

  // AI Chat Handlers
  const handleSendMessage = async (text: string) => {
    if (!text.trim() || chatLoading) return;

    const userMsg: Message = {
      sender: 'user',
      text: text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    const updatedMessages = [...chatMessages, userMsg];
    setChatMessages(updatedMessages);
    localStorage.setItem('taskmate_chats', JSON.stringify(updatedMessages));
    setChatLoading(true);

    try {
      const response = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: updatedMessages })
      });
      const data = await response.json();

      const aiMsg: Message = {
        sender: 'ai',
        text: data.text || "I'm checking Sprout's guide! Could you rephrase your question?",
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };

      const finalMessages = [...updatedMessages, aiMsg];
      setChatMessages(finalMessages);
      localStorage.setItem('taskmate_chats', JSON.stringify(finalMessages));
      
      // Earn 5 XP on AI queries
      handleEarnXp(5);
    } catch (err) {
      console.error("AI error:", err);
    } finally {
      setChatLoading(false);
    }
  };

  const handleClearChat = () => {
    setChatMessages([]);
    localStorage.removeItem('taskmate_chats');
  };

  // Pomodoro Handlers
  const handleCompletePomodoro = (minutes: number) => {
    if (!currentUser) return;

    const updatedUser = {
      ...currentUser,
      studyMinutes: currentUser.studyMinutes + minutes
    };
    saveUserData(updatedUser);
    handleEarnXp(40); // 40 XP reward on focus completion!
  };

  // Weekly Insight generator
  const handleGenerateInsight = async () => {
    if (isGeneratingInsight || !currentUser) return;

    setIsGeneratingInsight(true);
    let gpaValue = "0.00";
    if (subjects.length > 0) {
      const gradeScales: Record<string, number> = { 'A': 4.0, 'A-': 3.7, 'B+': 3.3, 'B': 3.0, 'B-': 2.7, 'C+': 2.3, 'C': 2.0, 'C-': 1.7, 'D': 1.0, 'F': 0.0 };
      let pts = 0; let creds = 0;
      subjects.forEach(s => { pts += (gradeScales[s.grade] ?? 4.0) * s.credits; creds += s.credits; });
      if (creds > 0) gpaValue = (pts / creds).toFixed(2);
    }

    try {
      const resp = await fetch('/api/ai/insight', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userName: currentUser.name,
          tasks: tasks,
          focusMinutes: currentUser.studyMinutes,
          gpa: gpaValue
        })
      });
      const data = await resp.json();
      setInsightReport(data.text);
      handleEarnXp(30); // Earn 30 XP on review!
    } catch (err) {
      console.error(err);
      setInsightReport("No internet or Gemini error. Please add your GEMINI_API_KEY under panel.");
    } finally {
      setIsGeneratingInsight(false);
    }
  };

  // Dynamic Hour Greeting helper
  const getGreeting = () => {
    const hours = new Date().getHours();
    if (hours < 12) return 'Good Morning';
    if (hours < 18) return 'Good Afternoon';
    return 'Good Evening';
  };

  // Dynamic calculations for home counters exactly matching Mockup numbers
  const totalCount = tasks.length;
  const overdueCount = tasks.filter(t => !t.done && new Date(t.dueDate) < new Date()).length;
  const doneCount = tasks.filter(t => t.done).length;
  const focusMin = currentUser?.studyMinutes || 0;

  if (!currentUser) {
    return <AuthView onAuthSuccess={(user) => {
      setCurrentUser(user);
      localStorage.setItem('taskmate_current_user', JSON.stringify(user));
    }} />;
  }

  return (
    <div className="min-h-screen bg-slate-50/50 pb-20 flex flex-col items-center">
      
      {/* Central Screen framed box resembling phone view */}
      <div className="w-full max-w-md bg-slate-50 min-h-screen relative shadow-2xl flex flex-col">
        
        {/* Main Header / Status bar mimicking top clock */}
        <div className="p-4 flex justify-between items-center bg-white border-b border-slate-100">
          <span className="text-xs font-bold text-slate-700">10:02 AM</span>
          <span className="text-xs text-slate-400 font-bold tracking-wider">Carrier 5G</span>
        </div>

        {/* Dynamic content canvas based on Active navigation */}
        <div className="p-5 flex-grow">
          {activeTab === 'dashboard' && (
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="space-y-6 text-left"
            >
              {/* Logo Center */}
              <div className="text-center pb-2">
                <h1 className="text-3xl font-black text-slate-800 tracking-tight" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
                  TaskMate
                </h1>
              </div>

              {/* Sprout Companion progress card */}
              <CompanionCard 
                xp={currentUser.xp} 
                level={currentUser.level} 
                name={currentUser.name} 
                onInteract={() => handleEarnXp(5)}
              />

              {/* "Good Morning Ali" Greeting exactly matching image */}
              <div>
                <h2 className="text-2xl font-black text-slate-800 tracking-tight" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
                  {getGreeting()}, {currentUser.name} ☀️
                </h2>
              </div>

              {/* Grid block metric boxes matching Mockup 1 heights and styles */}
              <div id="metrics-grid" className="grid grid-cols-2 gap-3 pb-2">
                
                {/* Total */}
                <div className="bg-white p-4 rounded-3xl shadow-sm border border-slate-100 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-2xl bg-sky-50 flex items-center justify-center text-sky-500">
                    <ClipboardList size={22} />
                  </div>
                  <div>
                    <p className="text-2xl font-black text-slate-800 tracking-tight">{totalCount}</p>
                    <p className="text-[10px] text-slate-400 font-bold uppercase">Total</p>
                  </div>
                </div>

                {/* Overdue */}
                <div className="bg-white p-4 rounded-3xl shadow-sm border border-slate-100 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-2xl bg-rose-50 flex items-center justify-center text-rose-500">
                    <Info size={22} />
                  </div>
                  <div>
                    <p className="text-2xl font-black text-slate-800 tracking-tight">{overdueCount}</p>
                    <p className="text-[10px] text-slate-400 font-bold uppercase">Overdue</p>
                  </div>
                </div>

                {/* Done */}
                <div className="bg-white p-4 rounded-3xl shadow-sm border border-slate-100 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-500">
                    <CheckCircle size={22} className="fill-emerald-50" />
                  </div>
                  <div>
                    <p className="text-2xl font-black text-slate-800 tracking-tight">{doneCount}</p>
                    <p className="text-[10px] text-slate-400 font-bold uppercase">Done</p>
                  </div>
                </div>

                {/* Focus Minutes */}
                <div className="bg-white p-4 rounded-3xl shadow-sm border border-slate-100 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-500">
                    <Timer size={22} />
                  </div>
                  <div>
                    <p className="text-2xl font-black text-slate-800 tracking-tight">{focusMin}m</p>
                    <p className="text-[10px] text-slate-400 font-bold uppercase">Focus</p>
                  </div>
                </div>

              </div>

              {/* Action grid rows from Image 1 */}
              <div className="grid grid-cols-3 gap-2.5">
                
                {/* Add Task Quick Trigger */}
                <button 
                  onClick={() => setActiveTab('tasks')}
                  className="p-3 bg-fuchsia-50 hover:bg-fuchsia-100 border border-fuchsia-100 rounded-2xl flex flex-col items-center gap-1.5 transition-all text-fuchsia-700 shadow-xs cursor-pointer active:scale-95"
                >
                  <Plus size={20} className="text-fuchsia-600 bg-fuchsia-200/50 p-1 rounded-full stroke-[3]" />
                  <span className="text-[10px] font-bold">New Task</span>
                </button>

                {/* Pomodoro Quick Trigger */}
                <button 
                  onClick={() => setActiveTab('pomodoro')}
                  className="p-3 bg-teal-50 hover:bg-teal-100 border border-teal-100 rounded-2xl flex flex-col items-center gap-1.5 transition-all text-teal-700 shadow-xs cursor-pointer active:scale-95"
                >
                  <Play size={20} className="text-teal-600 bg-teal-200/50 p-1.5 rounded-full fill-teal-600" />
                  <span className="text-[10px] font-bold truncate">Start Pomodoro</span>
                </button>

                {/* AI advice trigger */}
                <button 
                  onClick={() => setActiveTab('chat')}
                  className="p-3 bg-amber-50 hover:bg-amber-100 border border-amber-100 rounded-2xl flex flex-col items-center gap-1.5 transition-all text-amber-700 shadow-xs cursor-pointer active:scale-95"
                >
                  <Bot size={20} className="text-amber-600" />
                  <span className="text-[10px] font-bold">Ask AI</span>
                </button>

              </div>

              {/* Weekly AI Insight card matching Screenshot 1 bottom */}
              <div className="bg-white rounded-[32px] p-6 shadow-sm border border-slate-100 text-left space-y-4">
                <div className="flex items-center gap-2">
                  <span className="text-3xl">🧠</span>
                  <h3 className="text-lg font-black text-slate-800 tracking-tight" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
                    Weekly AI Insight
                  </h3>
                </div>

                <p className="text-xs text-slate-500 font-medium leading-relaxed">
                  Get a personalized weekly report from your AI coach — based on your task completions, academic GPA records, and Pomodoro focus time.
                </p>

                <button 
                  onClick={handleGenerateInsight}
                  disabled={isGeneratingInsight}
                  className="w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 shadow-sm cursor-pointer active:scale-95"
                >
                  {isGeneratingInsight ? (
                    <>
                      <Loader2 className="animate-spin" size={14} /> Generating Insights...
                    </>
                  ) : (
                    <>
                      ★ Generate My Insight
                    </>
                  )}
                </button>
              </div>

            </motion.div>
          )}

          {activeTab === 'tasks' && (
            <TasksView 
              tasks={tasks}
              onAddTask={handleAddTask}
              onToggleTask={handleToggleTask}
              onDeleteTask={handleDeleteTask}
            />
          )}

          {activeTab === 'pomodoro' && (
            <PomodoroView onCompleteSession={handleCompletePomodoro} />
          )}

          {activeTab === 'gpa' && (
            <GpaView 
              subjects={subjects}
              onAddSubject={handleAddSubject}
              onDeleteSubject={handleDeleteSubject}
            />
          )}

          {activeTab === 'chat' && (
            <AiChatView 
              messages={chatMessages}
              onSendMessage={handleSendMessage}
              onClearChat={handleClearChat}
              isLoading={chatLoading}
            />
          )}

          {activeTab === 'study_hub' && (
            <StudyHubView onEarnXp={handleEarnXp} />
          )}

          {activeTab === 'profile' && (
            <ProfileView 
              user={currentUser}
              onConnectCalendar={() => {
                alert("Simulated integration: Connect Google Calendar requested! To link, configure your Workspace credentials, or toggle standard mock syncing.");
              }}
              onLogout={() => {
                localStorage.removeItem('taskmate_current_user');
                setCurrentUser(null);
                setActiveTab('dashboard');
              }}
            />
          )}
        </div>

        {/* Bottom Tab Bar navigation exactly from mockup images */}
        <div id="bottom-tabbar" className="fixed bottom-0 max-w-md w-full bg-white/95 backdrop-blur-md border-t border-slate-200/80 p-2 py-3 grid grid-cols-7 text-center rounded-t-3xl shadow-lg z-40">
          
          {/* Dashboard */}
          <button 
            onClick={() => setActiveTab('dashboard')}
            className={`flex flex-col items-center gap-1 cursor-pointer transition-transform duration-200 active:scale-90 ${
              activeTab === 'dashboard' ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
            }`}
          >
            <LayoutGrid size={18} className={activeTab === 'dashboard' ? 'stroke-[2.5]' : 'stroke-2'} />
            <span className="text-[9px] font-bold">Home</span>
          </button>

          {/* Tasks */}
          <button 
            onClick={() => setActiveTab('tasks')}
            className={`flex flex-col items-center gap-1 cursor-pointer transition-transform duration-200 active:scale-90 ${
              activeTab === 'tasks' ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
            }`}
          >
            <ClipboardList size={18} className={activeTab === 'tasks' ? 'stroke-[2.5]' : 'stroke-2'} />
            <span className="text-[9px] font-bold">Tasks</span>
          </button>

          {/* Pomodoro */}
          <button 
            onClick={() => setActiveTab('pomodoro')}
            className={`flex flex-col items-center gap-1 cursor-pointer transition-transform duration-200 active:scale-90 ${
              activeTab === 'pomodoro' ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
            }`}
          >
            <Timer size={18} className={activeTab === 'pomodoro' ? 'stroke-[2.5]' : 'stroke-2'} />
            <span className="text-[9px] font-bold">Timer</span>
          </button>

          {/* GPA Calc */}
          <button 
            onClick={() => setActiveTab('gpa')}
            className={`flex flex-col items-center gap-1 cursor-pointer transition-transform duration-200 active:scale-90 ${
              activeTab === 'gpa' ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
            }`}
          >
            <Calculator size={18} className={activeTab === 'gpa' ? 'stroke-[2.5]' : 'stroke-2'} />
            <span className="text-[9px] font-bold">GPA Calc</span>
          </button>

          {/* AI Chat */}
          <button 
            onClick={() => setActiveTab('chat')}
            className={`flex flex-col items-center gap-1 cursor-pointer transition-transform duration-200 active:scale-90 ${
              activeTab === 'chat' ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
            }`}
          >
            <MessageSquare size={18} className={activeTab === 'chat' ? 'stroke-[2.5]' : 'stroke-2'} />
            <span className="text-[9px] font-bold">AI Chat</span>
          </button>

          {/* Study Hub */}
          <button 
            onClick={() => setActiveTab('study_hub')}
            className={`flex flex-col items-center gap-1 cursor-pointer transition-transform duration-200 active:scale-90 ${
              activeTab === 'study_hub' ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
            }`}
          >
            <BookOpen size={18} className={activeTab === 'study_hub' ? 'stroke-[2.5]' : 'stroke-2'} />
            <span className="text-[9px] font-bold">Study Hub</span>
          </button>

          {/* Profile */}
          <button 
            onClick={() => setActiveTab('profile')}
            className={`flex flex-col items-center gap-1 cursor-pointer transition-transform duration-200 active:scale-90 ${
              activeTab === 'profile' ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
            }`}
          >
            <UserIcon size={18} className={activeTab === 'profile' ? 'stroke-[2.5]' : 'stroke-2'} />
            <span className="text-[9px] font-bold">Profile</span>
          </button>

        </div>

      </div>

      {/* AI WEEKLY REPORT INSIGHT FULL-SCREEN MODAL */}
      <AnimatePresence>
        {insightReport && (
          <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-white rounded-3xl w-full max-w-sm p-6 shadow-xl border border-slate-100 flex flex-col max-h-[80vh]"
            >
              <div className="flex justify-between items-center mb-4 pb-2 border-b border-slate-100 flex-shrink-0">
                <h4 className="text-lg font-extrabold text-indigo-950 flex items-center gap-1.5" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
                  <Sparkles size={18} className="text-indigo-600" /> Weekly AI Insights
                </h4>
                <button 
                  onClick={() => setInsightReport(null)}
                  className="p-1 text-slate-400 hover:text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-full transition-all cursor-pointer"
                >
                  <X size={15} />
                </button>
              </div>

              {/* MD output summary scroll */}
              <div className="flex-grow overflow-y-auto pr-1 text-left whitespace-pre-wrap leading-relaxed text-xs sm:text-sm text-slate-700 font-medium">
                {insightReport}
              </div>

              <div className="pt-4 mt-2 border-t border-slate-150 flex-shrink-0">
                <button 
                  onClick={() => setInsightReport(null)}
                  className="w-full py-3 bg-indigo-600 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-all shadow-xs cursor-pointer"
                >
                  Acknowledge Report (+30 XP)
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
}
