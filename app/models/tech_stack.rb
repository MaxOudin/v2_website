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
class TechStack < ApplicationRecord
    has_many :project_tech_stacks, dependent: :destroy
    has_many :projects, through: :project_tech_stacks

    validates :name, presence: true, uniqueness: true
    validates :description, presence: true
end
