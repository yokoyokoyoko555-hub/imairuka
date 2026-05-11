class AddProjectManagementToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :project_name, :string
    add_column :orders, :project_summary, :text

    create_table :order_project_tasks do |t|
      t.references :company, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "not_started"
      t.string :priority, null: false, default: "normal"
      t.date :start_date
      t.date :due_date
      t.date :completed_on
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    create_table :order_project_issues do |t|
      t.references :company, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "open"
      t.string :priority, null: false, default: "normal"
      t.date :due_date
      t.datetime :resolved_at

      t.timestamps
    end

    create_table :order_assignments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "member"
      t.text :note

      t.timestamps
    end

    add_index :order_project_tasks, [:company_id, :order_id]
    add_index :order_project_tasks, [:order_id, :position]
    add_index :order_project_issues, [:company_id, :order_id]
    add_index :order_assignments, [:order_id, :user_id], unique: true
  end
end
