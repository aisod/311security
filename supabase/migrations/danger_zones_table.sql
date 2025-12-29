-- Create danger_zones table for storing high-risk areas
-- This table enables admins to mark dangerous locations on the map
-- Users will receive alerts when entering these areas

CREATE TABLE IF NOT EXISTS danger_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Basic info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Geometry type: 'circle' or 'polygon'
    geometry_type VARCHAR(20) NOT NULL DEFAULT 'circle',
    
    -- Circle geometry fields
    center_latitude DOUBLE PRECISION,
    center_longitude DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION,
    
    -- Polygon geometry (stored as JSONB array of {lat, lng} objects)
    polygon_points JSONB,
    
    -- Crime information
    crime_types TEXT[] NOT NULL DEFAULT ARRAY['general'],  -- Array of crime types
    risk_level VARCHAR(20) NOT NULL DEFAULT 'medium',  -- 'low', 'medium', 'high', 'critical'
    warning_message TEXT,
    safety_tips TEXT,
    
    -- Time-based activity
    active_hours TEXT[],  -- Array of time ranges like ["18:00-06:00", "weekends"]
    is_always_active BOOLEAN DEFAULT true,
    
    -- Statistics
    incident_count INTEGER DEFAULT 0,
    last_incident_date TIMESTAMPTZ,
    
    -- Location metadata
    region VARCHAR(100),
    city VARCHAR(100),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    
    -- Constraints
    CONSTRAINT valid_geometry_type CHECK (geometry_type IN ('circle', 'polygon')),
    CONSTRAINT valid_risk_level CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT valid_circle_geometry CHECK (
        geometry_type != 'circle' OR 
        (center_latitude IS NOT NULL AND center_longitude IS NOT NULL AND radius_meters IS NOT NULL)
    ),
    CONSTRAINT valid_polygon_geometry CHECK (
        geometry_type != 'polygon' OR polygon_points IS NOT NULL
    )
);

-- Create indexes for performance
CREATE INDEX idx_danger_zones_active ON danger_zones(is_active) WHERE is_active = true;
CREATE INDEX idx_danger_zones_risk_level ON danger_zones(risk_level);
CREATE INDEX idx_danger_zones_region ON danger_zones(region);
CREATE INDEX idx_danger_zones_city ON danger_zones(city);
CREATE INDEX idx_danger_zones_location ON danger_zones(center_latitude, center_longitude) 
    WHERE geometry_type = 'circle';

-- Enable Row Level Security
ALTER TABLE danger_zones ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view active danger zones
CREATE POLICY "Anyone can view active danger zones" ON danger_zones
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can view all danger zones
CREATE POLICY "Admins can view all danger zones" ON danger_zones
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Policy: Admins can create danger zones
CREATE POLICY "Admins can create danger zones" ON danger_zones
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Policy: Admins can update danger zones
CREATE POLICY "Admins can update danger zones" ON danger_zones
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Policy: Super admins can delete danger zones
CREATE POLICY "Super admins can delete danger zones" ON danger_zones
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'super_admin'
        )
    );

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_danger_zones_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_danger_zones_updated_at
    BEFORE UPDATE ON danger_zones
    FOR EACH ROW
    EXECUTE FUNCTION update_danger_zones_updated_at();

-- Create table for tracking user danger zone entries (for analytics)
CREATE TABLE IF NOT EXISTS danger_zone_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) NOT NULL,
    danger_zone_id UUID REFERENCES danger_zones(id) NOT NULL,
    entered_at TIMESTAMPTZ DEFAULT NOW(),
    exited_at TIMESTAMPTZ,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for entries
CREATE INDEX idx_danger_zone_entries_user ON danger_zone_entries(user_id);
CREATE INDEX idx_danger_zone_entries_zone ON danger_zone_entries(danger_zone_id);
CREATE INDEX idx_danger_zone_entries_time ON danger_zone_entries(entered_at DESC);

-- Enable RLS for entries
ALTER TABLE danger_zone_entries ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see their own entries
CREATE POLICY "Users can view their own entries" ON danger_zone_entries
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Policy: System can create entries for any user
CREATE POLICY "System can create entries" ON danger_zone_entries
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Policy: System can update entries
CREATE POLICY "System can update entries" ON danger_zone_entries
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid());

-- Policy: Admins can view all entries
CREATE POLICY "Admins can view all entries" ON danger_zone_entries
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Comment on table
COMMENT ON TABLE danger_zones IS 'Stores dangerous areas marked by admins. Users receive alerts when entering these zones.';
COMMENT ON TABLE danger_zone_entries IS 'Tracks when users enter/exit danger zones for analytics and safety monitoring.';





