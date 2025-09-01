class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.text :description
      t.date :start_date
      t.date :end_date
      t.string :client_name
      t.string :project_url
      t.string :github_url
      t.string :demo_url
      t.string :color
      t.integer :position, null: false
      t.integer :project_type, null: false

      t.timestamps
    end
  end
end
