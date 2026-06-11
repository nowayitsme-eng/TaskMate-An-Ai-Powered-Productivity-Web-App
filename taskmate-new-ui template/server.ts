import express from "express";
import path from "path";
import { GoogleGenAI, Type } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

// Initialize Express
const app = express();
app.use(express.json());

const PORT = 3000;

// Lazy initialize Gemini client
let ai: GoogleGenAI | null = null;
function getGeminiClient(): GoogleGenAI {
  if (!ai) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.warn("WARNING: GEMINI_API_KEY environment variable is not set. Real AI responses will fall back to local interactive simulated responses with a prompt guide.");
    }
    ai = new GoogleGenAI({
      apiKey: apiKey || "MOCK_KEY",
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        },
      },
    });
  }
  return ai;
}

// 1. General AI Chat Endpoint
app.post("/api/ai/chat", async (req, res) => {
  const { messages, systemPrompt } = req.body;
  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: "messages array is required" });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "MY_GEMINI_API_KEY") {
    // Generate a beautiful smart offline simulation response
    const lastMsg = messages[messages.length - 1]?.text || "hello";
    const simResponse = getSimulatedChatResponse(lastMsg);
    return res.json({ text: simResponse });
  }

  try {
    const client = getGeminiClient();
    
    // Format messages for gemini-3.5-flash
    // We can map sender to 'user' or 'model'
    const contents = messages.map((m: any) => ({
      role: m.sender === "user" ? "user" : "model",
      parts: [{ text: m.text }]
    }));

    const response = await client.models.generateContent({
      model: "gemini-3.5-flash",
      contents: contents,
      config: {
        systemInstruction: systemPrompt || "You are a professional, motivating, and smart AI Assistant in the TaskMate student productivity app named TaskMate AI. You specialize in student life balance, study habits, quick learning formulas, scientific study methods (active recall, Leitner system, spaced repetition, Feynman technique), and Pomodoro time management. Keep answers focused, clean, clear, and bulleted where helpful.",
      }
    });

    res.json({ text: response.text });
  } catch (err: any) {
    console.error("Gemini API Error in /api/ai/chat:", err);
    res.status(500).json({ error: err.message || "Failed to generate AI response" });
  }
});

// 2. Weekly AI report / Insights generator
app.post("/api/ai/insight", async (req, res) => {
  const { userName, tasks, focusMinutes, gpa } = req.body;

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "MY_GEMINI_API_KEY") {
    // Mock robust insight text if not configured
    const mockInsight = `### Hello ${userName || 'Ali'}! Here is your Weekly TaskMate Coach Report 🧠

Great effort tracking your goals! Here is your productivity analytics based on your setup:
* **Task Competency**: You have tracked **${tasks?.length || 0} tasks**.
* **Concentration Quotient**: You focused for **${focusMinutes || 0} minutes** in the Pomodoro timer.
* **Academic Overview**: Your tracked GPA stands of **${gpa || '0.00'}**.

**💡 Actionable Advice from your Coach:**
1. **Try Spaced Repetition**: We noticed you have multiple tasks. Space them out 1-2 days apart rather than cramming!
2. **Pomodoro Sprints**: Aim to hit at least 3 Pomodoro sprints of 25 mins tomorrow to bolster your focus levels. 
3. **Active Recall**: Before studying, close your book and jot down 3 key concepts first to boost active recall.

*Configure your real GEMINI_API_KEY under Secrets to get professional, highly customized cognitive reports!*`;
    return res.json({ text: mockInsight });
  }

  try {
    const client = getGeminiClient();
    const prompt = `Generate a highly personalized, structured study insight and weekly coach report for user "${userName || 'Ali'}".
Here is their activity data:
- Tracked tasks count: ${tasks?.length || 0} tasks (${JSON.stringify(tasks || [])})
- Pomodoro concentration focus time: ${focusMinutes || 0} minutes
- Current tracked GPA: ${gpa || "0.00"}

Identify their streak, focus level, and prioritize academic advice. Format it in Markdown with bullet points! Do not output any meta comments. Make it motivating, crisp, and under 250 words.`;

    const response = await client.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        systemInstruction: "You are the TaskMate AI Head Coach. You are wise, enthusiastic, and provide precise, actionable student-focused feedback based on data."
      }
    });

    res.json({ text: response.text });
  } catch (err: any) {
    console.error("Gemini API Error in /api/ai/insight:", err);
    res.status(500).json({ error: err.message || "Failed to generate weekly insight" });
  }
});

// 3. Summarize Notes Endpoint
app.post("/api/ai/summarize", async (req, res) => {
  const { text } = req.body;
  if (!text) {
    return res.status(400).json({ error: "Text is required to summarize" });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "MY_GEMINI_API_KEY") {
    // Return mock summary
    const mockResult = {
      keyConcepts: [
        "Spaced Repetition: Reviewing material at increasing intervals to move item into active memory.",
        "Active Recall: Forcing the mind to retrieve items directly instead of passive rereading.",
        "Mitochondria: Often called the powerhouses of the cell, generating adenosine triphosphate (ATP)."
      ],
      summaryText: `Your notes highlighted various foundational study methodologies and science. In addition to reviewing structural biology concepts such as mitochondrial cellular division and ATP energy production, the lecture heavily emphasized utilizing focused test-based active recall intervals to maximize retention rates.`
    };
    return res.json(mockResult);
  }

  try {
    const client = getGeminiClient();
    const response = await client.models.generateContent({
      model: "gemini-3.5-flash",
      contents: `Perform an intelligent key concept extraction and summary of the following lecture notes:\n\n${text}`,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          required: ["keyConcepts", "summaryText"],
          properties: {
            keyConcepts: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "Array of 3-5 crucial key concepts extracted from the notes, with a short explanation of each."
            },
            summaryText: {
              type: Type.STRING,
              description: "A cohesive, professional 2-3 paragraph summary of the entire submitted material."
            }
          }
        }
      }
    });

    const parsed = JSON.parse(response.text || "{}");
    res.json(parsed);
  } catch (err: any) {
    console.error("Gemini API Error in /api/ai/summarize:", err);
    res.status(500).json({ error: err.message || "Failed to summarize text" });
  }
});

// 4. Generate Study Set (Quizzes and Flashcards) Endpoint
app.post("/api/ai/generate-study", async (req, res) => {
  const { text } = req.body;
  if (!text) {
    return res.status(400).json({ error: "Lecture text is required to generate study materials" });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "MY_GEMINI_API_KEY") {
    // Offline smart fallback mock data suited to Mitochondria or general flashcards
    const mockQuiz = [
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
      },
      {
        id: "q3",
        question: "What is active recall?",
        options: ["Forcing the brain to retrieve information", "Rereading highlighted content", "Listening to lecture recordings", "Sleeping after studying"],
        correctAnswer: "Forcing the brain to retrieve information",
        explanation: "Active recall is a learning principle where you actively stimulate your memory for a concept during learning."
      }
    ];

    const mockCards = [
      { front: "Photosynthesis", back: "The chemical process by which green plants utilize sunlight, chlorophyll, CO2, and H2O to synthesize nutrients." },
      { front: "Mitochondria", back: "Foundational double-membrane organelle responsible for generating the vast majority of cellular ATP." },
      { front: "Active Recall", back: "An active study method where the student tests their mental retrieval instead of passively highlighting textbook paragraphs." },
      { front: "Spaced Repetition", back: "The practice of reviewing academic content across escalating intervals (e.g., 2, 4, 8 days) to boost retention." },
      { front: "Leitner System", back: "A flashcard methodology where cards are organized into boxes based on correct retrieval frequency." }
    ];

    return res.json({ flashcards: mockCards, quiz: mockQuiz });
  }

  try {
    const client = getGeminiClient();
    const prompt = `Using the following student notes, construct a study set containing EXACTLY 5 Flashcards and EXACTLY 3 interactive multiple-choice Quiz questions.
----------
NOTES:
${text}
----------
Flashcards must have 'front' and 'back' properties.
Quiz questions must have 'question', 'options' (array of 4 strings), 'correctAnswer' (string which must be one of physical options), and 'explanation' (string).`;

    const response = await client.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          required: ["flashcards", "quiz"],
          properties: {
            flashcards: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                required: ["front", "back"],
                properties: {
                  front: { type: Type.STRING },
                  back: { type: Type.STRING }
                }
              }
            },
            quiz: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                required: ["question", "options", "correctAnswer", "explanation"],
                properties: {
                  question: { type: Type.STRING },
                  options: {
                    type: Type.ARRAY,
                    items: { type: Type.STRING }
                  },
                  correctAnswer: { type: Type.STRING },
                  explanation: { type: Type.STRING }
                }
              }
            }
          }
        }
      }
    });

    const parsed = JSON.parse(response.text || "{}");
    // Ensure quizzes have IDs
    if (parsed.quiz && Array.isArray(parsed.quiz)) {
      parsed.quiz = parsed.quiz.map((q: any, idx: number) => ({
        ...q,
        id: `q-${Date.now()}-${idx}`
      }));
    }

    res.json(parsed);
  } catch (err: any) {
    console.error("Gemini API Error in /api/ai/generate-study:", err);
    res.status(500).json({ error: err.message || "Failed to generate quizzes and flashcards" });
  }
});


// Helper for local offline AI chatbot simulations (very robust!)
function getSimulatedChatResponse(userMsg: string): string {
  const m = userMsg.toLowerCase();
  if (m.includes("hello") || m.includes("hi ") || m.includes("hey")) {
    return "Hello! I am your TaskMate AI Coach. How can I assist you with your academic goals, task schedules, or exam preparation today? Try asking me about study techniques!";
  }
  if (m.includes("muscle") || m.includes("exercise") || m.includes("fitness") || m.includes("workout")) {
    return "Muscle growth requires consistency. Focus on compound exercises, adequate rest, and proper nutrition with sufficient protein. Stay hydrated and track your progress. Remember, results take time, so be patient and stay dedicated to your routine. Keep going!";
  }
  if (m.includes("mitochondria")) {
    return "The mitochondria is widely known as the powerhouse of the cell! It generates Adenosine Triphosphate (ATP), which acts as the chemical power unit for all eukaryotic life. Let's make sure that's logged in your exam review list.";
  }
  if (m.includes("spaced") || m.includes("repetition") || m.includes("leitner")) {
    return "Spaced repetition is a highly effective scientific technique! By testing yourself across escalating intervals (e.g. 2 hours, 1 day, 3 days, 7 days), you interrupt the 'Forgetting Curve' and store content in deep long-term recollection.";
  }
  if (m.includes("recall") || m.includes("active")) {
    return "Active recall is the absolute king of study skills! Rather than passively rereading or highlighting yellow text, you force your synapses to pull items out of memory (e.g. via practice questions or closed-book reviews).";
  }
  if (m.includes("gpa")) {
    return "Calculating your GPA keeps you clear and targeted. Use our built-in GPA Calculator tab! Remember, credit hours multiply grade weightings, so focus high intensity on heavily-weighted courses.";
  }
  if (m.includes("exam") || m.includes("stres") || m.includes("anxious")) {
    return "Exam anxiety is super common. First, break subjects down into atomic bullet points using the Task Manager. Second, execute small 25-minute Pomodoro sprints! Step-by-step progress lowers stress naturally.";
  }
  return `That makes absolute sense! Consistent preparation leads to incredible execution. Here is my core guidance:
1. **Log it step-by-step**: Put your target actions directly in our Task manager page and rank them by Priority (High, Medium, Low).
2. **Apply Pomodoro blocks**: Stay focused with the Pomodoro tab to build high study endurance. 
3. **Draft simple index cards**: Review notes directly. Paste long lecture texts on our 'Study Hub' tab to summarize automatically! 

What specific sub-topic or exam schedule should we design together next?`;
}


// Integrate Vite as Middleware or static server
async function setupServer() {
  if (process.env.NODE_ENV !== "production") {
    // Development Mode
    const { createServer: createViteServer } = await import("vite");
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    // Production Mode
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`TaskMate full-stack server running securely on http://localhost:${PORT}`);
  });
}

setupServer();
