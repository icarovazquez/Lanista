-- Migration 036: Diagnostic + fix for coach auth users
-- Uses RAISE NOTICE so we can see results in migration output

DO $$
DECLARE
  auth_count INT;
  identity_count INT;
  public_count INT;
  pw_hash TEXT := '$2b$10$xMI8e/IsHOcpjfi6wWCj/u6z381000etIhOCcCLW9SmWobtazukBG';
BEGIN
  SELECT count(*) INTO auth_count FROM auth.users WHERE email LIKE '%coach.%@lanista.test';
  SELECT count(*) INTO identity_count FROM auth.identities i
    JOIN auth.users u ON u.id = i.user_id WHERE u.email LIKE '%coach.%@lanista.test';
  SELECT count(*) INTO public_count FROM public.users WHERE email LIKE '%coach.%@lanista.test';

  RAISE NOTICE 'AUTH STATE: auth.users=% identities=% public.users=%', auth_count, identity_count, public_count;

  -- Insert if missing
  IF auth_count = 0 THEN
    RAISE NOTICE 'Inserting coach auth users...';
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
    VALUES
      ('b2000000-0000-0000-0000-000000000001','coach.daniels@lanista.test',   pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000002','coach.martinez@lanista.test',  pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000003','coach.osei@lanista.test',      pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000004','coach.nguyen@lanista.test',    pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000005','coach.sullivan@lanista.test',  pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000006','coach.reid@lanista.test',      pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000007','coach.patel@lanista.test',     pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000008','coach.foster@lanista.test',    pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000009','coach.diaz@lanista.test',      pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000010','coach.kim@lanista.test',       pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000011','coach.jackson@lanista.test',   pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000012','coach.okafor@lanista.test',    pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000013','coach.hernandez@lanista.test', pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000014','coach.walsh@lanista.test',     pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000015','coach.ibrahim@lanista.test',   pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000016','coach.chen@lanista.test',      pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000017','coach.morrison@lanista.test',  pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000018','coach.tran@lanista.test',      pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000019','coach.owens@lanista.test',     pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
      ('b2000000-0000-0000-0000-000000000020','coach.reyes@lanista.test',     pw_hash,NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated')
    ON CONFLICT (id) DO UPDATE SET encrypted_password = EXCLUDED.encrypted_password, updated_at = NOW();
    RAISE NOTICE 'auth.users insert done';
  ELSE
    RAISE NOTICE 'Coaches already in auth.users, updating password hash...';
    UPDATE auth.users SET encrypted_password = pw_hash, updated_at = NOW()
    WHERE email LIKE '%coach.%@lanista.test';
  END IF;

  -- Create identities if missing
  IF identity_count = 0 THEN
    INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    SELECT gen_random_uuid(), u.id, u.email,
           jsonb_build_object('sub', u.id::text, 'email', u.email),
           'email', NOW(), NOW(), NOW()
    FROM auth.users u
    WHERE u.email LIKE '%coach.%@lanista.test'
    ON CONFLICT (provider, provider_id) DO NOTHING;
    RAISE NOTICE 'identities inserted';
  ELSE
    RAISE NOTICE 'identities already exist';
  END IF;

  SELECT count(*) INTO auth_count FROM auth.users WHERE email LIKE '%coach.%@lanista.test';
  SELECT count(*) INTO identity_count FROM auth.identities i
    JOIN auth.users u ON u.id = i.user_id WHERE u.email LIKE '%coach.%@lanista.test';
  RAISE NOTICE 'FINAL STATE: auth.users=% identities=%', auth_count, identity_count;
END $$;
