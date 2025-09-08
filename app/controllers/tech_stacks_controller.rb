class TechStacksController < ApplicationController
    before_action :set_tech_stack, only: %i[show edit update destroy]

    def index
        @tech_stacks = TechStack.all
    end

    def show
    end
    
    def new
        @tech_stack = TechStack.new
    end

    def create
        @tech_stack = TechStack.new(tech_stack_params)
        if @tech_stack.save
            redirect_to @tech_stack, notice: 'Tech stack créé avec succès.'
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
    end

    def update
        if @tech_stack.update(tech_stack_params)
            redirect_to @tech_stack, notice: 'Tech stack mis à jour avec succès.'
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        if @tech_stack.destroy
            redirect_to tech_stacks_path, notice: 'Tech stack supprimé avec succès.'
        else
            redirect_to tech_stacks_path, alert: 'Tech stack non supprimé.'
        end
    end

    private
    
    def tech_stack_params
        params.require(:tech_stack).permit(:name, :description)
    end

    def set_tech_stack
        @tech_stack = TechStack.find(params[:id])
    end
end
