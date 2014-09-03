class String

  # ensures start with
  def random(l=32,m=nil)
    l = (rand(m-l)+l) unless m.blank?
    o, p = [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten, [('a'..'z'),('A'..'Z'),(0..9)].map{|i| i.to_a}.flatten.push('_','-','=')
    o[rand(o.length)] << (2..l).map{ p[rand(p.length)] }.join
  end

  def strip_unicode(r='')
    self.encode(Encoding.find('ASCII'), {:invalid => :replace, :undef => :replace, :replace => r, :universal_newline => true})
  end

end
