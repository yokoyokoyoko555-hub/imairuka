class AddParentToOrderProjectTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :order_project_tasks, :parent, foreign_key: { to_table: :order_project_tasks }, index: true
  end
end
