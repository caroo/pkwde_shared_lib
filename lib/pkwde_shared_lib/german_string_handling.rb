# encoding: UTF-8

module PkwdeSharedLib
  class ::String
    def make_url_friendly
      downcase.tap do |s|
        s.gsub!("\303\266", "oe")
        s.gsub!("\303\274", "ue")
        s.gsub!("\303\237", "ss")
        s.gsub!("\303\244", "ae")
        s.gsub!("\303\251", "e")
        s.gsub!(/[^a-z0-9]+/i, '-')
        s.gsub!('^0-9a-zA-Z ','')
        s.gsub!(' ', '-')
      end
    end

    alias make_css_friendly make_url_friendly
  end
end
