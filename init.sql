CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER DEFAULT 1,
    account_number VARCHAR(20) DEFAULT 'ACC-001',
    balance DECIMAL(19,4) DEFAULT 10000.0000,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO accounts (user_id, account_number, balance) 
VALUES (1, 'ACC-001', 10000.00)
ON CONFLICT DO NOTHING;