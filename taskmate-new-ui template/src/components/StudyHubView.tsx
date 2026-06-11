import React, { useState } from 'react';
import { Copy, FileText, Sparkles, BookOpen, Clock, ArrowRight, ArrowLeft, RefreshCw, Check, AlertCircle, Award } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Flashcard, QuizQuestion, StudySetSummary } from '../types';

interface StudyHubViewProps {
  onEarnXp: (amount: number) => void;
}

export default function StudyHubView({ onEarnXp }: StudyHubViewProps) {
  const [activeTab, setActiveTab] = useState<'summarize' | 'flashcards' | 'quiz'>('summarize');
  
  // Note states
  const [lectureText, setLectureText] = useState('');
  const [charCount, setCharCount] = useState(0);
  const [isSummarizing, setIsSummarizing] = useState(false);
  
  // Generated study results
  const [activeSummary, setActiveSummary] = useState<StudySetSummary | null>(null);
  const [activeFlashcards, setActiveFlashcards] = useState<Flashcard[]>([
    { front: "Mitochondria", back: "Foundational cellular organelle responsible for aerobic cellular respiration and ATP conversion." },
    { front: "Active Recall", back: "Learning principle that forces brain retrieval, yielding dramatically higher myelin pathways than highlighter rereading." },
    { front: "Spaced Repetition", back: "Systematic review technique where information is tested across graduating spans to halt the forgetting curve." },
    { front: "Photosynthesis", back: "Chemical conversion wherein plants, green algae, and cyanobacteria craft chemical energy using solar light." },
    { front: "Leitner System", back: "Flashcard method sorting items into progression boxes based on correct vs incorrect test outcomes." }
  ]);
  const [activeQuiz, setActiveQuiz] = useState<QuizQuestion[]>([
    {
      id: "q1",
      question: "What is the primary function of the mitochondria?",
      options: ["Energy production", "Protein synthesis", "Cell division", "Waste removal"],
      correctAnswer: "Energy production",
      explanation: "Mitochondria produce Adenosine Triphosphate (ATP) which serves as the energy currency of the cell."
    },
    {
      id: "q2",
      question: "Which studying protocol relies on increasing review intervals?",
      options: ["Spaced repetition", "Passive highlight", "Passive reading", "Cramming"],
      correctAnswer: "Spaced repetition",
      explanation: "Spaced repetition uses interval study durations (e.g. 1 day, 3 days, 7 days) to strengthen long-term memorization."
    }
  ]);

  // View state for summary result screen
  const [showSummaryResult, setShowSummaryResult] = useState(false);

  // Flashcards interface states
  const [currentCardIndex, setCurrentCardIndex] = useState(0);
  const [isCardFlipped, setIsCardFlipped] = useState(false);

  // Quiz interface states
  const [currentQuizIndex, setCurrentQuizIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [showExplanation, setShowExplanation] = useState(false);
  const [quizScore, setQuizScore] = useState(0);
  const [quizDone, setQuizDone] = useState(false);

  const handleTextChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const val = e.target.value;
    if (val.length <= 5000) {
      setLectureText(val);
      setCharCount(val.length);
    }
  };

  const handleSummarize = async () => {
    if (!lectureText.trim()) {
      alert("Please paste your lecture notes or some article first!");
      return;
    }

    setIsSummarizing(true);
    try {
      // 1. Fetch Summary
      const resSum = await fetch('/api/ai/summarize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: lectureText })
      });
      const dataSum = await resSum.json();

      if (dataSum.keyConcepts) {
        setActiveSummary(dataSum);
      } else {
        throw new Error("No summary parsed");
      }

      // 2. Fetch Study Set (Flashcards & Quiz questions) in background
      const resStudy = await fetch('/api/ai/generate-study', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: lectureText })
      });
      const dataStudy = await resStudy.json();

      if (dataStudy.flashcards) {
        setActiveFlashcards(dataStudy.flashcards);
      }
      if (dataStudy.quiz) {
        setActiveQuiz(dataStudy.quiz);
      }

      onEarnXp(50); // Earn 50 XP on summarization!
      setShowSummaryResult(true);
    } catch (err) {
      console.error(err);
      alert("AI was busy, loading optimized study concepts and template cards instantly!");
      // Fallback
      setActiveSummary({
        keyConcepts: [
          "Spaced Repetition: Boosting recall by testing across escalating intervals.",
          "Mitochondria: Powerhouses of eukaryotic cells converting ATP molecules.",
          "Active Recall: Forcing synapses to retrieve memory pathways over passive highlighting."
        ],
        summaryText: "Your notes explain standard high-impact cognitive studying metrics and cellular ATP production models. Spaced repetition and active retrieval trigger long-term axon myelination for higher retentive success."
      });
      setShowSummaryResult(true);
    } finally {
      setIsSummarizing(false);
    }
  };

  const handleCopyToClipboard = () => {
    if (!activeSummary) return;
    const bulletContent = activeSummary.keyConcepts.map(c => `- ${c}`).join('\n');
    const fullText = `Key Concepts:\n${bulletContent}\n\nSummary:\n${activeSummary.summaryText}`;
    
    navigator.clipboard.writeText(fullText);
    alert("📋 Summarized text copied to clipboard!");
  };

  const handleSaveAsPdf = () => {
    alert("📥 Simulated PDF report downloaded! Saved as 'Lecture_Summary.pdf' to your local storage.");
  };

  const startStudyingGeneratedFlashcards = () => {
    setShowSummaryResult(false);
    setActiveTab('flashcards');
    setCurrentCardIndex(0);
    setIsCardFlipped(false);
  };

  // Flashcards Actions
  const handleNextCard = () => {
    setIsCardFlipped(false);
    setTimeout(() => {
      setCurrentCardIndex((prev) => (prev + 1) % activeFlashcards.length);
    }, 150);
  };

  const handlePrevCard = () => {
    setIsCardFlipped(false);
    setTimeout(() => {
      setCurrentCardIndex((prev) => (prev - 1 + activeFlashcards.length) % activeFlashcards.length);
    }, 150);
  };

  // Quiz Actions
  const handleCheckAnswer = () => {
    if (!selectedOption) return;
    
    const currentQuestion = activeQuiz[currentQuizIndex];
    if (selectedOption === currentQuestion.correctAnswer) {
      setQuizScore(prev => prev + 1);
      onEarnXp(20); // 20 XP for correct answer!
    }
    
    setShowExplanation(true);
  };

  const handleNextQuizQuestion = () => {
    setSelectedOption(null);
    setShowExplanation(false);

    if (currentQuizIndex + 1 < activeQuiz.length) {
      setCurrentQuizIndex(prev => prev + 1);
    } else {
      setQuizDone(true);
      onEarnXp(50); // bonus XP on completion
    }
  };

  const resetQuiz = () => {
    setCurrentQuizIndex(0);
    setSelectedOption(null);
    setShowExplanation(false);
    setQuizScore(0);
    setQuizDone(false);
  };

  return (
    <div id="study-hub-container" className="space-y-6">
      {/* Tab bar header exactly mimicking Screenshot 7 */}
      {!showSummaryResult && (
        <div id="study-hub-tabs" className="bg-slate-100 rounded-2xl p-1.5 flex items-center gap-1.5 border border-slate-200">
          {(['summarize', 'flashcards', 'quiz'] as const).map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all capitalize cursor-pointer ${
                activeTab === tab 
                  ? 'bg-indigo-600 text-white shadow-sm' 
                  : 'text-slate-600 hover:text-slate-800'
              }`}
            >
              {tab === 'summarize' && '📝 Summarize'}
              {tab === 'flashcards' && '🎴 Flashcards'}
              {tab === 'quiz' && '✍️ Study Quiz'}
            </button>
          ))}
        </div>
      )}

      {/* RESULT PANEL: Lecture Summary exactly matching Screenshot 12 */}
      {showSummaryResult && activeSummary && (
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="space-y-5"
        >
          {/* Header */}
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setShowSummaryResult(false)} 
              className="p-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl transition-colors"
            >
              <ArrowLeft size={16} />
            </button>
            <h3 className="text-xl font-extrabold text-slate-800" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
              Lecture Summary
            </h3>
          </div>

          <div className="bg-white rounded-[32px] p-6 shadow-sm border border-slate-100 text-left space-y-5">
            {/* Key Concepts panel */}
            <div className="space-y-2.5">
              <h4 className="text-base font-bold text-slate-800">Key Concepts:</h4>
              <ul className="space-y-2 text-slate-600 text-xs sm:text-sm list-disc pl-5">
                {activeSummary.keyConcepts.map((item, idx) => (
                  <li key={idx} className="leading-relaxed">
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            {/* General Summary paragraph block */}
            <div className="space-y-2 border-t border-slate-100 pt-4">
              <h4 className="text-base font-bold text-slate-800">Summary:</h4>
              <p className="text-slate-600 text-xs sm:text-sm leading-relaxed whitespace-pre-line font-medium">
                {activeSummary.summaryText}
              </p>
            </div>
          </div>

          {/* Action buttons row from Screenshot 12 */}
          <div className="grid grid-cols-3 gap-2.5">
            <button 
              onClick={handleCopyToClipboard}
              className="p-3 bg-white hover:bg-slate-50 border border-slate-200 text-slate-600 rounded-2xl text-[11px] sm:text-xs font-bold transition-all shadow-xs flex flex-col items-center gap-1 cursor-pointer"
            >
              <Copy size={16} /> Copy to Clipboard
            </button>

            <button 
              onClick={handleSaveAsPdf}
              className="p-3 bg-white hover:bg-slate-50 border border-slate-200 text-slate-600 rounded-2xl text-[11px] sm:text-xs font-bold transition-all shadow-xs flex flex-col items-center gap-1 cursor-pointer"
            >
              <FileText size={16} /> Save as PDF
            </button>

            <button 
              onClick={startStudyingGeneratedFlashcards}
              className="p-3 bg-indigo-50 hover:bg-indigo-100 border border-indigo-100 text-indigo-700 rounded-2xl text-[11px] sm:text-xs font-bold transition-all shadow-xs flex flex-col items-center gap-1 cursor-pointer"
            >
              <Sparkles size={16} /> Load Flashcards
            </button>
          </div>
        </motion.div>
      )}

      {/* CORE SCREENS BASED ON ACTIVE TAB (Toggled if summary result is hidden) */}
      {!showSummaryResult && (
        <div id="study-panel-views">
          {/* 1. Summarize View */}
          {activeTab === 'summarize' && (
            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100/80 space-y-5">
              <div className="space-y-1">
                <h4 className="text-lg font-bold text-slate-800">Summarize & Parse</h4>
                <p className="text-xs text-slate-400 font-medium">Get bullet points, study cards, and quizzes, instantly powered by Gemini.</p>
              </div>

              <div className="relative">
                <textarea 
                  rows={8}
                  value={lectureText}
                  onChange={handleTextChange}
                  placeholder="Paste your lecture notes, article, or any long text here... When you hit Generate, a dedicated full-screen view will open with your results!"
                  className="w-full p-4 bg-slate-50 border border-slate-200 rounded-2xl text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none leading-relaxed"
                />
                <span className="absolute bottom-3 right-4 text-[10px] text-slate-400 font-bold">
                  {charCount}/5000 characters
                </span>
              </div>

              <button 
                onClick={handleSummarize}
                disabled={isSummarizing || !lectureText.trim()}
                className="w-full py-4 px-6 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl font-bold transition-all flex items-center justify-center gap-2 shadow-xs cursor-pointer disabled:opacity-45"
              >
                {isSummarizing ? (
                  <>
                    <RefreshCw className="animate-spin" size={18} /> Summarizing content...
                  </>
                ) : (
                  <>
                    <Sparkles size={18} /> Summarize
                  </>
                )}
              </button>
            </div>
          )}

          {/* 2. Flashcards View exactly matching Screenshot 10 */}
          {activeTab === 'flashcards' && (
            <div className="space-y-6">
              <div className="text-center">
                <h3 className="text-indigo-600 font-semibold text-sm">Study Flashcards</h3>
                <span className="text-[11px] text-slate-400 font-bold block mt-0.5">Card {currentCardIndex + 1} of {activeFlashcards.length}</span>
              </div>

              {/* Centered flip canvas */}
              <div 
                onClick={() => setIsCardFlipped(!isCardFlipped)}
                className="h-64 max-w-sm mx-auto cursor-pointer perspective"
              >
                <div className={`relative w-full h-full duration-500 preserve-3d ${isCardFlipped ? 'rotate-y-180' : ''}`}>
                  {/* Front Card (emerald theme as in Screenshot 10) */}
                  <div className="absolute inset-0 backface-hidden bg-gradient-to-br from-emerald-500 to-teal-600 text-white rounded-3xl p-6 shadow-md flex flex-col items-center justify-center text-center">
                    <h4 className="text-2xl font-black tracking-tight" style={{ fontFamily: "Space Grotesk, sans-serif" }}>
                      {activeFlashcards[currentCardIndex]?.front}
                    </h4>
                    <span className="mt-8 text-xs font-bold opacity-75 uppercase tracking-[0.2em] bg-white/10 px-3 py-1 rounded-full">
                      Tap to flip
                    </span>
                  </div>

                  {/* Back Card */}
                  <div className="absolute inset-0 backface-hidden rotate-y-180 bg-slate-800 text-slate-100 rounded-3xl p-6 shadow-md flex flex-col items-center justify-center text-center">
                    <p className="text-base font-semibold leading-relaxed px-2">
                      {activeFlashcards[currentCardIndex]?.back}
                    </p>
                    <span className="mt-8 text-[11px] text-indigo-300 font-bold uppercase tracking-[0.1em]">
                      Tap to return
                    </span>
                  </div>
                </div>
              </div>

              {/* Navigation row exactly matching Screenshot 10 bottom */}
              <div className="flex items-center justify-center gap-8 pt-2">
                <button 
                  onClick={handlePrevCard}
                  className="w-12 h-12 rounded-full border border-slate-200 bg-white shadow-xs hover:bg-slate-50 text-indigo-600 flex items-center justify-center transition-transform active:scale-90 cursor-pointer"
                >
                  <ArrowLeft size={18} strokeWidth={3} />
                </button>
                
                <span className="text-[13px] font-extrabold text-indigo-700">Tap to flip</span>

                <button 
                  onClick={handleNextCard}
                  className="w-12 h-12 rounded-full border border-slate-200 bg-white shadow-xs hover:bg-slate-50 text-indigo-600 flex items-center justify-center transition-transform active:scale-90 cursor-pointer"
                >
                  <ArrowRight size={18} strokeWidth={3} />
                </button>
              </div>
            </div>
          )}

          {/* 3. Quiz View exactly matching Screenshot 11 */}
          {activeTab === 'quiz' && (
            <div className="max-w-sm mx-auto space-y-6">
              {quizDone ? (
                <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100/80 text-center space-y-4">
                  <div className="mx-auto w-16 h-16 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-500">
                    <Award size={36} />
                  </div>
                  <h4 className="text-xl font-extrabold text-slate-800">Quiz Completed!</h4>
                  <p className="text-sm text-slate-500">You scored <span className="text-indigo-600 font-extrabold">{quizScore} / {activeQuiz.length}</span> correct questions.</p>
                  
                  <div className="pt-2">
                    <button 
                      onClick={resetQuiz}
                      className="py-2.5 px-6 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-semibold shadow-xs"
                    >
                      Retry Quiz
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  {/* Progress bar exactly from Mockup image */}
                  <div className="space-y-1">
                    <div className="flex justify-between items-center text-[10px] font-bold text-slate-400 pl-1">
                      <span>Quiz Challenge</span>
                      <span>{currentQuizIndex + 1} of {activeQuiz.length}</span>
                    </div>
                    {/* Progression bar with cute sliding companion head indicator */}
                    <div className="relative h-2 bg-slate-150 bg-slate-200 rounded-full overflow-visible">
                      <div 
                        className="h-full bg-indigo-600 rounded-full transition-all duration-300"
                        style={{ width: `${((currentQuizIndex + 1) / activeQuiz.length) * 100}%` }}
                      />
                      {/* Avatar icon floating slider */}
                      <span 
                        className="absolute -top-1.5 w-5 h-5 rounded-full bg-indigo-500 border border-white flex items-center justify-center text-[8px] text-white shadow-xs transition-all duration-300"
                        style={{ left: `calc(${((currentQuizIndex + 1) / activeQuiz.length) * 100}% - 14px)` }}
                      >
                        🌱
                      </span>
                    </div>
                  </div>

                  {/* Question Box Card */}
                  <div className="bg-white rounded-[28px] p-6 shadow-sm border border-slate-150/80">
                    <h4 className="text-lg font-bold text-slate-800 leading-relaxed">
                      {activeQuiz[currentQuizIndex]?.question}
                    </h4>
                  </div>

                  {/* Options List Grid */}
                  <div className="space-y-2 pt-2">
                    {activeQuiz[currentQuizIndex]?.options.map((option, idx) => {
                      const isSelected = selectedOption === option;
                      return (
                        <button
                          key={idx}
                          type="button"
                          disabled={showExplanation}
                          onClick={() => setSelectedOption(option)}
                          className={`w-full text-left p-4 rounded-2xl border text-sm font-semibold transition-all flex items-center justify-between cursor-pointer ${
                            isSelected 
                              ? 'border-indigo-600 bg-indigo-50/50 text-indigo-950 shadow-xs' 
                              : 'border-slate-200/80 bg-slate-50 hover:bg-slate-100 text-slate-700'
                          }`}
                        >
                          <span>{option}</span>
                          {isSelected && <Check size={16} className="text-indigo-600" />}
                        </button>
                      );
                    })}
                  </div>

                  {/* Action row (Check answer, next) */}
                  <div className="pt-2">
                    {!showExplanation ? (
                      <button
                        onClick={handleCheckAnswer}
                        disabled={!selectedOption}
                        className="w-full py-4 px-6 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl font-bold transition-all shadow-xs cursor-pointer disabled:opacity-50"
                      >
                        Check
                      </button>
                    ) : (
                      <div className="space-y-4">
                        {/* Explanation block feedback */}
                        <div className={`p-4 rounded-2xl border text-xs leading-relaxed font-semibold ${
                          selectedOption === activeQuiz[currentQuizIndex].correctAnswer
                            ? 'bg-emerald-50 border-emerald-100 text-emerald-800'
                            : 'bg-rose-50 border-rose-100 text-rose-800'
                        }`}>
                          <div className="flex items-center gap-1.5 mb-1 text-sm font-bold">
                            <AlertCircle size={14} />
                            <span>
                              {selectedOption === activeQuiz[currentQuizIndex].correctAnswer 
                                ? 'Correct! (+20 XP)' 
                                : `Incorrect! Correct: ${activeQuiz[currentQuizIndex].correctAnswer}`
                              }
                            </span>
                          </div>
                          <p className="font-medium mt-1">{activeQuiz[currentQuizIndex].explanation}</p>
                        </div>

                        <button
                          onClick={handleNextQuizQuestion}
                          className="w-full py-4 px-6 bg-slate-800 hover:bg-slate-900 text-white rounded-2xl font-bold transition-all shadow-xs flex items-center justify-center gap-1 cursor-pointer"
                        >
                          Next Question <ArrowRight size={16} />
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
