class Numeric
  def in(number, &block)
    return false if number <= 0
    threshold = self / number.to_f
    result = rand <= threshold
    return yield if result && block_given?
    result
  end
end
