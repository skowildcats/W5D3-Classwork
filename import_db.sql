PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  users_id INTEGER NOT NULL,
  FOREIGN KEY (users_id) REFERENCES users(id)
);

CREATE TABLE questions_follows (
  id INTEGER PRIMARY KEY,
  users_id INTEGER NOT NULL,
  questions_id INTEGER NOT NULL,
  FOREIGN KEY (users_id) REFERENCES users(id),
  FOREIGN KEY (questions_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  replies_id INTEGER NOT NULL,
  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (users_id) REFERENCES users(id),
  FOREIGN KEY (replies_id) REFERENCES replies(id)
);

CREATE TABLE questions_likes (
  id INTEGER PRIMARY KEY,
  users_id INTEGER NOT NULL,
  questions_id INTEGER NOT NULL,
  FOREIGN KEY (users_id) REFERENCES users(id),
  FOREIGN KEY (questions_id) REFERENCES questions(id)
);

-- question 
--  ^ reply (id = 1, replies_id = NULL) 
--     ^ reply (id = 2, replies_id = 1)
--  ^ reply(id = 3, replies_id = NULL)
--     ^ reply (id = 4, replies_id = 3)
-- INSERT INTO 
--   users (fname, lname)
-- VALUES
--   ('Sohrob', 'Ibrahimi'),
--   ('Jonathan', 'Chen');

-- INSERT INTO 
--   questions(title, body, users_id)
-- VALUES
--   ('What day is it today?', 'I am curious', (SELECT id FROM users WHERE fname = 'Sohrob')),
--   ('How far is the moon?', 'I am also curious',(SELECT id FROM users WHERE fname = 'Jonathan'))

