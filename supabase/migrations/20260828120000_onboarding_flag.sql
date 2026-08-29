-- FitTrack: Track onboarding completion so login routes returning users
-- to Home instead of re-running the personalization questionnaire.

ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false;
