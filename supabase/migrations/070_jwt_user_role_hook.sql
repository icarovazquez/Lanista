-- Migration 068: Custom access token hook to add user_role claim to JWT
-- This fixes RLS policies that use auth.jwt() ->> 'user_role'
-- (coaches_read_player_users, players_read_coach_users, etc.)

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  claims   jsonb;
  u_role   text;
BEGIN
  -- Look up the user's role from the public.users table
  SELECT role::text INTO u_role
  FROM public.users
  WHERE id = (event ->> 'user_id')::uuid;

  claims := event -> 'claims';

  IF u_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{user_role}', to_jsonb(u_role));
  END IF;

  event := jsonb_set(event, '{claims}', claims);
  RETURN event;
END;
$$;

-- Grant execute permission to the auth system
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM authenticated, anon, public;
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
