-- Achievements module: personal_records + user_achievements tables

-- 1. personal_records table
CREATE TABLE IF NOT EXISTS public.personal_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,
    record_value DOUBLE PRECISION NOT NULL DEFAULT 0,
    record_unit TEXT NOT NULL DEFAULT 'kg',
    achieved_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_personal_records_user_id ON public.personal_records(user_id);
CREATE INDEX IF NOT EXISTS idx_personal_records_exercise ON public.personal_records(user_id, exercise_name);

-- 2. user_achievements table (tracks which milestone badges are unlocked)
CREATE TABLE IF NOT EXISTS public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_key TEXT NOT NULL,
    achievement_title TEXT NOT NULL,
    achievement_description TEXT NOT NULL DEFAULT '',
    unlocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_achievements_unique ON public.user_achievements(user_id, achievement_key);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);

-- 3. Enable RLS
ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_personal_records" ON public.personal_records;
CREATE POLICY "users_manage_own_personal_records"
ON public.personal_records
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_user_achievements" ON public.user_achievements;
CREATE POLICY "users_manage_own_user_achievements"
ON public.user_achievements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
