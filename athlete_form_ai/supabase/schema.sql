-- Users table to store app users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Track & Field event models (ideal joint angles/positions)
CREATE TABLE event_models (
    id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) UNIQUE NOT NULL,
    model_data JSONB NOT NULL, -- Stores angle/position data for the event
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Videos uploaded by users
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,       -- URL to video in Supabase Storage or elsewhere
    event_id INT REFERENCES event_models(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Analysis feedback for videos
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    feedback_text TEXT NOT NULL,     -- Natural language feedback from Gemini API
    feedback_data JSONB,             -- Structured data, e.g., angles deviation etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Optional: User surveys or progress tracking
CREATE TABLE surveys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    survey_data JSONB NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
