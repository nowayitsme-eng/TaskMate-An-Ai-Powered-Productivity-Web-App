import React, { useState, useRef, useEffect } from 'react';
import { Send, Bot, Trash2, HelpCircle, ArrowLeft, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { Message } from '../types';

interface AiChatViewProps {
  messages: Message[];
  onSendMessage: (text: string) => Promise<void>;
  onClearChat: () => void;
  isLoading: boolean;
}

export default function AiChatView({ messages, onSendMessage, onClearChat, isLoading }: AiChatViewProps) {
  const [inputText, setInputText] = useState('');
  const chatBottomRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    // Auto-scroll to lowest messages
    chatBottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || isLoading) return;

    onSendMessage(inputText.trim());
    setInputText('');
  };

  const sampleQuestions = [
    "What is the power of Spaced Repetition?",
    "Explain Muscle Growth scientifically.",
    "Draft a study schedule for Maths Exam.",
    "Give me active recall techniques."
  ];

  return (
    <div id="ai-chat-screen" className="flex flex-col h-[75vh] max-w-md mx-auto bg-slate-50 border border-slate-100 rounded-[32px] overflow-hidden shadow-sm relative">
      {/* Dynamic Back-Header matched with screenshot 3 */}
      <div className="flex justify-between items-center bg-white p-4 border-b border-slate-200/80">
        <div className="flex items-center gap-2.5">
          <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600">
            <Bot size={22} className="animate-bounce" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-800">AI Assistant</h3>
            <span className="text-[10px] font-bold text-emerald-500 flex items-center gap-1">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-ping" />
              Online Coach
            </span>
          </div>
        </div>

        <button 
          onClick={onClearChat}
          className="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-600 text-xs font-bold rounded-xl transition-all cursor-pointer"
        >
          Clear Chat
        </button>
      </div>

      {/* Message history layout */}
      <div className="flex-grow overflow-y-auto p-4 space-y-4">
        {messages.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center px-4 space-y-4">
            <div className="w-12 h-12 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-500">
              <Bot size={24} />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-700">Ask Sprout's Wise Mentor!</p>
              <p className="text-xs text-slate-400 mt-1 max-w-[240px]">
                Ask me whatever you need about exam questions, study formulas, or time management routines!
              </p>
            </div>
            
            {/* Quick help bubbles */}
            <div className="grid grid-cols-2 gap-2 max-w-xs pt-2">
              {sampleQuestions.map((q, i) => (
                <button
                  key={i}
                  onClick={() => onSendMessage(q)}
                  className="p-2.5 bg-white border border-slate-200 rounded-xl text-[11px] text-slate-600 hover:border-indigo-400 text-left transition-all active:scale-95"
                >
                  {q}
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            {messages.map((msg, index) => {
              const isAi = msg.sender === 'ai';
              return (
                <div 
                  key={index}
                  className={`flex items-start gap-2.5 ${isAi ? '' : 'flex-row-reverse'}`}
                >
                  {/* Miniature Avatar */}
                  <div className={`w-8 h-8 rounded-full flex-shrink-0 flex items-center justify-center text-xs font-bold ${
                    isAi ? 'bg-indigo-150 bg-indigo-100 text-indigo-600' : 'bg-slate-300 text-slate-700'
                  }`}>
                    {isAi ? <Bot size={14} /> : 'ME'}
                  </div>

                  {/* Body Bubble - Ai messages styled purple as in Screenshot 3 */}
                  <div className="max-w-[80%]">
                    <div className={`p-4 rounded-3xl text-sm ${
                      isAi 
                        ? 'bg-indigo-50 text-indigo-950 rounded-tl-none border border-indigo-100' 
                        : 'bg-white text-slate-800 rounded-tr-none border border-slate-200'
                    }`}>
                      <p className="whitespace-pre-line leading-relaxed text-xs sm:text-sm font-medium">{msg.text}</p>
                    </div>

                    {/* Timestamp under bubble */}
                    <p className={`text-[10px] text-slate-400 mt-1 px-1 font-medium ${isAi ? 'text-left' : 'text-right'}`}>
                      {msg.timestamp}
                    </p>
                  </div>
                </div>
              );
            })}

            {/* Waiting loader feedback if AI is thinking */}
            {isLoading && (
              <div className="flex items-start gap-2.5">
                <div className="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-500 animate-pulse">
                  <Bot size={14} />
                </div>
                <div className="bg-indigo-50 p-3 rounded-2xl rounded-tl-none border border-indigo-100 text-slate-500 text-xs flex items-center gap-2">
                  <Loader2 size={14} className="animate-spin text-indigo-600" />
                  Sprouty's coach is drafting insights...
                </div>
              </div>
            )}
            <div ref={chatBottomRef} />
          </div>
        )}
      </div>

      {/* Input row exactly matching Screenshot 3 */}
      <form onSubmit={handleSend} className="p-3 bg-white border-t border-slate-150/80 flex items-center gap-2">
        <input 
          type="text"
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder="Ask me anything..."
          disabled={isLoading}
          className="flex-grow px-4 py-3.5 bg-slate-50 border border-slate-200 rounded-full text-slate-800 placeholder-slate-400 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
        />
        <button 
          type="submit"
          disabled={isLoading || !inputText.trim()}
          className="w-11 h-11 rounded-full bg-indigo-600 text-white flex items-center justify-center shadow-sm hover:bg-slate-800 transition-colors cursor-pointer disabled:opacity-45 disabled:cursor-not-allowed"
        >
          <Send size={16} fill="white" />
        </button>
      </form>
    </div>
  );
}
