class Name
  attr_reader :first, :last
  def initialize(first, last)
    @first = first
    @last = last
  end
  def to_s
    [ @first, @last ].compact.join(" ")
  end
end
