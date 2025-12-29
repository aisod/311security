CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    related_entity_id UUID,
    related_entity_type TEXT,
    metadata JSONB,
    action_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);