class AddSlugToNews < ActiveRecord::Migration[8.1]
  CYRILLIC_TO_LATIN = {
    "а" => "a", "б" => "b", "в" => "v", "г" => "g", "д" => "d", "е" => "e",
    "ё" => "e", "ж" => "zh", "з" => "z", "и" => "i", "й" => "y", "к" => "k",
    "л" => "l", "м" => "m", "н" => "n", "о" => "o", "п" => "p", "р" => "r",
    "с" => "s", "т" => "t", "у" => "u", "ф" => "f", "х" => "kh", "ц" => "ts",
    "ч" => "ch", "ш" => "sh", "щ" => "shch", "ъ" => "", "ы" => "y", "ь" => "",
    "э" => "e", "ю" => "yu", "я" => "ya"
  }.freeze

  def up
    add_column :news, :slug, :string
    add_index :news, :slug, unique: true

    News.find_each do |news|
      slug = news.title.chars.map { |char| CYRILLIC_TO_LATIN.fetch(char.downcase, char.downcase) }.join.parameterize
      slug = "#{slug}-#{news.id}" if slug.blank?
      news.update_columns(slug: slug)
    end

    change_column_null :news, :slug, false
  end

  def down
    remove_index :news, :slug
    remove_column :news, :slug
  end
end
