import React, { useState } from 'react';
import { Calculator, Plus, Trash2, GraduationCap, Percent } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Subject } from '../types';

interface GpaViewProps {
  subjects: Subject[];
  onAddSubject: (subject: Omit<Subject, 'id' | 'userId'>) => void;
  onDeleteSubject: (id: string) => void;
}

export default function GpaView({ subjects, onAddSubject, onDeleteSubject }: GpaViewProps) {
  const [subjectName, setSubjectName] = useState('');
  const [grade, setGrade] = useState('A');
  const [credits, setCredits] = useState(3);

  const gradeScales: Record<string, number> = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D': 1.0,
    'F': 0.0
  };

  const calculateCumulativeGpa = () => {
    if (subjects.length === 0) return { gpa: '0.00', totalCredits: 0 };

    let totalPoints = 0;
    let totalCredits = 0;

    subjects.forEach(sub => {
      const scaleValue = gradeScales[sub.grade] ?? 4.0;
      totalPoints += scaleValue * sub.credits;
      totalCredits += sub.credits;
    });

    if (totalCredits === 0) return { gpa: '0.00', totalCredits: 0 };
    const finalGpa = (totalPoints / totalCredits).toFixed(2);
    return { gpa: finalGpa, totalCredits };
  };

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!subjectName.trim()) return;

    onAddSubject({
      name: subjectName.trim(),
      grade,
      credits: Number(credits) || 1
    });

    setSubjectName('');
  };

  const { gpa, totalCredits } = calculateCumulativeGpa();

  return (
    <div id="gpa-calc-screen" className="space-y-6">
      {/* Visual Form Panel exactly matching screenshot 5 */}
      <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100/80 space-y-4">
        <h3 className="text-xl font-extrabold text-slate-800 flex items-center gap-2" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
          <Calculator className="text-indigo-600" />
          GPA Calculator
        </h3>

        <form onSubmit={handleCreate} className="space-y-4">
          {/* Subject Name Input */}
          <div>
            <label className="block text-xs font-bold text-slate-500 mb-1">Subject Name</label>
            <input 
              type="text" 
              value={subjectName}
              onChange={(e) => setSubjectName(e.target.value)}
              placeholder="e.g. Molecular Biology"
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
            />
          </div>

          {/* Side by side Grade and Credits selectors */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-500 mb-1">Grade</label>
              <select 
                value={grade}
                onChange={(e) => setGrade(e.target.value)}
                className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-700 text-sm focus:border-indigo-500 focus:outline-none cursor-pointer"
              >
                {Object.keys(gradeScales).map(g => (
                  <option key={g} value={g}>{g} ({gradeScales[g].toFixed(1)})</option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-500 mb-1">Credits</label>
              <input 
                type="number" 
                min={1}
                max={6}
                value={credits}
                onChange={(e) => setCredits(Math.max(1, Number(e.target.value)))}
                className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-800 text-sm focus:border-indigo-500 focus:outline-none"
              />
            </div>
          </div>

          <button 
            type="submit"
            className="w-full py-3.5 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-semibold transition-colors flex items-center justify-center gap-1.5 shadow-xs cursor-pointer active:scale-95"
          >
            Add Subject
          </button>
        </form>
      </div>

      {/* GPA Score Card matching screenshot 5 layout */}
      <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100/80 text-center space-y-4">
        <h4 className="text-sm font-extrabold text-slate-700">Your Cumulative GPA</h4>
        
        <div className="text-6xl font-black text-rose-500 tracking-tight select-none">
          {gpa}
        </div>

        <p className="text-xs text-slate-400 font-medium">
          Based on <span className="font-bold text-slate-700">{totalCredits.toFixed(1)}</span> credit hours
        </p>

        {subjects.length === 0 ? (
          <div className="text-xs text-slate-400 border-t border-slate-100 pt-4">
            No subjects added yet
          </div>
        ) : (
          <div className="border-t border-slate-150 pt-4 space-y-2">
            <h5 className="text-[11px] font-bold text-slate-400 text-left uppercase pl-1">Subjects List</h5>
            
            <div className="max-h-52 overflow-y-auto space-y-2 pr-1">
              {subjects.map(sub => {
                const gradePoints = gradeScales[sub.grade] ?? 4.0;
                return (
                  <div 
                    key={sub.id} 
                    className="flex justify-between items-center text-xs p-3 bg-slate-50/60 rounded-xl border border-slate-100"
                  >
                    <div className="text-left min-w-0">
                      <p className="font-bold text-slate-700 truncate">{sub.name}</p>
                      <p className="text-[10px] text-slate-400">{sub.credits} Credit Hours</p>
                    </div>

                    <div className="flex items-center gap-3 ml-2 flex-shrink-0">
                      <span className="bg-indigo-50 text-indigo-700 font-extrabold px-2.5 py-1 rounded-lg">
                        {sub.grade}
                      </span>
                      <button 
                        onClick={() => onDeleteSubject(sub.id)}
                        className="p-1.5 text-slate-300 hover:text-rose-500 rounded-md hover:bg-rose-50 transition-colors"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
