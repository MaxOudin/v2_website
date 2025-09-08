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
class ProjectTechStack < ApplicationRecord
  belongs_to :project
  belongs_to :tech_stack

  validates :project_id, presence: true, uniqueness: { scope: :tech_stack_id }
  validates :tech_stack_id, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  validates :level, presence: true

  # Niveaux d'expertise
  enum level: {
    beginner: 0,
    intermediate: 10,
    advanced: 20,
    expert: 30
  }

  # Scope pour ordonner par position
  scope :ordered, -> { order(position: :asc) }
  
  # Callback pour assigner automatiquement la position
  before_validation :set_position, on: :create

  private

  def set_position
    return if position.present?
    last_position = project.project_tech_stacks.maximum(:position) || 0
    self.position = last_position + 1
  end
end