require 'pg'
require 'pry'

class DatabasePersistence

  def initialize(logger)
    @db = if Sinatra::Base.production?
                  PG.connect(ENV['DATABASE_URL'])
                else
                  PG.connect(dbname: "todos")
                end

    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = <<~LISTS
      SELECT l.*, COUNT(completed) AS "total_todos", COUNT(NULLIF(t.completed, true)) AS "incomplete_todos"
      FROM lists l
      LEFT JOIN todos t ON l.id = t.list_id
      GROUP BY l.name, l.id;
    LISTS

    result = query sql

    x = result.map do |tuple|
      list_id = tuple["id"].to_i

      {id: list_id, 
       name: tuple["name"], 
       total_todos_count: tuple["total_todos"], 
       incomplete_todos_count: tuple["incomplete_todos"]}
    end
  end

  def find_list(id)
    sql = <<~LISTS
      SELECT l.*, COUNT(completed) AS "total_todos", COUNT(NULLIF(t.completed, true)) AS "incomplete_todos"
      FROM lists l
      LEFT JOIN todos t ON l.id = t.list_id
      WHERE l.id = $1
      GROUP BY l.name, l.id;
    LISTS

    total_and_completed = query sql, id

    res = total_and_completed.map do |t| 
      {id: t["id"], name: t["name"], total_todos_count: t["total_todos"],
       incomplete_todos_count: t["incomplete_todos"]}
    end.first

    res
  end

  def create_list(list_name)
    create_list_sql = "INSERT INTO lists (name) VALUES ($1)"
    query create_list_sql, list_name
  end

  def update_list(list_id, new_name)
    update_list_sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query update_list_sql, new_name, list_id
  end

  def delete_list(id)
    delete_list_sql = "DELETE FROM lists WHERE id = $1"
    query delete_list_sql, id
  end

  def create_todo(list_id, name)
    add_todo_sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2)"
    query add_todo_sql, list_id, name
  end

  def find_todos(list_id)
    todos_sql = "SELECT * FROM todos WHERE list_id = $1"

    query(todos_sql, list_id).map do |t|
      {id: t["id"], name: t["name"], completed: t["completed"] == 't'}
    end
  end

  def update_todo(list_id, todo_id, new_status)
    update_sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query update_sql, new_status, todo_id, list_id
  end

  def delete_todo(list_id, todo_id)
    delete_todo_sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query delete_todo_sql, todo_id, list_id
  end

  def mark_all_todos_complete(list_id)
    update_sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query update_sql, list_id
  end
end