-- Migration 040: Check and fix instance_id on auth.users
-- GoTrue filters auth.users by instance_id. If it's NULL, users won't be found.

DO $$
DECLARE
  r RECORD;
  coach_instance_id UUID;
  system_instance_id UUID;
BEGIN
  -- Check instance_id for coach.daniels
  SELECT instance_id INTO coach_instance_id
  FROM auth.users WHERE email = 'coach.daniels@lanista.test';
  RAISE NOTICE 'coach.daniels instance_id: %', coach_instance_id;

  -- Check instance_id of any non-coach user (to find the GoTrue instance id)
  SELECT instance_id INTO system_instance_id
  FROM auth.users
  WHERE email NOT LIKE '%@lanista.test'
  LIMIT 1;
  RAISE NOTICE 'system instance_id (for comparison): %', system_instance_id;

  -- Fix: set all coach users to the standard GoTrue instance_id (all zeros)
  UPDATE auth.users
  SET instance_id = '00000000-0000-0000-0000-000000000000'
  WHERE email LIKE '%coach.%@lanista.test';

  RAISE NOTICE 'Updated % coach rows with correct instance_id',
    (SELECT count(*) FROM auth.users WHERE email LIKE '%coach.%@lanista.test');

  -- Also check raw_app_meta_data for coach.daniels
  FOR r IN SELECT raw_app_meta_data, raw_user_meta_data, aud, role, instance_id
           FROM auth.users WHERE email = 'coach.daniels@lanista.test'
  LOOP
    RAISE NOTICE 'coach.daniels after fix: aud=% role=% instance_id=% app_meta=%',
      r.aud, r.role, r.instance_id, r.raw_app_meta_data;
  END LOOP;
END $$;
