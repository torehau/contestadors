require 'iconv'

class String
  # Iconv use borrowed from http://svn.robertrevans.com/plugins/Permalize/
  # Thanks!
  def to_permalink(max_size = 127)
    permalink = (Iconv.new('US-ASCII//TRANSLIT', 'utf-8').iconv self).gsub(/[^\w\s\-\â€”]/,'').gsub(/[^\w]|[\_]/,' ').split.join('-').downcase
    permalink.slice(0, permalink.size < max_size ? permalink.size : max_size)
  end

# File lib/facets/style.rb, line 84
  def self.snakecase(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end  
end

class Object

  class Array
    def chunk(pieces=2)
      len = self.length;
      mid = (len/pieces)
      chunks = []
      start = 0
      1.upto(pieces) do |i|
        last = start+mid
        last = last-1 unless len%pieces >= i
        chunks << self[start..last] || []
        start = last+1
      end
      chunks
    end
  end
end