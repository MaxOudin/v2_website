# == Schema Information
#
# Table name: translated_rich_texts
#
#  id          :bigint           not null, primary key
#  field_name  :string           not null
#  locale      :string           not null
#  record_type :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :bigint           not null
#
# Indexes
#
#  index_translated_rich_texts_on_record   (record_type,record_id)
#  index_translated_rich_texts_uniqueness  (record_type,record_id,field_name,locale) UNIQUE
#
class TranslatedRichText < ApplicationRecord
  belongs_to :record, polymorphic: true
  has_rich_text :body

  validates :locale, presence: true
  validates :field_name, presence: true
  validates :locale, uniqueness: { scope: [:record_id, :record_type, :field_name], case_sensitive: true }
end
