class ActiveRecord::Base
  class << self

    def has_translations *fields
      class_eval do

        unless respond_to?(:missing_translation)
            # Register it mostly to remove the translations once you delete an object
            has_many :translations, class_name: "RailsDbLocalize::Translation", as: :resource, dependent: :destroy


            scope :__rails_db_translations_sub_query, lambda{ |lang|
              adapter = Rails.configuration.database_configuration[Rails.env]["adapter"]

              number_of_fields_to_translates = RailsDbLocalize.schema[self.to_s].count

              ttable = RailsDbLocalize::Translation.arel_table.name

              # We can unscope, but problems tend to appears
              # with some gems like paranoid.
              table = respond_to?(:klass) ? table.klass : self

              table.select(:id).joins("INNER JOIN \`#{ttable}\`
                ON (\`#{ttable}\`.resource_id = \`#{arel_table.name}\`.id
                AND \`#{ttable}\`.resource_type = '#{to_s}')")
              .group(:resource_type, :resource_id, "#{arel_table.name}.id")
              .having("COUNT(*) = #{number_of_fields_to_translates}")
              .where(:"rails_db_localize_translations.lang" => lang)
            }

            # Return all rows with missing translation for a selected language.
            scope :missing_translation, lambda{ |lang|
              where("\`#{arel_table.name}\`.id NOT IN (#{__rails_db_translations_sub_query(lang).to_sql})")
            }

            # Return all rows with missing translation for a selected language, with specific field.
            scope :missing_field_translation, lambda{ |lang, field|
              where("\`#{arel_table.name}\`.id NOT IN (#{__rails_db_translations_sub_query(lang).where("\`rails_db_localize_translations\`.field = #{field}").to_sql})")
            }

            # Return all rows with translation OK for a selected language.
            scope :having_translation, lambda{ |lang|
              where("\`#{arel_table.name}\`.id IN (#{__rails_db_translations_sub_query(lang).to_sql})")
            }

            def self.preload_translations
              RailsDbLocalize::TranslationCache.instance.prefetch_collections(self)
              self
            end
          end


        fields.each do |field|
          # Add a marker to the schema of the application translations.
          RailsDbLocalize::add_to_schema(self, field)

          # Not sure if I would have to put dependent: :destroy here.
          self.has_many :"#{field}_translations", -> { where(field: field)  }, as: :resource

          # Making the magic happends.
          # I should really learn how to use the Reflection helpers in ActiveRecord, because
          # ruby eval is not the most readable stuff... :o)
          self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{field}_translated_exists?(lang=nil)
              lang ||= I18n.locale
              !!RailsDbLocalize::TranslationCache.instance.get_translation_for(self.class, self.id, "#{field}", lang, nil )
            end

            def #{field}_translated (lang=nil)
              lang ||= I18n.locale
              RailsDbLocalize::TranslationCache.instance.get_translation_for(self.class, self.id, "#{field}", lang, self.#{field} )
            end

            def #{field}_translated= args
              if args.is_a?(Array)
                value, lang = args
              else
                value = args
                lang = I18n.locale
              end

              if self.id
                translated = RailsDbLocalize::Translation.where(
                  resource_type: self.class.to_s, resource_id: self.id,  field: "#{field}", lang: lang
                ).first_or_create

                translated.content = value

                translated.save!
              else
                translations.build field: "#{field}", lang: lang, content: value
              end
            end
          RUBY
        end

      end

    end
  end
end
