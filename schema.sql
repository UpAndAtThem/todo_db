CREATE TABLE lists(
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE todos(
  id serial PRIMARY KEY,
  list_id int NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
  name text NOT NULL,
  completed boolean NOT NULL DEFAULT 'f'
);