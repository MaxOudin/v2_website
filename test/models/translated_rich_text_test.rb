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
require "test_helper"

class TranslatedRichTextTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
