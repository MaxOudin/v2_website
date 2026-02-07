class ProjectPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def new?
    create?
  end

  def update?
    user.present?
  end

  def edit?
    update?
  end

  def destroy?
    user.present?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end