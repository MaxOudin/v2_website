class ProjectsController < ApplicationController
    before_action :set_project, only: %i[show edit update destroy]
    before_action :set_tech_stacks, only: %i[new create edit update]

    def index
        @projects = Project.includes(:tech_stacks).all
    end

    def show
        @project = Project.includes(project_tech_stacks: :tech_stack).find(params[:id])
    end

    def new
        @project = Project.new
    end

    def create
        @project = Project.new(project_params)
        if @project.save
            create_or_update_tech_stacks
            redirect_to @project, notice: 'Projet créé avec succès.'
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
    end

    def update
        if @project.update(project_params)
            create_or_update_tech_stacks
            redirect_to @project, notice: 'Projet mis à jour avec succès.'
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @project.destroy
        redirect_to projects_path, notice: 'Projet supprimé avec succès.'
    end

    private
    
    def project_params
        params.require(:project).permit(
            *I18n.available_locales.map { |locale| "title_#{locale}" },
            *I18n.available_locales.map { |locale| "description_#{locale}" },
            *I18n.available_locales.map { |locale| "context_#{locale}" },
            :start_date, 
            :end_date, 
            :client_name, 
            :project_url, 
            :github_url, 
            :demo_url, 
            :color, 
            :position, 
            :project_type,
            :main_picture
        )
    end

    def set_project
        @project = Project.find(params[:id])
    end

    def set_tech_stacks
        @tech_stacks = TechStack.order(:name)
    end

    def create_or_update_tech_stacks
        return unless params[:project][:tech_stack_attributes].present?

        # Supprime les associations existantes
        @project.project_tech_stacks.destroy_all
        
        # Récupère les IDs des tech stacks sélectionnées (sans le blank)
        tech_stack_ids = params[:project][:tech_stack_attributes].reject(&:blank?)
        
        # Récupère les niveaux correspondants
        tech_stack_levels = params[:project][:tech_stack_levels] || []
        
        # Crée les nouvelles associations avec les niveaux
        tech_stack_ids.each_with_index do |tech_stack_id, index|
            @project.project_tech_stacks.create!(
                tech_stack_id: tech_stack_id,
                level: tech_stack_levels[index] || 'intermediate'
            )
        end
    end
end