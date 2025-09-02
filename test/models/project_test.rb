# == Schema Information
#
# Table name: projects
#
#  id           :bigint           not null, primary key
#  title        :string           not null
#  description  :text
#  start_date   :date
#  end_date     :date
#  client_name  :string
#  project_url  :string
#  github_url   :string
#  demo_url     :string
#  color        :string
#  position     :integer          not null
#  project_type :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
