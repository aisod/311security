CREATE TYPE missing_report_type AS ENUM ('missing_person', 'lost_item', 'found_person');
CREATE TYPE missing_report_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TABLE missing_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    report_type missing_report_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    person_name TEXT,
    age INTEGER,
    last_seen_location TEXT,
    last_seen_date TIMESTAMPTZ,
    contact_phone TEXT,
    contact_email TEXT,
    photo_urls TEXT[],
    admin_notes TEXT,
    status missing_report_status DEFAULT 'pending',
    approved_by UUID REFERENCES profiles(id),
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_missing_reports_status ON missing_reports(status);
CREATE INDEX idx_missing_reports_created_at ON missing_reports(created_at DESC);

