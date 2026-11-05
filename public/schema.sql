
PRAGMA foreign_keys = ON;

-- =====================================
-- HOMEPROOF DATABASE
-- =====================================

-- 1. CUSTOMER ACCOUNTS
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password_hash TEXT NOT NULL,
    full_name TEXT,
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. HOUSEHOLDS
CREATE TABLE IF NOT EXISTS households (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (owner_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 3. HOUSEHOLD MEMBERS
CREATE TABLE IF NOT EXISTS household_members (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'member'
        CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (household_id, user_id),

    FOREIGN KEY (household_id)
        REFERENCES households(id) ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 4. PROPERTIES
CREATE TABLE IF NOT EXISTS properties (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    name TEXT NOT NULL,
    property_type TEXT DEFAULT 'house',
    address TEXT,
    city TEXT,
    region TEXT,
    postal_code TEXT,
    country TEXT NOT NULL DEFAULT 'US',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (household_id)
        REFERENCES households(id) ON DELETE CASCADE
);

-- 5. ROOMS
CREATE TABLE IF NOT EXISTS rooms (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (property_id)
        REFERENCES properties(id) ON DELETE CASCADE
);

-- 6. HOUSEHOLD ITEMS
CREATE TABLE IF NOT EXISTS inventory_items (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    room_id TEXT,
    name TEXT NOT NULL,
    category TEXT,
    description TEXT,
    brand TEXT,
    model TEXT,
    serial_number TEXT,
    purchase_price REAL DEFAULT 0,
    replacement_value REAL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'USD',
    purchase_date TEXT,
    condition TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (property_id)
        REFERENCES properties(id) ON DELETE CASCADE,

    FOREIGN KEY (room_id)
        REFERENCES rooms(id) ON DELETE SET NULL
);

-- 7. DOCUMENT AND PHOTO STORAGE
CREATE TABLE IF NOT EXISTS files (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    item_id TEXT,
    uploaded_by TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_name TEXT NOT NULL,
    object_key TEXT NOT NULL UNIQUE,
    mime_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (property_id)
        REFERENCES properties(id) ON DELETE CASCADE,

    FOREIGN KEY (item_id)
        REFERENCES inventory_items(id) ON DELETE CASCADE,

    FOREIGN KEY (uploaded_by)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 8. AUTHENTICATION SESSIONS
CREATE TABLE IF NOT EXISTS auth_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 9. EMAIL VERIFICATION TOKENS
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 10. PASSWORD RESET TOKENS
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    used INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 11. PAYMENTS
CREATE TABLE IF NOT EXISTS payments (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    household_id TEXT NOT NULL,
    plan TEXT NOT NULL CHECK (plan IN ('basic', 'premium')),
    amount INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    provider TEXT NOT NULL DEFAULT 'paystack',
    provider_reference TEXT UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'successful', 'failed', 'refunded')),
    access_granted_at TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE RESTRICT,

    FOREIGN KEY (household_id)
        REFERENCES households(id) ON DELETE RESTRICT
);

-- 12. HOUSEHOLD ACCESS PLANS
CREATE TABLE IF NOT EXISTS household_entitlements (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL UNIQUE,
    plan TEXT NOT NULL DEFAULT 'free'
        CHECK (plan IN ('free', 'basic', 'premium')),
    payment_id TEXT,
    purchased_at TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (household_id)
        REFERENCES households(id) ON DELETE CASCADE,

    FOREIGN KEY (payment_id)
        REFERENCES payments(id) ON DELETE SET NULL
);

-- 13. PAYMENT WEBHOOK EVENTS
CREATE TABLE IF NOT EXISTS payment_events (
    id TEXT PRIMARY KEY,
    provider_event_id TEXT NOT NULL UNIQUE,
    provider TEXT NOT NULL,
    event_type TEXT NOT NULL,
    processed INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 14. FAMILY INVITATIONS
CREATE TABLE IF NOT EXISTS invitations (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    email TEXT NOT NULL COLLATE NOCASE,
    role TEXT NOT NULL DEFAULT 'member'
        CHECK (role IN ('admin', 'member', 'viewer')),
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    accepted_at TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (household_id)
        REFERENCES households(id) ON DELETE CASCADE
);

-- =====================================
-- PERFORMANCE INDEXES
-- =====================================

CREATE INDEX IF NOT EXISTS idx_users_email
ON users(email);

CREATE INDEX IF NOT EXISTS idx_household_members_user
ON household_members(user_id);

CREATE INDEX IF NOT EXISTS idx_properties_household
ON properties(household_id);

CREATE INDEX IF NOT EXISTS idx_rooms_property
ON rooms(property_id);

CREATE INDEX IF NOT EXISTS idx_items_property
ON inventory_items(property_id);

CREATE INDEX IF NOT EXISTS idx_items_room
ON inventory_items(room_id);

CREATE INDEX IF NOT EXISTS idx_files_property
ON files(property_id);

CREATE INDEX IF NOT EXISTS idx_files_item
ON files(item_id);

CREATE INDEX IF NOT EXISTS idx_sessions_user
ON auth_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_sessions_expiry
ON auth_sessions(expires_at);

CREATE INDEX IF NOT EXISTS idx_payments_user
ON payments(user_id);

CREATE INDEX IF NOT EXISTS idx_payments_household
ON payments(household_id);

CREATE INDEX IF NOT EXISTS idx_payments_status
ON payments(status);

CREATE INDEX IF NOT EXISTS idx_invitations_household
ON invitations(household_id);

-- =====================================
-- DATABASE INITIALIZATION COMPLETE
-- =====================================
