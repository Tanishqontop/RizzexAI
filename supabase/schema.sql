-- Create battles table
CREATE TABLE battles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player1_id UUID NOT NULL,
    player2_id UUID,
    player1_line TEXT NOT NULL,
    player2_line TEXT,
    status TEXT NOT NULL DEFAULT 'waiting',
    winner_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create index for faster queries
CREATE INDEX battles_status_idx ON battles(status);
CREATE INDEX battles_player1_id_idx ON battles(player1_id);
CREATE INDEX battles_player2_id_idx ON battles(player2_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_battles_updated_at
    BEFORE UPDATE ON battles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create RLS policies
ALTER TABLE battles ENABLE ROW LEVEL SECURITY;

-- Allow anyone to create a battle
CREATE POLICY "Anyone can create a battle"
    ON battles FOR INSERT
    WITH CHECK (true);

-- Allow anyone to read battles
CREATE POLICY "Anyone can read battles"
    ON battles FOR SELECT
    USING (true);

-- Allow players to update their own battles
CREATE POLICY "Players can update their battles"
    ON battles FOR UPDATE
    USING (
        player1_id = auth.uid() OR 
        player2_id = auth.uid()
    );

-- Create player_stats table
CREATE TABLE player_stats (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id),
    wins INTEGER DEFAULT 0,
    total_battles INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create trigger to update player_stats when a battle is completed
CREATE OR REPLACE FUNCTION update_player_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update winner's stats
    IF NEW.winner_id IS NOT NULL THEN
        INSERT INTO player_stats (user_id, wins, total_battles, total_points)
        VALUES (NEW.winner_id, 1, 1, 10)
        ON CONFLICT (user_id) DO UPDATE
        SET 
            wins = player_stats.wins + 1,
            total_battles = player_stats.total_battles + 1,
            total_points = player_stats.total_points + 10,
            updated_at = TIMEZONE('utc'::text, NOW());
    END IF;

    -- Update loser's stats
    IF NEW.winner_id IS NOT NULL THEN
        INSERT INTO player_stats (user_id, total_battles)
        VALUES (
            CASE 
                WHEN NEW.winner_id = NEW.player1_id THEN NEW.player2_id
                ELSE NEW.player1_id
            END,
            1
        )
        ON CONFLICT (user_id) DO UPDATE
        SET 
            total_battles = player_stats.total_battles + 1,
            updated_at = TIMEZONE('utc'::text, NOW());
    END IF;

    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to update player stats when a battle is completed
CREATE TRIGGER update_player_stats_after_battle
    AFTER UPDATE ON battles
    FOR EACH ROW
    WHEN (NEW.status = 'complete' AND OLD.status != 'complete')
    EXECUTE FUNCTION update_player_stats();

-- Create RLS policies for player_stats
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read player stats
CREATE POLICY "Anyone can read player stats"
    ON player_stats FOR SELECT
    USING (true);

-- Allow users to update their own stats
CREATE POLICY "Users can update their own stats"
    ON player_stats FOR UPDATE
    USING (user_id = auth.uid());

-- Create profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    username TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Set up Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public profiles are viewable by everyone."
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile."
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile."
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create rizz_submissions table
CREATE TABLE rizz_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    content TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create rizz_votes table
CREATE TABLE rizz_votes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    battle_id UUID NOT NULL REFERENCES battles(id) ON DELETE CASCADE,
    submission_id UUID NOT NULL REFERENCES rizz_submissions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    is_upvote BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create index for faster queries on rizz_votes
CREATE INDEX rizz_votes_battle_id_idx ON rizz_votes(battle_id);
CREATE INDEX rizz_votes_submission_id_idx ON rizz_votes(submission_id);
CREATE INDEX rizz_votes_user_id_idx ON rizz_votes(user_id);

-- Add RLS policies for rizz_submissions table
ALTER TABLE rizz_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON rizz_submissions FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users" ON rizz_submissions FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Add RLS policies for rizz_votes table
ALTER TABLE rizz_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON rizz_votes FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users" ON rizz_votes FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Create function to process battle results
CREATE OR REPLACE FUNCTION process_battle_result(p_battle_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_player1_id UUID;
    v_player2_id UUID;
    v_player1_votes INTEGER DEFAULT 0;
    v_player2_votes INTEGER DEFAULT 0;
    v_winner_id UUID DEFAULT NULL;
    v_vote RECORD;
BEGIN
    -- Get player IDs for the battle
    SELECT player1_id, player2_id INTO v_player1_id, v_player2_id
    FROM battles
    WHERE id = p_battle_id;

    -- Count votes for each player
    FOR v_vote IN
        SELECT player_vote_id
        FROM rizz_votes
        WHERE battle_id = p_battle_id
    LOOP
        IF v_vote.player_vote_id = v_player1_id THEN
            v_player1_votes := v_player1_votes + 1;
        ELSIF v_vote.player_vote_id = v_player2_id THEN
            v_player2_votes := v_player2_votes + 1;
        END IF;
    END LOOP;

    -- Determine the winner
    IF v_player1_votes > v_player2_votes THEN
        v_winner_id := v_player1_id;
    ELSIF v_player2_votes > v_player1_votes THEN
        v_winner_id := v_player2_id;
    ELSE
        -- Handle tie: winner_id remains NULL. The player_stats trigger
        -- handles updating total_battles for both players even with no winner_id.
        -- We can log a tie if needed.
        RAISE NOTICE 'Tie in battle %: Player 1 votes: %, Player 2 votes: %', p_battle_id, v_player1_votes, v_player2_votes;
    END IF;

    -- Update the battle status and winner
    UPDATE battles
    SET status = 'completed', winner_id = v_winner_id
    WHERE id = p_battle_id;

    -- The update_player_stats_after_battle trigger will handle updating player_stats
END;
$$; 