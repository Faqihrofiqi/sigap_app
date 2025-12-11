-- ============================================
-- Function: Get Server Time
-- Mengembalikan waktu server dalam timezone lokal (Asia/Jakarta)
-- ============================================

CREATE OR REPLACE FUNCTION get_server_time()
RETURNS JSON AS $$
BEGIN
    RETURN json_build_object(
        'server_time_utc', CURRENT_TIMESTAMP,
        'server_time_local', (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Jakarta'),
        'timezone', 'Asia/Jakarta',
        'timezone_offset', '+07:00',
        'day_of_week', EXTRACT(DOW FROM (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Jakarta')),
        'date', (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Jakarta')::DATE,
        'time', (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Jakarta')::TIME
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_server_time TO authenticated;
GRANT EXECUTE ON FUNCTION get_server_time TO anon;

-- Verifikasi
SELECT 'Function get_server_time created' as status;

