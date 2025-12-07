class CreateTranslatedRichTexts < ActiveRecord::Migration[7.1]
def change
    create_table :translated_rich_texts do |t|
      t.string :locale, null: false
      t.string :field_name, null: false
      t.references :record, polymorphic: true, null: false

      t.timestamps

      t.index [:record_type, :record_id, :field_name, :locale], unique: true,
              name: 'index_translated_rich_texts_uniqueness'
    end
  end
end
