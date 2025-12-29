-- STEP 1: RUN THIS FIRST
-- Add the 'approved' value to the enum.
-- This must be committed before it can be used in Step 2.

ALTER TYPE crime_status ADD VALUE IF NOT EXISTS 'approved';

