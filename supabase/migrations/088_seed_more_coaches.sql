-- Migration 088: Seed 80 additional coach profiles (schools 21–100)
-- Covers D1, D2, and D3 programs across the US.
-- UUIDs start at 201 to avoid conflicts with existing migrations (001–066, 135).

SET search_path TO public, extensions, auth;
SET session_replication_role = replica;

DO $$
DECLARE
  -- Auth user UUIDs (201–280)
  cuid201 UUID := 'b2000000-0000-0000-0000-000000000201';
  cuid202 UUID := 'b2000000-0000-0000-0000-000000000202';
  cuid203 UUID := 'b2000000-0000-0000-0000-000000000203';
  cuid204 UUID := 'b2000000-0000-0000-0000-000000000204';
  cuid205 UUID := 'b2000000-0000-0000-0000-000000000205';
  cuid206 UUID := 'b2000000-0000-0000-0000-000000000206';
  cuid207 UUID := 'b2000000-0000-0000-0000-000000000207';
  cuid208 UUID := 'b2000000-0000-0000-0000-000000000208';
  cuid209 UUID := 'b2000000-0000-0000-0000-000000000209';
  cuid210 UUID := 'b2000000-0000-0000-0000-000000000210';
  cuid211 UUID := 'b2000000-0000-0000-0000-000000000211';
  cuid212 UUID := 'b2000000-0000-0000-0000-000000000212';
  cuid213 UUID := 'b2000000-0000-0000-0000-000000000213';
  cuid214 UUID := 'b2000000-0000-0000-0000-000000000214';
  cuid215 UUID := 'b2000000-0000-0000-0000-000000000215';
  cuid216 UUID := 'b2000000-0000-0000-0000-000000000216';
  cuid217 UUID := 'b2000000-0000-0000-0000-000000000217';
  cuid218 UUID := 'b2000000-0000-0000-0000-000000000218';
  cuid219 UUID := 'b2000000-0000-0000-0000-000000000219';
  cuid220 UUID := 'b2000000-0000-0000-0000-000000000220';
  cuid221 UUID := 'b2000000-0000-0000-0000-000000000221';
  cuid222 UUID := 'b2000000-0000-0000-0000-000000000222';
  cuid223 UUID := 'b2000000-0000-0000-0000-000000000223';
  cuid224 UUID := 'b2000000-0000-0000-0000-000000000224';
  cuid225 UUID := 'b2000000-0000-0000-0000-000000000225';
  cuid226 UUID := 'b2000000-0000-0000-0000-000000000226';
  cuid227 UUID := 'b2000000-0000-0000-0000-000000000227';
  cuid228 UUID := 'b2000000-0000-0000-0000-000000000228';
  cuid229 UUID := 'b2000000-0000-0000-0000-000000000229';
  cuid230 UUID := 'b2000000-0000-0000-0000-000000000230';
  cuid231 UUID := 'b2000000-0000-0000-0000-000000000231';
  cuid232 UUID := 'b2000000-0000-0000-0000-000000000232';
  cuid233 UUID := 'b2000000-0000-0000-0000-000000000233';
  cuid234 UUID := 'b2000000-0000-0000-0000-000000000234';
  cuid235 UUID := 'b2000000-0000-0000-0000-000000000235';
  cuid236 UUID := 'b2000000-0000-0000-0000-000000000236';
  cuid237 UUID := 'b2000000-0000-0000-0000-000000000237';
  cuid238 UUID := 'b2000000-0000-0000-0000-000000000238';
  cuid239 UUID := 'b2000000-0000-0000-0000-000000000239';
  cuid240 UUID := 'b2000000-0000-0000-0000-000000000240';
  cuid241 UUID := 'b2000000-0000-0000-0000-000000000241';
  cuid242 UUID := 'b2000000-0000-0000-0000-000000000242';
  cuid243 UUID := 'b2000000-0000-0000-0000-000000000243';
  cuid244 UUID := 'b2000000-0000-0000-0000-000000000244';
  cuid245 UUID := 'b2000000-0000-0000-0000-000000000245';
  cuid246 UUID := 'b2000000-0000-0000-0000-000000000246';
  cuid247 UUID := 'b2000000-0000-0000-0000-000000000247';
  cuid248 UUID := 'b2000000-0000-0000-0000-000000000248';
  cuid249 UUID := 'b2000000-0000-0000-0000-000000000249';
  cuid250 UUID := 'b2000000-0000-0000-0000-000000000250';
  cuid251 UUID := 'b2000000-0000-0000-0000-000000000251';
  cuid252 UUID := 'b2000000-0000-0000-0000-000000000252';
  cuid253 UUID := 'b2000000-0000-0000-0000-000000000253';
  cuid254 UUID := 'b2000000-0000-0000-0000-000000000254';
  cuid255 UUID := 'b2000000-0000-0000-0000-000000000255';
  cuid256 UUID := 'b2000000-0000-0000-0000-000000000256';
  cuid257 UUID := 'b2000000-0000-0000-0000-000000000257';
  cuid258 UUID := 'b2000000-0000-0000-0000-000000000258';
  cuid259 UUID := 'b2000000-0000-0000-0000-000000000259';
  cuid260 UUID := 'b2000000-0000-0000-0000-000000000260';
  cuid261 UUID := 'b2000000-0000-0000-0000-000000000261';
  cuid262 UUID := 'b2000000-0000-0000-0000-000000000262';
  cuid263 UUID := 'b2000000-0000-0000-0000-000000000263';
  cuid264 UUID := 'b2000000-0000-0000-0000-000000000264';
  cuid265 UUID := 'b2000000-0000-0000-0000-000000000265';
  cuid266 UUID := 'b2000000-0000-0000-0000-000000000266';
  cuid267 UUID := 'b2000000-0000-0000-0000-000000000267';
  cuid268 UUID := 'b2000000-0000-0000-0000-000000000268';
  cuid269 UUID := 'b2000000-0000-0000-0000-000000000269';
  cuid270 UUID := 'b2000000-0000-0000-0000-000000000270';
  cuid271 UUID := 'b2000000-0000-0000-0000-000000000271';
  cuid272 UUID := 'b2000000-0000-0000-0000-000000000272';
  cuid273 UUID := 'b2000000-0000-0000-0000-000000000273';
  cuid274 UUID := 'b2000000-0000-0000-0000-000000000274';
  cuid275 UUID := 'b2000000-0000-0000-0000-000000000275';
  cuid276 UUID := 'b2000000-0000-0000-0000-000000000276';
  cuid277 UUID := 'b2000000-0000-0000-0000-000000000277';
  cuid278 UUID := 'b2000000-0000-0000-0000-000000000278';
  cuid279 UUID := 'b2000000-0000-0000-0000-000000000279';
  cuid280 UUID := 'b2000000-0000-0000-0000-000000000280';

  -- Coach profile UUIDs (201–280)
  coach201 UUID := 'c3000000-0000-0000-0000-000000000201';
  coach202 UUID := 'c3000000-0000-0000-0000-000000000202';
  coach203 UUID := 'c3000000-0000-0000-0000-000000000203';
  coach204 UUID := 'c3000000-0000-0000-0000-000000000204';
  coach205 UUID := 'c3000000-0000-0000-0000-000000000205';
  coach206 UUID := 'c3000000-0000-0000-0000-000000000206';
  coach207 UUID := 'c3000000-0000-0000-0000-000000000207';
  coach208 UUID := 'c3000000-0000-0000-0000-000000000208';
  coach209 UUID := 'c3000000-0000-0000-0000-000000000209';
  coach210 UUID := 'c3000000-0000-0000-0000-000000000210';
  coach211 UUID := 'c3000000-0000-0000-0000-000000000211';
  coach212 UUID := 'c3000000-0000-0000-0000-000000000212';
  coach213 UUID := 'c3000000-0000-0000-0000-000000000213';
  coach214 UUID := 'c3000000-0000-0000-0000-000000000214';
  coach215 UUID := 'c3000000-0000-0000-0000-000000000215';
  coach216 UUID := 'c3000000-0000-0000-0000-000000000216';
  coach217 UUID := 'c3000000-0000-0000-0000-000000000217';
  coach218 UUID := 'c3000000-0000-0000-0000-000000000218';
  coach219 UUID := 'c3000000-0000-0000-0000-000000000219';
  coach220 UUID := 'c3000000-0000-0000-0000-000000000220';
  coach221 UUID := 'c3000000-0000-0000-0000-000000000221';
  coach222 UUID := 'c3000000-0000-0000-0000-000000000222';
  coach223 UUID := 'c3000000-0000-0000-0000-000000000223';
  coach224 UUID := 'c3000000-0000-0000-0000-000000000224';
  coach225 UUID := 'c3000000-0000-0000-0000-000000000225';
  coach226 UUID := 'c3000000-0000-0000-0000-000000000226';
  coach227 UUID := 'c3000000-0000-0000-0000-000000000227';
  coach228 UUID := 'c3000000-0000-0000-0000-000000000228';
  coach229 UUID := 'c3000000-0000-0000-0000-000000000229';
  coach230 UUID := 'c3000000-0000-0000-0000-000000000230';
  coach231 UUID := 'c3000000-0000-0000-0000-000000000231';
  coach232 UUID := 'c3000000-0000-0000-0000-000000000232';
  coach233 UUID := 'c3000000-0000-0000-0000-000000000233';
  coach234 UUID := 'c3000000-0000-0000-0000-000000000234';
  coach235 UUID := 'c3000000-0000-0000-0000-000000000235';
  coach236 UUID := 'c3000000-0000-0000-0000-000000000236';
  coach237 UUID := 'c3000000-0000-0000-0000-000000000237';
  coach238 UUID := 'c3000000-0000-0000-0000-000000000238';
  coach239 UUID := 'c3000000-0000-0000-0000-000000000239';
  coach240 UUID := 'c3000000-0000-0000-0000-000000000240';
  coach241 UUID := 'c3000000-0000-0000-0000-000000000241';
  coach242 UUID := 'c3000000-0000-0000-0000-000000000242';
  coach243 UUID := 'c3000000-0000-0000-0000-000000000243';
  coach244 UUID := 'c3000000-0000-0000-0000-000000000244';
  coach245 UUID := 'c3000000-0000-0000-0000-000000000245';
  coach246 UUID := 'c3000000-0000-0000-0000-000000000246';
  coach247 UUID := 'c3000000-0000-0000-0000-000000000247';
  coach248 UUID := 'c3000000-0000-0000-0000-000000000248';
  coach249 UUID := 'c3000000-0000-0000-0000-000000000249';
  coach250 UUID := 'c3000000-0000-0000-0000-000000000250';
  coach251 UUID := 'c3000000-0000-0000-0000-000000000251';
  coach252 UUID := 'c3000000-0000-0000-0000-000000000252';
  coach253 UUID := 'c3000000-0000-0000-0000-000000000253';
  coach254 UUID := 'c3000000-0000-0000-0000-000000000254';
  coach255 UUID := 'c3000000-0000-0000-0000-000000000255';
  coach256 UUID := 'c3000000-0000-0000-0000-000000000256';
  coach257 UUID := 'c3000000-0000-0000-0000-000000000257';
  coach258 UUID := 'c3000000-0000-0000-0000-000000000258';
  coach259 UUID := 'c3000000-0000-0000-0000-000000000259';
  coach260 UUID := 'c3000000-0000-0000-0000-000000000260';
  coach261 UUID := 'c3000000-0000-0000-0000-000000000261';
  coach262 UUID := 'c3000000-0000-0000-0000-000000000262';
  coach263 UUID := 'c3000000-0000-0000-0000-000000000263';
  coach264 UUID := 'c3000000-0000-0000-0000-000000000264';
  coach265 UUID := 'c3000000-0000-0000-0000-000000000265';
  coach266 UUID := 'c3000000-0000-0000-0000-000000000266';
  coach267 UUID := 'c3000000-0000-0000-0000-000000000267';
  coach268 UUID := 'c3000000-0000-0000-0000-000000000268';
  coach269 UUID := 'c3000000-0000-0000-0000-000000000269';
  coach270 UUID := 'c3000000-0000-0000-0000-000000000270';
  coach271 UUID := 'c3000000-0000-0000-0000-000000000271';
  coach272 UUID := 'c3000000-0000-0000-0000-000000000272';
  coach273 UUID := 'c3000000-0000-0000-0000-000000000273';
  coach274 UUID := 'c3000000-0000-0000-0000-000000000274';
  coach275 UUID := 'c3000000-0000-0000-0000-000000000275';
  coach276 UUID := 'c3000000-0000-0000-0000-000000000276';
  coach277 UUID := 'c3000000-0000-0000-0000-000000000277';
  coach278 UUID := 'c3000000-0000-0000-0000-000000000278';
  coach279 UUID := 'c3000000-0000-0000-0000-000000000279';
  coach280 UUID := 'c3000000-0000-0000-0000-000000000280';

BEGIN

-- ─── Auth Users ───────────────────────────────────────────────────────────────
-- instance_id MUST be '00000000-0000-0000-0000-000000000000'
-- All token fields MUST be '' (empty string, NOT NULL)
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, reauthentication_token,
  email_change, email_change_token_new, email_change_token_current,
  created_at, updated_at, aud, role
) VALUES
  -- 21 University of Maryland — Thomas Kelly
  (cuid201, '00000000-0000-0000-0000-000000000000',
   'coach.kelly@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 22 Duke University — Sarah Williams
  (cuid202, '00000000-0000-0000-0000-000000000000',
   'coach.swilliams@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 23 University of Notre Dame — John Nolan
  (cuid203, '00000000-0000-0000-0000-000000000000',
   'coach.nolan@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 24 Ohio State University — David Perez
  (cuid204, '00000000-0000-0000-0000-000000000000',
   'coach.dperez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 25 Penn State University — Michael Torres
  (cuid205, '00000000-0000-0000-0000-000000000000',
   'coach.torres@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 26 UCLA — Carlos Rivera
  (cuid206, '00000000-0000-0000-0000-000000000000',
   'coach.crivera@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 27 UC Santa Barbara — Rebecca Chen
  (cuid207, '00000000-0000-0000-0000-000000000000',
   'coach.rchen@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 28 University of Akron — James Murphy
  (cuid208, '00000000-0000-0000-0000-000000000000',
   'coach.jmurphy@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 29 UConn — Patricia Santos
  (cuid209, '00000000-0000-0000-0000-000000000000',
   'coach.santos@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 30 University of Michigan — Robert Anderson
  (cuid210, '00000000-0000-0000-0000-000000000000',
   'coach.randerson@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 31 Michigan State University — Lisa Johnson
  (cuid211, '00000000-0000-0000-0000-000000000000',
   'coach.ljohnson@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 32 Northwestern University — Kevin Park
  (cuid212, '00000000-0000-0000-0000-000000000000',
   'coach.park@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 33 University of Wisconsin — Amy Schmidt
  (cuid213, '00000000-0000-0000-0000-000000000000',
   'coach.schmidt@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 34 Virginia Tech — Mark Davis
  (cuid214, '00000000-0000-0000-0000-000000000000',
   'coach.mdavis@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 35 NC State University — Jennifer Lopez
  (cuid215, '00000000-0000-0000-0000-000000000000',
   'coach.jlopez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 36 University of Pittsburgh — Brian Walsh
  (cuid216, '00000000-0000-0000-0000-000000000000',
   'coach.bwalsh@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 37 Boston College — Daniel O'Brien
  (cuid217, '00000000-0000-0000-0000-000000000000',
   'coach.obrien@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 38 Rutgers University — Eric Zhang
  (cuid218, '00000000-0000-0000-0000-000000000000',
   'coach.zhang@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 39 West Virginia University — Steven Coleman
  (cuid219, '00000000-0000-0000-0000-000000000000',
   'coach.coleman@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 40 University of Colorado — Rachel Green
  (cuid220, '00000000-0000-0000-0000-000000000000',
   'coach.rgreen@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 41 Creighton University — Paul Martinez
  (cuid221, '00000000-0000-0000-0000-000000000000',
   'coach.pmartinez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 42 University of Portland — Maria Gonzalez
  (cuid222, '00000000-0000-0000-0000-000000000000',
   'coach.gonzalez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 43 University of Denver — Andrew Phillips
  (cuid223, '00000000-0000-0000-0000-000000000000',
   'coach.aphillips@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 44 Gonzaga University — Christine Burke
  (cuid224, '00000000-0000-0000-0000-000000000000',
   'coach.burke@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 45 University of New Mexico — Jose Rodriguez
  (cuid225, '00000000-0000-0000-0000-000000000000',
   'coach.jrodriguez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 46 SMU — Nathan Brown
  (cuid226, '00000000-0000-0000-0000-000000000000',
   'coach.nbrown@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 47 TCU — Laura Thompson
  (cuid227, '00000000-0000-0000-0000-000000000000',
   'coach.thompson@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 48 Baylor University — Christopher White
  (cuid228, '00000000-0000-0000-0000-000000000000',
   'coach.cwhite@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 49 University of Kentucky — Stephanie Harris
  (cuid229, '00000000-0000-0000-0000-000000000000',
   'coach.harris@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 50 University of South Carolina — Derek Wilson
  (cuid230, '00000000-0000-0000-0000-000000000000',
   'coach.dwilson@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 51 University of Tulsa — Amanda Taylor
  (cuid231, '00000000-0000-0000-0000-000000000000',
   'coach.taylor@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 52 University of Minnesota — William Clark
  (cuid232, '00000000-0000-0000-0000-000000000000',
   'coach.wclark@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 53 University of Iowa — Elizabeth Moore
  (cuid233, '00000000-0000-0000-0000-000000000000',
   'coach.moore@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 54 Florida State University — Anthony Jackson
  (cuid234, '00000000-0000-0000-0000-000000000000',
   'coach.ajackson@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 55 University of Tennessee — Sandra Davis
  (cuid235, '00000000-0000-0000-0000-000000000000',
   'coach.sdavis@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 56 University of Arizona — Richard Lee
  (cuid236, '00000000-0000-0000-0000-000000000000',
   'coach.lee@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 57 University of Washington — Michelle Kim
  (cuid237, '00000000-0000-0000-0000-000000000000',
   'coach.mkim@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 58 Oregon State University — Timothy Brown
  (cuid238, '00000000-0000-0000-0000-000000000000',
   'coach.tbrown@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 59 UC Davis — Catherine Adams
  (cuid239, '00000000-0000-0000-0000-000000000000',
   'coach.adams@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 60 San Jose State University — Ronald Garcia
  (cuid240, '00000000-0000-0000-0000-000000000000',
   'coach.garcia@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 61 UNLV — Frances Miller
  (cuid241, '00000000-0000-0000-0000-000000000000',
   'coach.miller@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 62 Xavier University — Joseph Martin
  (cuid242, '00000000-0000-0000-0000-000000000000',
   'coach.jmartin@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 63 Butler University — Diana Robinson
  (cuid243, '00000000-0000-0000-0000-000000000000',
   'coach.robinson@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 64 Loyola University Chicago — Alan Walker
  (cuid244, '00000000-0000-0000-0000-000000000000',
   'coach.awalker@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 65 Providence College — Barbara Hall
  (cuid245, '00000000-0000-0000-0000-000000000000',
   'coach.hall@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 66 University of San Diego — Christopher Allen
  (cuid246, '00000000-0000-0000-0000-000000000000',
   'coach.allen@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 67 Furman University — Margaret Young
  (cuid247, '00000000-0000-0000-0000-000000000000',
   'coach.young@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 68 James Madison University — Kevin Hernandez
  (cuid248, '00000000-0000-0000-0000-000000000000',
   'coach.khernandez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 69 Old Dominion University — Sharon King
  (cuid249, '00000000-0000-0000-0000-000000000000',
   'coach.king@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 70 University of Missouri — Gary Wright
  (cuid250, '00000000-0000-0000-0000-000000000000',
   'coach.wright@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 71 University of Tampa — Nicholas Scott
  (cuid251, '00000000-0000-0000-0000-000000000000',
   'coach.nscott@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 72 Florida Southern College — Donna Green
  (cuid252, '00000000-0000-0000-0000-000000000000',
   'coach.dgreen@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 73 Rollins College — Peter Adams
  (cuid253, '00000000-0000-0000-0000-000000000000',
   'coach.padams@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 74 Rockhurst University — Melissa Baker
  (cuid254, '00000000-0000-0000-0000-000000000000',
   'coach.baker@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 75 Drury University — Robert Nelson
  (cuid255, '00000000-0000-0000-0000-000000000000',
   'coach.nelson@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 76 Colorado School of Mines — Jennifer Carter
  (cuid256, '00000000-0000-0000-0000-000000000000',
   'coach.carter@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 77 Fort Hays State University — Thomas Mitchell
  (cuid257, '00000000-0000-0000-0000-000000000000',
   'coach.mitchell@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 78 Adelphi University — Linda Perez
  (cuid258, '00000000-0000-0000-0000-000000000000',
   'coach.lperez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 79 Assumption University — Steven Roberts
  (cuid259, '00000000-0000-0000-0000-000000000000',
   'coach.roberts@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 80 Le Moyne College — Karen Turner
  (cuid260, '00000000-0000-0000-0000-000000000000',
   'coach.turner@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 81 University of Indianapolis — Richard Phillips
  (cuid261, '00000000-0000-0000-0000-000000000000',
   'coach.rphillips@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 82 Ashland University — Patricia Campbell
  (cuid262, '00000000-0000-0000-0000-000000000000',
   'coach.campbell@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 83 West Texas A&M University — Jose Sanchez
  (cuid263, '00000000-0000-0000-0000-000000000000',
   'coach.sanchez@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 84 Bellarmine University — Dorothy Parker
  (cuid264, '00000000-0000-0000-0000-000000000000',
   'coach.dparker@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 85 Wingate University — Frank Evans
  (cuid265, '00000000-0000-0000-0000-000000000000',
   'coach.evans@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 86 University of Wisconsin-Parkside — Susan Edwards
  (cuid266, '00000000-0000-0000-0000-000000000000',
   'coach.edwards@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 87 Saint Leo University — Charles Collins
  (cuid267, '00000000-0000-0000-0000-000000000000',
   'coach.collins@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 88 Mercy University — Helen Stewart
  (cuid268, '00000000-0000-0000-0000-000000000000',
   'coach.stewart@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 89 Trinity College — Matthew Morris
  (cuid269, '00000000-0000-0000-0000-000000000000',
   'coach.morris@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 90 Connecticut College — Anna Rogers
  (cuid270, '00000000-0000-0000-0000-000000000000',
   'coach.arogers@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 91 Dickinson College — Benjamin Reed
  (cuid271, '00000000-0000-0000-0000-000000000000',
   'coach.reed@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 92 Bowdoin College — Emily Cook
  (cuid272, '00000000-0000-0000-0000-000000000000',
   'coach.cook@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 93 Colby College — Samuel Morgan
  (cuid273, '00000000-0000-0000-0000-000000000000',
   'coach.smorgan@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 94 Haverford College — Rebecca Bell
  (cuid274, '00000000-0000-0000-0000-000000000000',
   'coach.rbell@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 95 Wesleyan University — Daniel Murphy
  (cuid275, '00000000-0000-0000-0000-000000000000',
   'coach.dmurphy@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 96 Macalester College — Sophia Rivera
  (cuid276, '00000000-0000-0000-0000-000000000000',
   'coach.srivera@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 97 Carnegie Mellon University — Nathan Hughes
  (cuid277, '00000000-0000-0000-0000-000000000000',
   'coach.hughes@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 98 Brandeis University — Grace Powell
  (cuid278, '00000000-0000-0000-0000-000000000000',
   'coach.powell@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 99 Johns Hopkins University — Adam Russell
  (cuid279, '00000000-0000-0000-0000-000000000000',
   'coach.russell@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  -- 100 Emory University — Victoria Price
  (cuid280, '00000000-0000-0000-0000-000000000000',
   'coach.vprice@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- ─── Auth Identities ──────────────────────────────────────────────────────────
-- provider_id MUST be the user UUID as text (NOT the email)
INSERT INTO auth.identities (
  id, user_id, provider_id, provider,
  identity_data, last_sign_in_at, created_at, updated_at
) VALUES
  (gen_random_uuid(), cuid201, cuid201::text, 'email', jsonb_build_object('sub', cuid201::text, 'email', 'coach.kelly@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid202, cuid202::text, 'email', jsonb_build_object('sub', cuid202::text, 'email', 'coach.swilliams@lanista.test'),        NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid203, cuid203::text, 'email', jsonb_build_object('sub', cuid203::text, 'email', 'coach.nolan@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid204, cuid204::text, 'email', jsonb_build_object('sub', cuid204::text, 'email', 'coach.dperez@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid205, cuid205::text, 'email', jsonb_build_object('sub', cuid205::text, 'email', 'coach.torres@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid206, cuid206::text, 'email', jsonb_build_object('sub', cuid206::text, 'email', 'coach.crivera@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid207, cuid207::text, 'email', jsonb_build_object('sub', cuid207::text, 'email', 'coach.rchen@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid208, cuid208::text, 'email', jsonb_build_object('sub', cuid208::text, 'email', 'coach.jmurphy@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid209, cuid209::text, 'email', jsonb_build_object('sub', cuid209::text, 'email', 'coach.santos@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid210, cuid210::text, 'email', jsonb_build_object('sub', cuid210::text, 'email', 'coach.randerson@lanista.test'),        NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid211, cuid211::text, 'email', jsonb_build_object('sub', cuid211::text, 'email', 'coach.ljohnson@lanista.test'),         NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid212, cuid212::text, 'email', jsonb_build_object('sub', cuid212::text, 'email', 'coach.park@lanista.test'),             NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid213, cuid213::text, 'email', jsonb_build_object('sub', cuid213::text, 'email', 'coach.schmidt@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid214, cuid214::text, 'email', jsonb_build_object('sub', cuid214::text, 'email', 'coach.mdavis@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid215, cuid215::text, 'email', jsonb_build_object('sub', cuid215::text, 'email', 'coach.jlopez@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid216, cuid216::text, 'email', jsonb_build_object('sub', cuid216::text, 'email', 'coach.bwalsh@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid217, cuid217::text, 'email', jsonb_build_object('sub', cuid217::text, 'email', 'coach.obrien@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid218, cuid218::text, 'email', jsonb_build_object('sub', cuid218::text, 'email', 'coach.zhang@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid219, cuid219::text, 'email', jsonb_build_object('sub', cuid219::text, 'email', 'coach.coleman@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid220, cuid220::text, 'email', jsonb_build_object('sub', cuid220::text, 'email', 'coach.rgreen@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid221, cuid221::text, 'email', jsonb_build_object('sub', cuid221::text, 'email', 'coach.pmartinez@lanista.test'),        NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid222, cuid222::text, 'email', jsonb_build_object('sub', cuid222::text, 'email', 'coach.gonzalez@lanista.test'),         NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid223, cuid223::text, 'email', jsonb_build_object('sub', cuid223::text, 'email', 'coach.aphillips@lanista.test'),        NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid224, cuid224::text, 'email', jsonb_build_object('sub', cuid224::text, 'email', 'coach.burke@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid225, cuid225::text, 'email', jsonb_build_object('sub', cuid225::text, 'email', 'coach.jrodriguez@lanista.test'),       NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid226, cuid226::text, 'email', jsonb_build_object('sub', cuid226::text, 'email', 'coach.nbrown@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid227, cuid227::text, 'email', jsonb_build_object('sub', cuid227::text, 'email', 'coach.thompson@lanista.test'),         NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid228, cuid228::text, 'email', jsonb_build_object('sub', cuid228::text, 'email', 'coach.cwhite@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid229, cuid229::text, 'email', jsonb_build_object('sub', cuid229::text, 'email', 'coach.harris@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid230, cuid230::text, 'email', jsonb_build_object('sub', cuid230::text, 'email', 'coach.dwilson@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid231, cuid231::text, 'email', jsonb_build_object('sub', cuid231::text, 'email', 'coach.taylor@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid232, cuid232::text, 'email', jsonb_build_object('sub', cuid232::text, 'email', 'coach.wclark@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid233, cuid233::text, 'email', jsonb_build_object('sub', cuid233::text, 'email', 'coach.moore@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid234, cuid234::text, 'email', jsonb_build_object('sub', cuid234::text, 'email', 'coach.ajackson@lanista.test'),         NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid235, cuid235::text, 'email', jsonb_build_object('sub', cuid235::text, 'email', 'coach.sdavis@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid236, cuid236::text, 'email', jsonb_build_object('sub', cuid236::text, 'email', 'coach.lee@lanista.test'),              NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid237, cuid237::text, 'email', jsonb_build_object('sub', cuid237::text, 'email', 'coach.mkim@lanista.test'),             NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid238, cuid238::text, 'email', jsonb_build_object('sub', cuid238::text, 'email', 'coach.tbrown@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid239, cuid239::text, 'email', jsonb_build_object('sub', cuid239::text, 'email', 'coach.adams@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid240, cuid240::text, 'email', jsonb_build_object('sub', cuid240::text, 'email', 'coach.garcia@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid241, cuid241::text, 'email', jsonb_build_object('sub', cuid241::text, 'email', 'coach.miller@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid242, cuid242::text, 'email', jsonb_build_object('sub', cuid242::text, 'email', 'coach.jmartin@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid243, cuid243::text, 'email', jsonb_build_object('sub', cuid243::text, 'email', 'coach.robinson@lanista.test'),         NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid244, cuid244::text, 'email', jsonb_build_object('sub', cuid244::text, 'email', 'coach.awalker@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid245, cuid245::text, 'email', jsonb_build_object('sub', cuid245::text, 'email', 'coach.hall@lanista.test'),             NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid246, cuid246::text, 'email', jsonb_build_object('sub', cuid246::text, 'email', 'coach.allen@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid247, cuid247::text, 'email', jsonb_build_object('sub', cuid247::text, 'email', 'coach.young@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid248, cuid248::text, 'email', jsonb_build_object('sub', cuid248::text, 'email', 'coach.khernandez@lanista.test'),       NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid249, cuid249::text, 'email', jsonb_build_object('sub', cuid249::text, 'email', 'coach.king@lanista.test'),             NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid250, cuid250::text, 'email', jsonb_build_object('sub', cuid250::text, 'email', 'coach.wright@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid251, cuid251::text, 'email', jsonb_build_object('sub', cuid251::text, 'email', 'coach.nscott@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid252, cuid252::text, 'email', jsonb_build_object('sub', cuid252::text, 'email', 'coach.dgreen@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid253, cuid253::text, 'email', jsonb_build_object('sub', cuid253::text, 'email', 'coach.padams@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid254, cuid254::text, 'email', jsonb_build_object('sub', cuid254::text, 'email', 'coach.baker@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid255, cuid255::text, 'email', jsonb_build_object('sub', cuid255::text, 'email', 'coach.nelson@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid256, cuid256::text, 'email', jsonb_build_object('sub', cuid256::text, 'email', 'coach.carter@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid257, cuid257::text, 'email', jsonb_build_object('sub', cuid257::text, 'email', 'coach.mitchell@lanista.test'),         NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid258, cuid258::text, 'email', jsonb_build_object('sub', cuid258::text, 'email', 'coach.lperez@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid259, cuid259::text, 'email', jsonb_build_object('sub', cuid259::text, 'email', 'coach.roberts@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid260, cuid260::text, 'email', jsonb_build_object('sub', cuid260::text, 'email', 'coach.turner@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid261, cuid261::text, 'email', jsonb_build_object('sub', cuid261::text, 'email', 'coach.rphillips@lanista.test'),        NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid262, cuid262::text, 'email', jsonb_build_object('sub', cuid262::text, 'email', 'coach.campbell@lanista.test'),         NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid263, cuid263::text, 'email', jsonb_build_object('sub', cuid263::text, 'email', 'coach.sanchez@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid264, cuid264::text, 'email', jsonb_build_object('sub', cuid264::text, 'email', 'coach.dparker@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid265, cuid265::text, 'email', jsonb_build_object('sub', cuid265::text, 'email', 'coach.evans@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid266, cuid266::text, 'email', jsonb_build_object('sub', cuid266::text, 'email', 'coach.edwards@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid267, cuid267::text, 'email', jsonb_build_object('sub', cuid267::text, 'email', 'coach.collins@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid268, cuid268::text, 'email', jsonb_build_object('sub', cuid268::text, 'email', 'coach.stewart@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid269, cuid269::text, 'email', jsonb_build_object('sub', cuid269::text, 'email', 'coach.morris@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid270, cuid270::text, 'email', jsonb_build_object('sub', cuid270::text, 'email', 'coach.arogers@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid271, cuid271::text, 'email', jsonb_build_object('sub', cuid271::text, 'email', 'coach.reed@lanista.test'),             NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid272, cuid272::text, 'email', jsonb_build_object('sub', cuid272::text, 'email', 'coach.cook@lanista.test'),             NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid273, cuid273::text, 'email', jsonb_build_object('sub', cuid273::text, 'email', 'coach.smorgan@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid274, cuid274::text, 'email', jsonb_build_object('sub', cuid274::text, 'email', 'coach.rbell@lanista.test'),            NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid275, cuid275::text, 'email', jsonb_build_object('sub', cuid275::text, 'email', 'coach.dmurphy@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid276, cuid276::text, 'email', jsonb_build_object('sub', cuid276::text, 'email', 'coach.srivera@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid277, cuid277::text, 'email', jsonb_build_object('sub', cuid277::text, 'email', 'coach.hughes@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid278, cuid278::text, 'email', jsonb_build_object('sub', cuid278::text, 'email', 'coach.powell@lanista.test'),           NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid279, cuid279::text, 'email', jsonb_build_object('sub', cuid279::text, 'email', 'coach.russell@lanista.test'),          NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid280, cuid280::text, 'email', jsonb_build_object('sub', cuid280::text, 'email', 'coach.vprice@lanista.test'),           NOW(), NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ─── Public Users ─────────────────────────────────────────────────────────────
INSERT INTO users (id, email, role, first_name, last_name, language, onboarding_complete)
VALUES
  (cuid201, 'coach.kelly@lanista.test',        'coach', 'Thomas',      'Kelly',      'en', true),
  (cuid202, 'coach.swilliams@lanista.test',    'coach', 'Sarah',       'Williams',   'en', true),
  (cuid203, 'coach.nolan@lanista.test',        'coach', 'John',        'Nolan',      'en', true),
  (cuid204, 'coach.dperez@lanista.test',       'coach', 'David',       'Perez',      'en', true),
  (cuid205, 'coach.torres@lanista.test',       'coach', 'Michael',     'Torres',     'en', true),
  (cuid206, 'coach.crivera@lanista.test',      'coach', 'Carlos',      'Rivera',     'es', true),
  (cuid207, 'coach.rchen@lanista.test',        'coach', 'Rebecca',     'Chen',       'en', true),
  (cuid208, 'coach.jmurphy@lanista.test',      'coach', 'James',       'Murphy',     'en', true),
  (cuid209, 'coach.santos@lanista.test',       'coach', 'Patricia',    'Santos',     'en', true),
  (cuid210, 'coach.randerson@lanista.test',    'coach', 'Robert',      'Anderson',   'en', true),
  (cuid211, 'coach.ljohnson@lanista.test',     'coach', 'Lisa',        'Johnson',    'en', true),
  (cuid212, 'coach.park@lanista.test',         'coach', 'Kevin',       'Park',       'en', true),
  (cuid213, 'coach.schmidt@lanista.test',      'coach', 'Amy',         'Schmidt',    'en', true),
  (cuid214, 'coach.mdavis@lanista.test',       'coach', 'Mark',        'Davis',      'en', true),
  (cuid215, 'coach.jlopez@lanista.test',       'coach', 'Jennifer',    'Lopez',      'es', true),
  (cuid216, 'coach.bwalsh@lanista.test',       'coach', 'Brian',       'Walsh',      'en', true),
  (cuid217, 'coach.obrien@lanista.test',       'coach', 'Daniel',      'O''Brien',   'en', true),
  (cuid218, 'coach.zhang@lanista.test',        'coach', 'Eric',        'Zhang',      'en', true),
  (cuid219, 'coach.coleman@lanista.test',      'coach', 'Steven',      'Coleman',    'en', true),
  (cuid220, 'coach.rgreen@lanista.test',       'coach', 'Rachel',      'Green',      'en', true),
  (cuid221, 'coach.pmartinez@lanista.test',    'coach', 'Paul',        'Martinez',   'es', true),
  (cuid222, 'coach.gonzalez@lanista.test',     'coach', 'Maria',       'Gonzalez',   'es', true),
  (cuid223, 'coach.aphillips@lanista.test',    'coach', 'Andrew',      'Phillips',   'en', true),
  (cuid224, 'coach.burke@lanista.test',        'coach', 'Christine',   'Burke',      'en', true),
  (cuid225, 'coach.jrodriguez@lanista.test',   'coach', 'Jose',        'Rodriguez',  'es', true),
  (cuid226, 'coach.nbrown@lanista.test',       'coach', 'Nathan',      'Brown',      'en', true),
  (cuid227, 'coach.thompson@lanista.test',     'coach', 'Laura',       'Thompson',   'en', true),
  (cuid228, 'coach.cwhite@lanista.test',       'coach', 'Christopher', 'White',      'en', true),
  (cuid229, 'coach.harris@lanista.test',       'coach', 'Stephanie',   'Harris',     'en', true),
  (cuid230, 'coach.dwilson@lanista.test',      'coach', 'Derek',       'Wilson',     'en', true),
  (cuid231, 'coach.taylor@lanista.test',       'coach', 'Amanda',      'Taylor',     'en', true),
  (cuid232, 'coach.wclark@lanista.test',       'coach', 'William',     'Clark',      'en', true),
  (cuid233, 'coach.moore@lanista.test',        'coach', 'Elizabeth',   'Moore',      'en', true),
  (cuid234, 'coach.ajackson@lanista.test',     'coach', 'Anthony',     'Jackson',    'en', true),
  (cuid235, 'coach.sdavis@lanista.test',       'coach', 'Sandra',      'Davis',      'en', true),
  (cuid236, 'coach.lee@lanista.test',          'coach', 'Richard',     'Lee',        'en', true),
  (cuid237, 'coach.mkim@lanista.test',         'coach', 'Michelle',    'Kim',        'en', true),
  (cuid238, 'coach.tbrown@lanista.test',       'coach', 'Timothy',     'Brown',      'en', true),
  (cuid239, 'coach.adams@lanista.test',        'coach', 'Catherine',   'Adams',      'en', true),
  (cuid240, 'coach.garcia@lanista.test',       'coach', 'Ronald',      'Garcia',     'es', true),
  (cuid241, 'coach.miller@lanista.test',       'coach', 'Frances',     'Miller',     'en', true),
  (cuid242, 'coach.jmartin@lanista.test',      'coach', 'Joseph',      'Martin',     'en', true),
  (cuid243, 'coach.robinson@lanista.test',     'coach', 'Diana',       'Robinson',   'en', true),
  (cuid244, 'coach.awalker@lanista.test',      'coach', 'Alan',        'Walker',     'en', true),
  (cuid245, 'coach.hall@lanista.test',         'coach', 'Barbara',     'Hall',       'en', true),
  (cuid246, 'coach.allen@lanista.test',        'coach', 'Christopher', 'Allen',      'en', true),
  (cuid247, 'coach.young@lanista.test',        'coach', 'Margaret',    'Young',      'en', true),
  (cuid248, 'coach.khernandez@lanista.test',   'coach', 'Kevin',       'Hernandez',  'es', true),
  (cuid249, 'coach.king@lanista.test',         'coach', 'Sharon',      'King',       'en', true),
  (cuid250, 'coach.wright@lanista.test',       'coach', 'Gary',        'Wright',     'en', true),
  (cuid251, 'coach.nscott@lanista.test',       'coach', 'Nicholas',    'Scott',      'en', true),
  (cuid252, 'coach.dgreen@lanista.test',       'coach', 'Donna',       'Green',      'en', true),
  (cuid253, 'coach.padams@lanista.test',       'coach', 'Peter',       'Adams',      'en', true),
  (cuid254, 'coach.baker@lanista.test',        'coach', 'Melissa',     'Baker',      'en', true),
  (cuid255, 'coach.nelson@lanista.test',       'coach', 'Robert',      'Nelson',     'en', true),
  (cuid256, 'coach.carter@lanista.test',       'coach', 'Jennifer',    'Carter',     'en', true),
  (cuid257, 'coach.mitchell@lanista.test',     'coach', 'Thomas',      'Mitchell',   'en', true),
  (cuid258, 'coach.lperez@lanista.test',       'coach', 'Linda',       'Perez',      'es', true),
  (cuid259, 'coach.roberts@lanista.test',      'coach', 'Steven',      'Roberts',    'en', true),
  (cuid260, 'coach.turner@lanista.test',       'coach', 'Karen',       'Turner',     'en', true),
  (cuid261, 'coach.rphillips@lanista.test',    'coach', 'Richard',     'Phillips',   'en', true),
  (cuid262, 'coach.campbell@lanista.test',     'coach', 'Patricia',    'Campbell',   'en', true),
  (cuid263, 'coach.sanchez@lanista.test',      'coach', 'Jose',        'Sanchez',    'es', true),
  (cuid264, 'coach.dparker@lanista.test',      'coach', 'Dorothy',     'Parker',     'en', true),
  (cuid265, 'coach.evans@lanista.test',        'coach', 'Frank',       'Evans',      'en', true),
  (cuid266, 'coach.edwards@lanista.test',      'coach', 'Susan',       'Edwards',    'en', true),
  (cuid267, 'coach.collins@lanista.test',      'coach', 'Charles',     'Collins',    'en', true),
  (cuid268, 'coach.stewart@lanista.test',      'coach', 'Helen',       'Stewart',    'en', true),
  (cuid269, 'coach.morris@lanista.test',       'coach', 'Matthew',     'Morris',     'en', true),
  (cuid270, 'coach.arogers@lanista.test',      'coach', 'Anna',        'Rogers',     'en', true),
  (cuid271, 'coach.reed@lanista.test',         'coach', 'Benjamin',    'Reed',       'en', true),
  (cuid272, 'coach.cook@lanista.test',         'coach', 'Emily',       'Cook',       'en', true),
  (cuid273, 'coach.smorgan@lanista.test',      'coach', 'Samuel',      'Morgan',     'en', true),
  (cuid274, 'coach.rbell@lanista.test',        'coach', 'Rebecca',     'Bell',       'en', true),
  (cuid275, 'coach.dmurphy@lanista.test',      'coach', 'Daniel',      'Murphy',     'en', true),
  (cuid276, 'coach.srivera@lanista.test',      'coach', 'Sophia',      'Rivera',     'es', true),
  (cuid277, 'coach.hughes@lanista.test',       'coach', 'Nathan',      'Hughes',     'en', true),
  (cuid278, 'coach.powell@lanista.test',       'coach', 'Grace',       'Powell',     'en', true),
  (cuid279, 'coach.russell@lanista.test',      'coach', 'Adam',        'Russell',    'en', true),
  (cuid280, 'coach.vprice@lanista.test',       'coach', 'Victoria',    'Price',      'en', true)
ON CONFLICT (id) DO NOTHING;

-- ─── Coach Profiles ───────────────────────────────────────────────────────────
-- school_name MUST exactly match schools.json entries
INSERT INTO coaches (
  id, user_id, school_name, division, state,
  primary_formation, gender_program, playing_styles,
  recruiting_class_years, min_gpa, is_published,
  bio, recruiting_notes
) VALUES

  -- ── D1 (21-70) ───────────────────────────────────────────────────────────────

  -- 21 University of Maryland — Thomas Kelly
  (coach201, cuid201, 'University of Maryland', 'D1', 'MD',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 22 Duke University — Sarah Williams
  (coach202, cuid202, 'Duke University', 'D1', 'NC',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 23 University of Notre Dame — John Nolan
  (coach203, cuid203, 'University of Notre Dame', 'D1', 'IN',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 24 Ohio State University — David Perez
  (coach204, cuid204, 'Ohio State University', 'D1', 'OH',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 25 Penn State University — Michael Torres
  (coach205, cuid205, 'Penn State University', 'D1', 'PA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 26 UCLA — Carlos Rivera
  (coach206, cuid206, 'UCLA', 'D1', 'CA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 27 UC Santa Barbara — Rebecca Chen
  (coach207, cuid207, 'UC Santa Barbara', 'D1', 'CA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 28 University of Akron — James Murphy
  (coach208, cuid208, 'University of Akron', 'D1', 'OH',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 29 UConn — Patricia Santos
  (coach209, cuid209, 'UConn', 'D1', 'CT',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 30 University of Michigan — Robert Anderson
  (coach210, cuid210, 'University of Michigan', 'D1', 'MI',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 31 Michigan State University — Lisa Johnson
  (coach211, cuid211, 'Michigan State University', 'D1', 'MI',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 32 Northwestern University — Kevin Park
  (coach212, cuid212, 'Northwestern University', 'D1', 'IL',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 33 University of Wisconsin — Amy Schmidt
  (coach213, cuid213, 'University of Wisconsin', 'D1', 'WI',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 34 Virginia Tech — Mark Davis
  (coach214, cuid214, 'Virginia Tech', 'D1', 'VA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 35 NC State University — Jennifer Lopez
  (coach215, cuid215, 'NC State University', 'D1', 'NC',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 36 University of Pittsburgh — Brian Walsh
  (coach216, cuid216, 'University of Pittsburgh', 'D1', 'PA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 37 Boston College — Daniel O'Brien
  (coach217, cuid217, 'Boston College', 'D1', 'MA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 38 Rutgers University — Eric Zhang
  (coach218, cuid218, 'Rutgers University', 'D1', 'NJ',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 39 West Virginia University — Steven Coleman
  (coach219, cuid219, 'West Virginia University', 'D1', 'WV',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 40 University of Colorado — Rachel Green
  (coach220, cuid220, 'University of Colorado', 'D1', 'CO',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 41 Creighton University — Paul Martinez
  (coach221, cuid221, 'Creighton University', 'D1', 'NE',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 42 University of Portland — Maria Gonzalez
  (coach222, cuid222, 'University of Portland', 'D1', 'OR',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 43 University of Denver — Andrew Phillips
  (coach223, cuid223, 'University of Denver', 'D1', 'CO',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 44 Gonzaga University — Christine Burke
  (coach224, cuid224, 'Gonzaga University', 'D1', 'WA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 45 University of New Mexico — Jose Rodriguez
  (coach225, cuid225, 'University of New Mexico', 'D1', 'NM',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 46 SMU — Nathan Brown
  (coach226, cuid226, 'SMU', 'D1', 'TX',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 47 TCU — Laura Thompson
  (coach227, cuid227, 'TCU', 'D1', 'TX',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 48 Baylor University — Christopher White
  (coach228, cuid228, 'Baylor University', 'D1', 'TX',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 49 University of Kentucky — Stephanie Harris
  (coach229, cuid229, 'University of Kentucky', 'D1', 'KY',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 50 University of South Carolina — Derek Wilson
  (coach230, cuid230, 'University of South Carolina', 'D1', 'SC',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 51 University of Tulsa — Amanda Taylor
  (coach231, cuid231, 'University of Tulsa', 'D1', 'OK',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 52 University of Minnesota — William Clark
  (coach232, cuid232, 'University of Minnesota', 'D1', 'MN',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 53 University of Iowa — Elizabeth Moore
  (coach233, cuid233, 'University of Iowa', 'D1', 'IA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 54 Florida State University — Anthony Jackson
  (coach234, cuid234, 'Florida State University', 'D1', 'FL',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 55 University of Tennessee — Sandra Davis
  (coach235, cuid235, 'University of Tennessee', 'D1', 'TN',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 56 University of Arizona — Richard Lee
  (coach236, cuid236, 'University of Arizona', 'D1', 'AZ',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 57 University of Washington — Michelle Kim
  (coach237, cuid237, 'University of Washington', 'D1', 'WA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 58 Oregon State University — Timothy Brown
  (coach238, cuid238, 'Oregon State University', 'D1', 'OR',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 59 UC Davis — Catherine Adams
  (coach239, cuid239, 'UC Davis', 'D1', 'CA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 60 San Jose State University — Ronald Garcia
  (coach240, cuid240, 'San Jose State University', 'D1', 'CA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 61 UNLV — Frances Miller
  (coach241, cuid241, 'UNLV', 'D1', 'NV',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 62 Xavier University — Joseph Martin
  (coach242, cuid242, 'Xavier University', 'D1', 'OH',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 63 Butler University — Diana Robinson
  (coach243, cuid243, 'Butler University', 'D1', 'IN',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 64 Loyola University Chicago — Alan Walker
  (coach244, cuid244, 'Loyola University Chicago', 'D1', 'IL',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 65 Providence College — Barbara Hall
  (coach245, cuid245, 'Providence College', 'D1', 'RI',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 66 University of San Diego — Christopher Allen
  (coach246, cuid246, 'University of San Diego', 'D1', 'CA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 67 Furman University — Margaret Young
  (coach247, cuid247, 'Furman University', 'D1', 'SC',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 68 James Madison University — Kevin Hernandez
  (coach248, cuid248, 'James Madison University', 'D1', 'VA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 69 Old Dominion University — Sharon King
  (coach249, cuid249, 'Old Dominion University', 'D1', 'VA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 70 University of Missouri — Gary Wright
  (coach250, cuid250, 'University of Missouri', 'D1', 'MO',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- ── D2 (71-88) ───────────────────────────────────────────────────────────────

  -- 71 University of Tampa — Nicholas Scott
  (coach251, cuid251, 'University of Tampa', 'D2', 'FL',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 72 Florida Southern College — Donna Green
  (coach252, cuid252, 'Florida Southern College', 'D2', 'FL',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 73 Rollins College — Peter Adams
  (coach253, cuid253, 'Rollins College', 'D2', 'FL',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 74 Rockhurst University — Melissa Baker
  (coach254, cuid254, 'Rockhurst University', 'D2', 'MO',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 75 Drury University — Robert Nelson
  (coach255, cuid255, 'Drury University', 'D2', 'MO',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 76 Colorado School of Mines — Jennifer Carter
  (coach256, cuid256, 'Colorado School of Mines', 'D2', 'CO',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 77 Fort Hays State University — Thomas Mitchell
  (coach257, cuid257, 'Fort Hays State University', 'D2', 'KS',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 78 Adelphi University — Linda Perez
  (coach258, cuid258, 'Adelphi University', 'D2', 'NY',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 79 Assumption University — Steven Roberts
  (coach259, cuid259, 'Assumption University', 'D2', 'MA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 80 Le Moyne College — Karen Turner
  (coach260, cuid260, 'Le Moyne College', 'D2', 'NY',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 81 University of Indianapolis — Richard Phillips
  (coach261, cuid261, 'University of Indianapolis', 'D2', 'IN',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 82 Ashland University — Patricia Campbell
  (coach262, cuid262, 'Ashland University', 'D2', 'OH',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 83 West Texas A&M University — Jose Sanchez
  (coach263, cuid263, 'West Texas A&M University', 'D2', 'TX',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 84 Bellarmine University — Dorothy Parker
  (coach264, cuid264, 'Bellarmine University', 'D2', 'KY',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 85 Wingate University — Frank Evans
  (coach265, cuid265, 'Wingate University', 'D2', 'NC',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 86 University of Wisconsin-Parkside — Susan Edwards
  (coach266, cuid266, 'University of Wisconsin-Parkside', 'D2', 'WI',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 87 Saint Leo University — Charles Collins
  (coach267, cuid267, 'Saint Leo University', 'D2', 'FL',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 88 Mercy University — Helen Stewart
  (coach268, cuid268, 'Mercy University', 'D2', 'NY',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- ── D3 (89-100) ──────────────────────────────────────────────────────────────

  -- 89 Trinity College — Matthew Morris
  (coach269, cuid269, 'Trinity College', 'D3', 'CT',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 90 Connecticut College — Anna Rogers
  (coach270, cuid270, 'Connecticut College', 'D3', 'CT',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 91 Dickinson College — Benjamin Reed
  (coach271, cuid271, 'Dickinson College', 'D3', 'PA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 92 Bowdoin College — Emily Cook
  (coach272, cuid272, 'Bowdoin College', 'D3', 'ME',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 93 Colby College — Samuel Morgan
  (coach273, cuid273, 'Colby College', 'D3', 'ME',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 94 Haverford College — Rebecca Bell
  (coach274, cuid274, 'Haverford College', 'D3', 'PA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 95 Wesleyan University — Daniel Murphy
  (coach275, cuid275, 'Wesleyan University', 'D3', 'CT',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 96 Macalester College — Sophia Rivera
  (coach276, cuid276, 'Macalester College', 'D3', 'MN',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 97 Carnegie Mellon University — Nathan Hughes
  (coach277, cuid277, 'Carnegie Mellon University', 'D3', 'PA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 98 Brandeis University — Grace Powell
  (coach278, cuid278, 'Brandeis University', 'D3', 'MA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 99 Johns Hopkins University — Adam Russell
  (coach279, cuid279, 'Johns Hopkins University', 'D3', 'MD',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL),

  -- 100 Emory University — Victoria Price
  (coach280, cuid280, 'Emory University', 'D3', 'GA',
   '4-3-3', 'male', NULL, ARRAY[2026, 2027, 2028], 2.0, true, NULL, NULL)

ON CONFLICT (id) DO NOTHING;

END $$;

SET session_replication_role = DEFAULT;
