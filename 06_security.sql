ALTER TABLE airport        ENABLE ROW LEVEL SECURITY;
ALTER TABLE aircraft_model ENABLE ROW LEVEL SECURITY;
ALTER TABLE aircraft       ENABLE ROW LEVEL SECURITY;
ALTER TABLE seat           ENABLE ROW LEVEL SECURITY;
ALTER TABLE flight         ENABLE ROW LEVEL SECURITY;
ALTER TABLE passenger      ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking        ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read" ON airport        FOR SELECT TO anon USING (true);
CREATE POLICY "public read" ON aircraft_model FOR SELECT TO anon USING (true);
CREATE POLICY "public read" ON aircraft       FOR SELECT TO anon USING (true);
CREATE POLICY "public read" ON seat           FOR SELECT TO anon USING (true);
CREATE POLICY "public read" ON flight         FOR SELECT TO anon USING (true);

CREATE POLICY "public read" ON booking FOR SELECT TO anon USING (true);
REVOKE SELECT ON booking FROM anon;
GRANT  SELECT (flight_id, seat_id, status) ON booking TO anon;
