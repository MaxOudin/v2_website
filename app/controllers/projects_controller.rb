class ProjectsController < ApplicationController
    before_action :set_project, only: %i[show edit update destroy translate_field translate_all]
    before_action :set_project_for_new, only: :new
    before_action :set_tech_stacks, only: %i[new create edit update]
    before_action :authorize_project, except: :index
    after_action :verify_authorized, except: :index

    def index
        @projects = policy_scope(Project).includes(:tech_stacks).all
    end

    def show
        @project = Project.includes(project_tech_stacks: :tech_stack).find(params[:id])
    end

    def new
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

    def translate_field
        @project = Project.find(params[:id])
        field = params[:field]
        from = params[:from] || I18n.default_locale
        to = params[:to] || (I18n.available_locales - [from.to_sym]).first
        force = params[:force] == "true" || params[:force] == true

        begin
            # Recharger le projet pour avoir les dernières données
            @project.reload
            
            if [:title, :description].include?(field.to_sym)
                # Champ Mobility
                # Vérifier si on doit forcer ou si le champ est vide
                existing = @project.public_send("#{field}_#{to}")
                if !force && existing.present? && existing.to_s.strip.present?
                    respond_to do |format|
                        format.json { render json: { success: false, error: "Traduction déjà existante. Utilisez force=true pour forcer." } }
                        format.html { redirect_to edit_project_path(@project), alert: "Traduction déjà existante." }
                    end
                    return
                end
                
                result = @project.translate_mobility_field!(
                    field: field.to_sym,
                    from: from.to_sym,
                    to: to.to_sym,
                    context: "projet de développement web"
                )
            elsif field.to_sym == :context
                # Champ RichText
                # Vérifier si on doit forcer ou si le champ est vide
                existing = @project.public_send("#{field}_#{to}")
                if !force && existing.present? && existing.to_s.strip.present?
                    respond_to do |format|
                        format.json { render json: { success: false, error: "Traduction déjà existante. Utilisez force=true pour forcer." } }
                        format.html { redirect_to edit_project_path(@project), alert: "Traduction déjà existante." }
                    end
                    return
                end
                
                result = @project.translate_rich_text_field!(
                    field: field.to_sym,
                    from: from.to_sym,
                    to: to.to_sym,
                    context: "description détaillée de projet"
                )
            else
                raise ArgumentError, "Champ non traduisible : #{field}"
            end

            respond_to do |format|
                format.json { render json: { success: true, translated_text: result } }
                format.html { redirect_to edit_project_path(@project), notice: "Traduction effectuée avec succès." }
            end
        rescue StandardError => e
            Rails.logger.error("Erreur de traduction : #{e.message}")
            Rails.logger.error(e.backtrace.first(5).join("\n"))
            respond_to do |format|
                format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
                format.html { redirect_to edit_project_path(@project), alert: "Erreur lors de la traduction : #{e.message}" }
            end
        end
    end

    def translate_all
        @project = Project.find(params[:id])
        from = params[:from] || I18n.default_locale
        to = params[:to] || (I18n.available_locales - [from.to_sym])
        force = params[:force] == "true" || params[:force] == true

        begin
            # Recharger le projet pour avoir les dernières données
            @project.reload
            
            results = @project.translate_with_mistral!(
                from: from.to_sym,
                to: Array(to).map(&:to_sym),
                context: "projet de développement web",
                force: force
            )

            total = results[:mobility].size + results[:rich_text].size
            message = if total > 0
                        "#{total} champ(s) traduit(s) avec succès."
                      else
                        "Aucune traduction nécessaire. Tous les champs sont déjà traduits."
                      end
            
            respond_to do |format|
                format.json { render json: { success: true, translated_count: total, results: results, message: message } }
                format.html { redirect_to edit_project_path(@project), notice: message }
            end
        rescue StandardError => e
            Rails.logger.error("Erreur de traduction : #{e.message}")
            Rails.logger.error(e.backtrace.first(5).join("\n"))
            respond_to do |format|
                format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
                format.html { redirect_to edit_project_path(@project), alert: "Erreur lors de la traduction : #{e.message}" }
            end
        end
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

    def set_project_for_new
        @project = Project.new
    end

    def authorize_project
        authorize @project
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