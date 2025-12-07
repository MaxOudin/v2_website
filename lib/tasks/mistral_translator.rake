# frozen_string_literal: true

namespace :mistral_translator do
  desc "Traduit tous les projets manquants"
  task translate_projects: :environment do
    puts "🚀 Démarrage de la traduction des projets..."

    Project.find_each do |project|
      puts "📝 Traduction du projet ##{project.id} : #{project.title_fr || project.title_en}"

      begin
        results = project.translate_with_mistral!(
          from: :fr,
          to: [:en],
          context: "projet de développement web"
        )

        mobility_count = results[:mobility].size
        rich_text_count = results[:rich_text].size

        if mobility_count > 0 || rich_text_count > 0
          puts "  ✅ #{mobility_count} champ(s) Mobility traduit(s)"
          puts "  ✅ #{rich_text_count} champ(s) RichText traduit(s)"
        else
          puts "  ⏭️  Toutes les traductions existent déjà"
        end
      rescue StandardError => e
        puts "  ❌ Erreur : #{e.message}"
      end

      puts ""
    end

    puts "✅ Traduction terminée !"
  end

  desc "Traduit un projet spécifique par ID"
  task :translate_project, [:project_id] => :environment do |_t, args|
    project_id = args[:project_id]
    raise "ID du projet requis. Usage: rake mistral_translator:translate_project[123]" if project_id.nil?

    project = Project.find(project_id)
    puts "🚀 Traduction du projet ##{project.id} : #{project.title_fr || project.title_en}"

    results = project.translate_with_mistral!(
      from: :fr,
      to: [:en],
      context: "projet de développement web"
    )

    puts "✅ Traduction terminée !"
    puts "  - #{results[:mobility].size} champ(s) Mobility traduit(s)"
    puts "  - #{results[:rich_text].size} champ(s) RichText traduit(s)"
  end

  desc "Teste la connexion à l'API Mistral"
  task test_connection: :environment do
    puts "🔍 Test de connexion à l'API Mistral..."

    begin
      service = MistralTranslator::TranslationService.new
      result = service.translate_text(
        "Bonjour le monde",
        from: "fr",
        to: "en"
      )

      puts "✅ Connexion réussie !"
      puts "   Test: 'Bonjour le monde' → '#{result}'"
    rescue StandardError => e
      puts "❌ Erreur de connexion : #{e.message}"
      puts "   Vérifiez que MISTRAL_API_KEY est définie dans vos variables d'environnement"
    end
  end
end

