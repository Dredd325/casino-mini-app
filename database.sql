-- =============================================
-- БАЗА ДАННЫХ WIN TON CASINO
-- =============================================

-- Удаляем таблицы если есть (для чистого старта)
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS bets;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS game_settings;

-- =============================================
-- ТАБЛИЦА ПОЛЬЗОВАТЕЛЕЙ
-- =============================================
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    telegram_id TEXT UNIQUE NOT NULL,
    username TEXT,
    first_name TEXT NOT NULL,
    last_name TEXT,
    avatar TEXT,
    balance REAL DEFAULT 100.0,
    total_sent REAL DEFAULT 0.0,
    total_won REAL DEFAULT 0.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_active DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- ТАБЛИЦА СТАВОК
-- =============================================
CREATE TABLE bets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =============================================
-- ТАБЛИЦА ТРАНЗАКЦИЙ (ПОПОЛНЕНИЙ)
-- =============================================
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    tx_hash TEXT UNIQUE,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    confirmed_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =============================================
-- ТАБЛИЦА НАСТРОЕК ИГРЫ
-- =============================================
CREATE TABLE game_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- ТАБЛИЦА ИСТОРИИ КОРОЛЕЙ
-- =============================================
CREATE TABLE king_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    total_pool REAL NOT NULL,
    crowned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =============================================
-- ИНДЕКСЫ ДЛЯ БЫСТРОГО ПОИСКА
-- =============================================
CREATE INDEX idx_users_telegram ON users(telegram_id);
CREATE INDEX idx_bets_user ON bets(user_id);
CREATE INDEX idx_bets_created ON bets(created_at);
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_hash ON transactions(tx_hash);

-- =============================================
-- НАЧАЛЬНЫЕ НАСТРОЙКИ
-- =============================================
INSERT INTO game_settings (key, value) VALUES 
    ('king_end_time', strftime('%s', 'now', '+200 hours')),
    ('total_pool', '0'),
    ('total_royalty', '0'),
    ('min_bet', '0.01'),
    ('game_version', '1.0.0');

-- =============================================
-- ТЕСТОВЫЕ ДАННЫЕ (можно удалить потом)
-- =============================================
INSERT INTO users (telegram_id, first_name, username, balance, total_sent) VALUES
    ('123456789', 'Игрок 1', 'player1', 150.0, 50.0),
    ('987654321', 'Игрок 2', 'player2', 200.0, 75.5),
    ('456789123', 'Игрок 3', 'player3', 300.0, 120.0),
    ('789123456', 'Игрок 4', 'player4', 80.0, 25.0),
    ('321654987', 'Игрок 5', 'player5', 500.0, 250.0);

INSERT INTO bets (user_id, amount) VALUES
    (1, 10.0), (1, 15.0), (1, 25.0),
    (2, 30.0), (2, 45.5),
    (3, 50.0), (3, 70.0),
    (4, 25.0),
    (5, 100.0), (5, 150.0);

-- =============================================
-- ПРЕДСТАВЛЕНИЕ ДЛЯ ТОП-50
-- =============================================
CREATE VIEW top_50 AS
SELECT 
    u.id,
    u.first_name || ' ' || COALESCE(u.last_name, '') as full_name,
    u.username,
    u.avatar,
    COUNT(b.id) as bets_count,
    SUM(b.amount) as total_amount,
    RANK() OVER (ORDER BY SUM(b.amount) DESC) as rank_position
FROM users u
LEFT JOIN bets b ON u.id = b.user_id
GROUP BY u.id
HAVING total_amount > 0
ORDER BY total_amount DESC
LIMIT 50;

-- =============================================
-- ТРИГГЕР ДЛЯ ОБНОВЛЕНИЯ total_sent
-- =============================================
CREATE TRIGGER update_user_total_sent
AFTER INSERT ON bets
BEGIN
    UPDATE users 
    SET total_sent = total_sent + NEW.amount,
        balance = balance - NEW.amount
    WHERE id = NEW.user_id;
END;

-- =============================================
-- ТРИГГЕР ДЛЯ ОБНОВЛЕНИЯ total_pool
-- =============================================
CREATE TRIGGER update_game_stats
AFTER INSERT ON bets
BEGIN
    UPDATE game_settings 
    SET value = value + NEW.amount
    WHERE key = 'total_pool';
    
    UPDATE game_settings 
    SET value = value + (NEW.amount * 0.1)
    WHERE key = 'total_royalty';
END;

-- =============================================
-- ПРОВЕРОЧНЫЕ ЗАПРОСЫ
-- =============================================
-- SELECT * FROM top_50;
-- SELECT * FROM game_settings;