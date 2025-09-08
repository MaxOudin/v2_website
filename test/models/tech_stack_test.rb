# == Schema Information
#
# Table name: tech_stacks
#
#  id          :bigint           not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class TechStackTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
