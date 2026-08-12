module DateParams
  module_function

  def parse(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
