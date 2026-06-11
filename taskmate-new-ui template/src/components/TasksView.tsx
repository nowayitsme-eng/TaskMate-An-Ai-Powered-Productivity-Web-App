import React, { useState } from 'react';
import { Calendar, Tag, Trash2, Plus, Sparkles, CheckCircle, Circle, Briefcase, FileText } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Task } from '../types';

interface TasksViewProps {
  tasks: Task[];
  onAddTask: (task: Omit<Task, 'id' | 'createdAt' | 'userId'>) => void;
  onToggleTask: (id: string) => void;
  onDeleteTask: (id: string) => void;
}

export default function TasksView({ tasks, onAddTask, onToggleTask, onDeleteTask }: TasksViewProps) {
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('maths');
  const [type, setType] = useState('Exam');
  const [dueDate, setDueDate] = useState('2026-06-17');
  const [priority, setPriority] = useState<'low' | 'medium' | 'high'>('medium');
  const [activeFilter, setActiveFilter] = useState<'all' | 'today' | 'high' | 'medium' | 'low'>('all');
  
  const [showAddForm, setShowAddForm] = useState(true);

  const categories = [
    { value: 'maths', label: 'Maths' },
    { value: 'science', label: 'Science' },
    { value: 'exam', label: 'Exam' },
    { value: 'languages', label: 'Languages' },
    { value: 'coding', label: 'Coding' },
    { value: 'health', label: 'Health' },
    { value: 'design', label: 'Design' }
  ];

  const types = [
    { value: 'Task', label: 'Task' },
    { value: 'Lecture', label: 'Lecture' },
    { value: 'Revision', label: 'Revision' },
    { value: 'Exam', label: 'Exam' },
    { value: 'Assignment', label: 'Assignment' },
    { value: 'Quiz', label: 'Quiz' }
  ];

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim()) return;

    onAddTask({
      description: description.trim(),
      category,
      type,
      dueDate,
      priority,
      done: false
    });

    setDescription('');
    // Keep form readable, add some fun micro feedback
  };

  const getPriorityStyle = (p: 'low' | 'medium' | 'high') => {
    switch (p) {
      case 'low': return 'bg-emerald-50 text-emerald-600 border-emerald-100 hover:bg-emerald-100/70';
      case 'medium': return 'bg-amber-50 text-amber-600 border-amber-100 hover:bg-amber-100/70';
      case 'high': return 'bg-rose-50 text-rose-600 border-rose-100 hover:bg-rose-100/70';
    }
  };

  const filteredTasks = tasks.filter(task => {
    if (activeFilter === 'all') return true;
    if (activeFilter === 'today') {
      const todayStr = new Date().toISOString().split('T')[0];
      return task.dueDate === todayStr;
    }
    return task.priority === activeFilter;
  });

  return (
    <div id="tasks-manager-container" className="space-y-6">
      {/* Top Header */}
      <div className="flex justify-between items-center bg-white p-3 rounded-2xl shadow-xs border border-slate-100">
        <h2 className="text-xl font-bold flex items-center gap-2 text-slate-800">
          <Briefcase size={20} className="text-indigo-600" />
          Task Manager
        </h2>
        <button 
          onClick={() => setShowAddForm(!showAddForm)}
          className="p-2 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded-xl transition-all font-medium text-xs flex items-center gap-1.5"
        >
          {showAddForm ? "Hide Editor" : "Quick Add Form"}
        </button>
      </div>

      {/* Task Creation Card */}
      <AnimatePresence>
        {showAddForm && (
          <motion.div 
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-4"
          >
            <form onSubmit={handleCreate} className="space-y-4">
              {/* Task Description */}
              <div className="flex gap-2">
                <input 
                  type="text" 
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Task description (e.g. Maths Exam Prep)"
                  className="flex-grow px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                />
                <button 
                  type="submit"
                  className="bg-indigo-600 hover:bg-indigo-700 text-white p-3 rounded-xl transition-colors shadow-sm cursor-pointer flex items-center justify-center"
                >
                  <Sparkles size={18} />
                </button>
              </div>

              {/* Category selector */}
              <div>
                <label className="block text-xs font-semibold text-slate-500 mb-1.5">Category</label>
                <select 
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-700 text-sm focus:border-indigo-500 focus:outline-none focus:ring-0 cursor-pointer"
                >
                  {categories.map(c => (
                    <option key={c.value} value={c.value}>{c.label}</option>
                  ))}
                </select>
              </div>

              {/* Dual row for type and due date */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-500 mb-1.5">Select Type</label>
                  <select 
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-700 text-sm focus:border-indigo-500 focus:outline-none cursor-pointer"
                  >
                    {types.map(t => (
                      <option key={t.value} value={t.value}>{t.label}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-500 mb-1.5">Select Due Date</label>
                  <div className="relative">
                    <input 
                      type="date" 
                      value={dueDate}
                      onChange={(e) => setDueDate(e.target.value)}
                      className="w-full pl-4 pr-10 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-700 text-sm focus:border-indigo-500 focus:outline-none cursor-pointer"
                    />
                    <span className="absolute inset-y-0 right-0 flex items-center pr-3 text-slate-400 pointer-events-none">
                      <Calendar size={16} />
                    </span>
                  </div>
                </div>
              </div>

              {/* Priority Row selectors */}
              <div>
                <label className="block text-xs font-semibold text-slate-500 mb-2">Priority</label>
                <div className="grid grid-cols-3 gap-2">
                  {(['low', 'medium', 'high'] as const).map(p => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => setPriority(p)}
                      className={`py-2 px-3 border text-xs font-bold rounded-xl transition-all capitalize ${
                        priority === p 
                          ? p === 'low' 
                            ? 'bg-emerald-500 text-white border-emerald-500 shadow-xs' 
                            : p === 'medium'
                            ? 'bg-amber-500 text-white border-amber-500 shadow-xs'
                            : 'bg-rose-500 text-white border-rose-500 shadow-xs'
                          : getPriorityStyle(p)
                      }`}
                    >
                      {p === 'low' && '↕️ '}
                      {p === 'medium' && '🖐️ '}
                      {p === 'high' && '🔥 '}
                      {p}
                    </button>
                  ))}
                </div>
              </div>
            </form>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Filter Options Pills */}
      <div id="filter-pills" className="flex items-center gap-1.5 overflow-x-auto py-1 scrollbar-none">
        {(['all', 'today', 'high', 'medium', 'low'] as const).map(f => (
          <button
            key={f}
            onClick={() => setActiveFilter(f)}
            className={`px-4 py-1.5 text-xs font-semibold rounded-full border transition-all truncate cursor-pointer ${
              activeFilter === f 
                ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm' 
                : 'bg-white text-slate-500 border-slate-200 hover:bg-slate-50'
            }`}
          >
            {f === 'all' && 'All'}
            {f === 'today' && 'Today'}
            {f === 'high' && '🔥 High'}
            {f === 'medium' && '🖐️ Medium'}
            {f === 'low' && '↕️ Low'}
          </button>
        ))}
      </div>

      {/* Task List items */}
      <div className="space-y-3">
        {filteredTasks.length === 0 ? (
          <div className="bg-slate-50 border border-dashed border-slate-200 rounded-2xl p-8 text-center text-slate-500 text-sm">
            No tracked tasks found in category / priority select. Click the form to input your exam prep tasks!
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-3">
            {filteredTasks.map(task => (
              <motion.div 
                key={task.id}
                layout
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                className={`bg-white p-4 rounded-2xl shadow-xs border border-slate-100 flex items-start gap-3 transition-opacity ${
                  task.done ? 'opacity-80' : ''
                }`}
              >
                {/* Custom Checkbox Toggle */}
                <button 
                  onClick={() => onToggleTask(task.id)}
                  className="mt-1 text-indigo-500 hover:text-indigo-700 transition-colors focus:outline-none"
                >
                  {task.done ? (
                    <CheckCircle size={22} className="text-emerald-500 fill-emerald-50" />
                  ) : (
                    <Circle size={22} className="text-slate-300" />
                  )}
                </button>

                {/* Info details */}
                <div className="flex-grow min-w-0">
                  <h4 className={`text-sm font-bold text-slate-800 truncate ${
                    task.done ? 'line-through text-slate-400 font-normal' : ''
                  }`}>
                    {task.description}
                  </h4>
                  
                  {/* Category and Type tags */}
                  <div className="flex items-center gap-1.5 flex-wrap mt-1">
                    <span className="bg-slate-100 text-slate-500 text-[10px] font-bold px-2 py-0.5 rounded-md uppercase">
                      {task.category}
                    </span>
                    <span className="bg-indigo-50 text-indigo-600 text-[10px] font-bold px-2 py-0.5 rounded-md">
                      {task.type}
                    </span>

                    {/* Short priority micro label */}
                    <span className={`text-[9px] font-extrabold px-1.5 py-0.5 rounded-md ${
                      task.priority === 'high' 
                        ? 'bg-rose-50 text-rose-500' 
                        : task.priority === 'medium'
                        ? 'bg-amber-50 text-amber-500'
                        : 'bg-emerald-50 text-emerald-500'
                    }`}>
                      {task.priority.toUpperCase()}
                    </span>
                  </div>

                  {/* Due Date block */}
                  <div className="flex items-center gap-1 text-[11px] text-slate-400 mt-2 font-medium">
                    <Calendar size={12} />
                    <span>
                      {new Date(task.dueDate).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric'
                      })}
                    </span>
                  </div>
                </div>

                {/* Sparkle boost for AI integration */}
                <button 
                  title="Study helper tips for this task"
                  onClick={() => alert(`Here is an AI study tip for: "${task.description}"!\n\nUse the Study Hub's Flashcards mode to test your understanding of ${task.category} topics using high-efficiency spaced intervals!`)}
                  className="opacity-40 hover:opacity-100 p-1.5 text-slate-400 hover:text-indigo-600 rounded-lg transition-all"
                >
                  <Sparkles size={16} />
                </button>

                {/* Delete task button */}
                <button 
                  onClick={() => onDeleteTask(task.id)}
                  className="p-1.5 text-slate-300 hover:text-rose-500 rounded-lg hover:bg-rose-50/50 transition-colors"
                >
                  <Trash2 size={16} />
                </button>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      {/* Floating Add trigger logic */}
      {!showAddForm && (
        <div className="flex justify-end pr-2 pt-2">
          <button 
            type="button"
            onClick={() => {
              setShowAddForm(true);
              // Scroll gracefully
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
            className="w-12 h-12 rounded-full bg-indigo-600 text-white flex items-center justify-center shadow-lg hover:bg-slate-800 transition-colors cursor-pointer"
          >
            <Plus size={24} />
          </button>
        </div>
      )}
    </div>
  );
}
