-- 020_gamification_phases_2_3.sql
-- Challenges, Quests, and Social Squads

-- 1. Challenges Table
CREATE TABLE IF NOT EXISTS public.challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    pillar TEXT NOT NULL, -- 'cooking', 'waste', 'health', 'prep'
    goal_target INT NOT NULL,
    season TEXT, -- e.g. 'July 2026', or 'Evergreen'
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
-- Everyone can read active challenges
CREATE POLICY "anyone_can_read_challenges" ON public.challenges
    FOR SELECT USING (true);

-- 2. User Challenges Table (tracks progress)
CREATE TABLE IF NOT EXISTS public.user_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
    progress INT DEFAULT 0,
    status TEXT DEFAULT 'active', -- 'active', 'completed'
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, challenge_id)
);

ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_manage_own_challenges" ON public.user_challenges
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Squads Table
CREATE TABLE IF NOT EXISTS public.squads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.squads ENABLE ROW LEVEL SECURITY;
-- Anyone can read squads (needed to join via invite code)
CREATE POLICY "anyone_can_read_squads" ON public.squads
    FOR SELECT USING (true);
CREATE POLICY "users_can_create_squads" ON public.squads
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- 4. Squad Members Table
CREATE TABLE IF NOT EXISTS public.squad_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    squad_id UUID NOT NULL REFERENCES public.squads(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'owner', 'member'
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(squad_id, user_id)
);

ALTER TABLE public.squad_members ENABLE ROW LEVEL SECURITY;
-- Users can see members of squads they are in
CREATE POLICY "users_read_own_squad_members" ON public.squad_members
    FOR SELECT USING (
        squad_id IN (
            SELECT squad_id FROM public.squad_members WHERE user_id = auth.uid()
        )
    );
-- Users can join squads
CREATE POLICY "users_can_join_squads" ON public.squad_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);
-- Users can leave squads
CREATE POLICY "users_can_leave_squads" ON public.squad_members
    FOR DELETE USING (auth.uid() = user_id);

-- 5. Insert initial challenges
INSERT INTO public.challenges (title, description, pillar, goal_target, season, start_date, end_date)
VALUES 
  ('Use It Up Weekend', 'Save 5 items from expiring over the weekend.', 'waste', 5, 'Evergreen', NULL, NULL),
  ('Prep Week', 'Cook and store 10 prep portions.', 'prep', 10, 'Evergreen', NULL, NULL),
  ('Macro Week', 'Log 7 meals with a balanced macro profile.', 'health', 7, 'Evergreen', NULL, NULL),
  ('Chef in Training', 'Complete 3 guided cooking sessions.', 'cooking', 3, 'Evergreen', NULL, NULL)
ON CONFLICT DO NOTHING;
