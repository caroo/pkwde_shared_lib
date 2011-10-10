require 'open-uri'
require 'rexml/document'
require 'tins/xt/full'
require 'fileutils'

module Pkwde
  module Tagging
    module_function

    def version_filename
      File.join(Pkwde.lib_path, 'pkwde', 'version.rb')
    end

    def write_version(time = Time.now)
      old, $VERBOSE = $VERBOSE, nil
      version = time.strftime '%Y.%m.%d.%H.%M'
      FileUtils.mkdir_p(File.dirname(Pkwde::Tagging.version_filename))
      open(version_filename, 'w') do |output|
        output.puts <<EOT
module Pkwde
  VERSION        = "#{version}"
  VERSION_ARRAY  = [ #{version.split(/\./).map(&:to_i) * ','} ]
end
EOT
      end
      load Pkwde::Tagging.version_filename

      version
    ensure
      $VERBOSE = old
    end

    def current_version
      old, $VERBOSE = $VERBOSE, nil
      load Pkwde::Tagging.version_filename
      Pkwde::VERSION
    ensure
      $VERBOSE = old
    end

    def current_branch
      `git branch`.lines.each { |line| line =~ /^\*\s+(.+)/ and return $1 }
      nil
    end

    def tag_changes(from_tag, to_tag)
      `git log --pretty='%H %s (%an)' #{from_tag}..#{to_tag}`
    end

    def tag_annotation(tag)
      `git tag -l -n1 #{tag}`.sub(/^#{Regexp.quote(tag)}\s*/, '').chomp
    end

    def tag_message(tag = nil)
      `git log -1 --pretty=format:%B #{tag}`.chomp
    end

    def tags
      system 'git fetch --tags'
      `git tag`.split(/\n/)
    end

    def has_migrations?(from_tag = tags.last, to_tag = 'HEAD')
      changed_files(from_tag, to_tag).scan(/migrate\/(\d{14}|\d{3})_.*\.rb/).size > 0
    end

    def changed_files(from_tag, to_tag)
      `git diff --name-only #{from_tag} #{to_tag}`
    end

    def story_lines(from_tag, to_tag)
      return "" unless pivotaltracker_project_id && pivotaltracker_token
      @stories ||= begin
        story_ids(from_tag, to_tag).map do |story_id|
          begin
            url = "http://www.pivotaltracker.com/services/v3/projects/#{pivotaltracker_project_id}/stories/#{story_id}"
            
            story_xml = REXML::Document.new(open(url, 'X-TrackerToken' => pivotaltracker_token, 'Content-Type' => 'application/xml'))
            [
              [
                story_xml.elements["//story/story_type"].text.upcase.ljust(7),
                "[##{story_id}]",
                story_xml.elements["//story/name"].text
              ].join(" "),
              # for more information uncomment the following lines
              # "\thttps://www.pivotaltracker.com/story/show/#{story_id}",
              # story_xml.at_css("story labels").content.full?{ |labels| "\t{#{labels}}" },
              # story_xml.at_css("story description").content.lines.map{ |line| line = "\t#{line}" }.join()
            ].compact.join("\n")
          rescue OpenURI::HTTPError => e
            warn "couldn't find story with id #{story_id}"
          end
        end
      end.compact
    rescue => e
      warn "couldn't connect to server, so there won't be any stories in commit message"
      "[#{story_ids(from_tag, to_tag).map{|s| "##{s}" }.join(" ")}]"
    end

    def story_ids(from_tag, to_tag)
      story_bodys = `git log --pretty='%s %b' #{from_tag}..#{to_tag}`
      story_bodys.scan(/\[([^\]]*)\]\.*/).flatten.map do |brackets|
        brackets.scan(/#(\d+)/)
      end.flatten.uniq
    end

    def pivotaltracker_token
      pivotalprinterrc["default"]["token"]
    end

    def pivotaltracker_project_id
      pivotalprinterrc["default"]["project"]
    end

    def pivotalprinterrc
      @pivotalprinterrc ||= YAML.load_file("#{ENV['HOME']}/.pivotalprinterrc")
    rescue
      warn("could not load ~/.pivotalprintrc so there won't be any stories in commit message")
      { "default" => {"token" => nil, "project" => nil } }
    end
  end
end
