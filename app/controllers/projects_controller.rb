class ProjectsController < ApplicationController
    before_action :set_project, only: %i[show edit update destroy]

    def index
        @projects = Project.all
    end

    def show
    end

    def new
        @project = Project.new
    end

    def create
        @project = Project.new(project_params)

        if @project.save
            redirect_to @project, notice: 'Projet créé avec succès.'
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
    end

    def update
        if @project.update(project_params)
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
            :title, 
            :description, 
            :start_date, 
            :end_date, 
            :client_name, 
            :project_url, 
            :github_url, 
            :demo_url, 
            :color, 
            :position, 
            :project_type,
            :context,
            :main_picture
        )
    end

    def set_project
        @project = Project.find(params[:id])
    end
end