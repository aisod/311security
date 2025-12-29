CREATE TABLE proximity_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crime_report_id UUID NOT NULL REFERENCES crime_reports(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    distance_meters DOUBLE PRECISION NOT NULL,
    radius_meters DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'delivered', 'dismissed')),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX uniq_proximity_alert_report_user
    ON proximity_alerts (crime_report_id, target_user_id);

