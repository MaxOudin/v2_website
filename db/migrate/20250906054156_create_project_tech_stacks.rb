class CreateProjectTechStacks < ActiveRecord::Migration[7.1]
  def change
    create_table :project_tech_stacks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :tech_stack, null: false, foreign_key: true
      t.integer :position
      t.integer :level

      t.timestamps
    end
  end
end
