# == Schema Information
#
# Table name: project_tech_stacks
#
#  id            :bigint           not null, primary key
#  project_id    :bigint           not null
#  tech_stack_id :bigint           not null
#  position      :integer
#  level         :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

class ProjectTechStackTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
