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
class Project < ApplicationRecord
    validates :title, presence: true, uniqueness: true
    validates :position, presence: true, uniqueness: true, numericality: { only_integer: true }
    validates :project_type, presence: true

    has_many :project_tech_stacks
    has_many :tech_stacks, through: :project_tech_stacks

    enum :project_type, {
        website: 0,
        platform: 10,
        application: 20,
        api: 30,
        ecommerce: 40,
        other: 50
    }

    has_one_attached :main_picture

    has_rich_text :context
    
end
