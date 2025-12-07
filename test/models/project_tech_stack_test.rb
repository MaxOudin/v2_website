# == Schema Information
#
# Table name: project_tech_stacks
#
#  id            :bigint           not null, primary key
#  level         :integer
#  position      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  project_id    :bigint           not null
#  tech_stack_id :bigint           not null
#
# Indexes
#
#  index_project_tech_stacks_on_project_id     (project_id)
#  index_project_tech_stacks_on_tech_stack_id  (tech_stack_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (tech_stack_id => tech_stacks.id)
#
require "test_helper"

class ProjectTechStackTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
