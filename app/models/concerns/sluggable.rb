module Sluggable
  extend ActiveSupport::Concern

  CYRILLIC_TO_LATIN = {
    "а" => "a", "б" => "b", "в" => "v", "г" => "g", "д" => "d", "е" => "e",
    "ё" => "e", "ж" => "zh", "з" => "z", "и" => "i", "й" => "y", "к" => "k",
    "л" => "l", "м" => "m", "н" => "n", "о" => "o", "п" => "p", "р" => "r",
    "с" => "s", "т" => "t", "у" => "u", "ф" => "f", "х" => "kh", "ц" => "ts",
    "ч" => "ch", "ш" => "sh", "щ" => "shch", "ъ" => "", "ы" => "y", "ь" => "",
    "э" => "e", "ю" => "yu", "я" => "ya"
  }.freeze

  included do
    validates :slug, presence: true, uniqueness: true,
                     format: { with: /\A[a-z0-9-]+\z/, message: "только строчные буквы, цифры и дефисы" }

    before_validation :set_slug
  end

  private

  def set_slug
    if slug.blank?
      self.slug = unique_slug_for(transliterate(title).parameterize)
    elsif transliterate(slug).parameterize != slug
      self.slug = transliterate(slug).parameterize
    end
  end

  def unique_slug_for(base)
    return base unless self.class.exists?(slug: base)

    suffix = 1
    suffix += 1 while self.class.exists?(slug: "#{base}-#{suffix}")
    "#{base}-#{suffix}"
  end

  def transliterate(value)
    value.to_s.chars.map { |char| CYRILLIC_TO_LATIN.fetch(char.downcase, char.downcase) }.join
  end
end
