ALTER PUBLICATION supabase_realtime ADD TABLE booking;
SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
