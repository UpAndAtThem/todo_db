require 'pg'

class DatabasePersistence

  def initialize(logger)
    @db = if Sinatra::Base.production?
                  PG.connect(ENV['DATABASE_URL'])
                else
                  PG.connect(dbname: "todos")
                end

    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = "SELECT * FROM lists"
    result = @db.exec(sql)

    result.map do |tuple|
      todos = find_todos tuple["id"]

      {id: tuple["id"], name: tuple["name"], todos: todos}
    end
  end

  def find_list(id)
    list_sql = "SELECT * FROM lists WHERE lists.id = $1"

    list_res = query(list_sql, id).values.first
    todos = find_todos id

    {id: list_res[0].to_i, name: list_res[1], todos: todos}
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