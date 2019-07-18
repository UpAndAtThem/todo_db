require 'pg'

class SessionPersistence

  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def all_lists
    @session[:lists]
  end

  def find_list(id)
    @session[:lists].find{ |list| list[:id] == id }
  end

  def create_list(list_name)
    id = next_element_id(@session[:lists])
    @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def update_list(list_id, new_name)
    list = find_list list_id
    list[:name] = new_name
  end

  def delete_list(id)
    @session[:lists].reject! { |list| list[:id] == id }
  end

  def find_todo(list, todo_id)
    list[:todos].find { |todo| todo[:id] == todo_id}
  end

  def add_todo(list_id, name)
    list = find_list list_id
    id = next_element_id(list[:todos])

    list[:todos] << { id: id, name: name, completed: false }
  end

  def update_todo(list_id, todo_id, new_status)
    list = find_list list_id
    todo = find_todo list, todo_id
    todo[:completed] = new_status
  end

  def delete_todo(list_id, todo_id)
    @list = find_list list_id
    @list[:todos].reject! { |todo| todo[:id] == @todo_id }
  end

  def mark_all_todos_complete(list_id)
    @list = find_list list_id

    @list[:todos].each do |todo|
      todo[:completed] = true
    end
  end

  private

  def next_element_id(elements)
    max = elements.map { |todo| todo[:id] }.max || 0
    max + 1
  end

end