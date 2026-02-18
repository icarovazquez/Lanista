-- Notifications
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,
  title       TEXT NOT NULL,
  title_es    TEXT,
  body        TEXT,
  body_es     TEXT,
  data        JSONB,
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  sent_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User subscriptions
CREATE TABLE subscriptions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stripe_customer_id      TEXT,
  stripe_subscription_id  TEXT,
  tier                    TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium', 'institutional')),
  status                  TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'past_due', 'cancelled', 'trialing')),
  current_period_end      TIMESTAMPTZ,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Device tokens for push notifications
CREATE TABLE device_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);

-- Legal consent tracking
CREATE TABLE user_legal_consents (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  document_type       TEXT NOT NULL,
  document_version    TEXT NOT NULL,
  consented_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  consent_ip_address  INET
);

-- Parental consent for under-13
CREATE TABLE parental_consents (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_user_id    UUID NOT NULL REFERENCES users(id),
  child_user_id     UUID NOT NULL REFERENCES users(id),
  consent_version   TEXT NOT NULL,
  consent_given_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  consent_ip_address INET,
  consent_method    TEXT,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  revoked_at        TIMESTAMPTZ
);

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_legal_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE parental_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_own" ON notifications FOR ALL USING (user_id = auth.uid());
CREATE POLICY "subscriptions_own" ON subscriptions FOR ALL USING (user_id = auth.uid());
CREATE POLICY "device_tokens_own" ON device_tokens FOR ALL USING (user_id = auth.uid());
CREATE POLICY "legal_consents_own" ON user_legal_consents FOR ALL USING (user_id = auth.uid());
CREATE POLICY "parental_consents_own" ON parental_consents FOR ALL
  USING (parent_user_id = auth.uid() OR child_user_id = auth.uid());
