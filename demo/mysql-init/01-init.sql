-- Initialization script for demo application database
-- This script runs when MySQL container starts for the first time

USE demoapp;

-- Set time zone
SET time_zone = '+00:00';

-- Create indexes for better performance
-- These will be created automatically by Hibernate, but we can pre-create them

-- Uncomment these if you want to pre-create indexes
-- CREATE INDEX idx_users_username ON users(username);
-- CREATE INDEX idx_users_email ON users(email);
-- CREATE INDEX idx_blogs_author ON blogs(author_id);
-- CREATE INDEX idx_blogs_created_at ON blogs(created_at);

-- Insert some initial data (optional)
-- Note: This will only run if tables don't exist yet
-- Hibernate will create the tables automatically

-- Example: Insert admin user (password is "admin123" encoded)
-- INSERT IGNORE INTO users (username, email, password, role, created_at) 
-- VALUES ('admin', 'admin@demo.com', '$2a$10$EIXz8TQLb/.LyNKdLGJL4ejsEeBnQGMGG8PEhNsUhClxFDRf1hHj6', 'ADMIN', NOW());

-- Insert sample blog posts after user creation
-- Note: This is just an example and may need to be adjusted based on your user table structure

COMMIT;