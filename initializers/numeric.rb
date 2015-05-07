class Numeric

  def to_hex
    self.to_i.to_s(16).upcase
  rescue
    0.to_s(16)
  end

end
