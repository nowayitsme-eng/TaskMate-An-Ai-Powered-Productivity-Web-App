export interface User {
  id: string;
  name: string;
  email: string;
  xp: number;
  level: number;
  badges: string[]; // badge IDs
  studyMinutes: number; // cumulative Pomodoro focus min
  streak: number; // current consecutive active days
  lastActiveDate?: string; // YYYY-MM-DD
}

export interface Task {
  id: string;
  userId: string;
  description: string;
  category: string; // e.g., "Maths", "Coding", "Health", etc.
  type: string; // e.g., "Exam", "Homework", "Project", "lecture", etc.
  dueDate: string; // YYYY-MM-DD
  priority: 'low' | 'medium' | 'high';
  done: boolean;
  createdAt: string;
}

export interface Subject {
  id: string;
  userId: string;
  name: string;
  grade: string; // "A", "A-", "B+", "B", etc.
  credits: number;
}

export interface Badge {
  id: string;
  title: string;
  description: string;
  icon: string; // Emoji or Lucide icon key
  requirementText: string;
  unlocked: boolean;
}

export interface Message {
  sender: 'user' | 'ai';
  text: string;
  timestamp: string;
}

export interface Flashcard {
  front: string;
  back: string;
}

export interface QuizQuestion {
  id: string;
  question: string;
  options: string[];
  correctAnswer: string; // Must match one of options exactly
  explanation: string;
}

export interface StudySetSummary {
  keyConcepts: string[];
  summaryText: string;
}

export interface StudySet {
  id: string;
  userId: string;
  sourceText: string;
  title: string;
  summary: StudySetSummary;
  flashcards: Flashcard[];
  quiz: QuizQuestion[];
  createdAt: string;
}

export interface ActivityDay {
  date: string; // YYYY-MM-DD
  intensity: number; // 0 to 4 (similar to GitHub Calendar)
  minutes: number;
}
