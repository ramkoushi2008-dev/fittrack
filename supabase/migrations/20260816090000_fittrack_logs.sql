-- FitTrack: Cloud sync tables for workout, nutrition, and sleep logs

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. user_profiles (intermediary for auth.users)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. workout_logs
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workout_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    workout_label TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    calories_burned DOUBLE PRECISION NOT NULL DEFAULT 0,
    total_sets INTEGER NOT NULL DEFAULT 0,
    exercises JSONB DEFAULT '[]'::jsonb,
    logged_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON public.workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_logged_at ON public.workout_logs(logged_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. nutrition_logs
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.nutrition_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    meal_index INTEGER NOT NULL DEFAULT 0,
    food_name TEXT NOT NULL,
    calories INTEGER NOT NULL DEFAULT 0,
    protein INTEGER NOT NULL DEFAULT 0,
    carbs INTEGER NOT NULL DEFAULT 0,
    fat INTEGER NOT NULL DEFAULT 0,
    portion TEXT DEFAULT '',
    logged_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_nutrition_logs_user_id ON public.nutrition_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_logs_logged_at ON public.nutrition_logs(logged_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. sleep_logs
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    hours_slept DOUBLE PRECISION NOT NULL DEFAULT 0,
    logged_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_id ON public.sleep_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_sleep_logs_logged_at ON public.sleep_logs(logged_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Trigger: auto-create user_profiles on auth signup
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Enable RLS
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. RLS Policies
-- ─────────────────────────────────────────────────────────────────────────────

-- user_profiles
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles FOR ALL TO authenticated
USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- workout_logs
DROP POLICY IF EXISTS "users_manage_own_workout_logs" ON public.workout_logs;
CREATE POLICY "users_manage_own_workout_logs"
ON public.workout_logs FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- nutrition_logs
DROP POLICY IF EXISTS "users_manage_own_nutrition_logs" ON public.nutrition_logs;
CREATE POLICY "users_manage_own_nutrition_logs"
ON public.nutrition_logs FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- sleep_logs
DROP POLICY IF EXISTS "users_manage_own_sleep_logs" ON public.sleep_logs;
CREATE POLICY "users_manage_own_sleep_logs"
ON public.sleep_logs FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
