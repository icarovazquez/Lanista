-- Migration 038: Fix coach password hash
-- Previous migrations used a corrupted bcrypt hash (! in password caused shell issues).
-- This sets the correct hash for password: Lanista2026!

UPDATE auth.users
SET
  encrypted_password = '$2b$10$rYIcCIcvWMR6sef50nC7kuzX1jScEbOXjX0j.Il0H5V0TGjIsSMim',
  updated_at = NOW()
WHERE email LIKE '%coach.%@lanista.test';
