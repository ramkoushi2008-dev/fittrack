-- FitTrack: Extend user_profiles for account screen + linked devices + health apps

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Extend user_profiles with additional account fields
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS display_name TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS date_of_birth DATE,
    ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS height_cm DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS weight_kg DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS fitness_goal TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. linked_devices
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.linked_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    device_type TEXT NOT NULL DEFAULT 'wearable',
    is_connected BOOLEAN NOT NULL DEFAULT true,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_linked_devices_user_id ON public.linked_devices(user_id);

ALTER TABLE public.linked_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_linked_devices" ON public.linked_devices;
CREATE POLICY "users_manage_own_linked_devices"
ON public.linked_devices FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. connected_health_apps
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.connected_health_apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    app_name TEXT NOT NULL,
    app_icon TEXT DEFAULT '',
    is_connected BOOLEAN NOT NULL DEFAULT false,
    connected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_connected_health_apps_user_id ON public.connected_health_apps(user_id);

ALTER TABLE public.connected_health_apps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_connected_health_apps" ON public.connected_health_apps;
CREATE POLICY "users_manage_own_connected_health_apps"
ON public.connected_health_apps FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
