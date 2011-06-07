require 'rake'
require file = File.join(File.dirname(__FILE__), *%w[.. .. pkwde.rb])
include Pkwde::Tagging

namespace :version do
  desc "Write a new version information"
  task :write do
    current_branch == 'master' or fail 'current branch has to be master'
    version = write_version
    Rake.application.options.silent or STDOUT.puts "Written version #{version}."
  end

  desc "Tag the current state with the current version"
  task :tag => :'version:write' do
    if last_tag = tags.last
      changes = tag_changes(last_tag, 'HEAD')
      stories = story_lines(last_tag, 'HEAD')
      Tempfile.open('git-tag') do |out|
        out.puts "New Version: #{Pkwde::VERSION}", '', changes, '', stories
        out.flush
        unless tag_message =~ /^New Version: /
          sh "git commit -F #{out.path} #{version_filename}"
        end
        sh "git tag -a #{Pkwde::VERSION}#{has_migrations?(last_tag, 'HEAD') ? '.DB' : '' } -F #{out.path}"
      end
    else
      fail "No tags were found!"
    end
  end

  desc "Show the current version"
  task :current do
    puts current_version
  end

  desc "Show the current branch"
  task :branch do
    puts current_branch
  end

  desc 'Pushes the master and all tags to the origin'
  task :push  do
    current_branch == 'master' or fail 'current branch has to be master'
    sh 'git push origin master'
    sh 'git push --tags'
  end

  desc "Show the current version and annotation/messages"
  task :message do
    tag = ENV['TAG'] || tags.last
    puts "Tag: #{tag.inspect}", "Annotation: #{tag_annotation(tag).inspect}", "Message: #{tag_message(tag).inspect}"
  end

  desc "Show all version tags"
  task :tags do
    puts tags
  end

  desc "Show all changes since last tag"
  task :changes do
    if last_tag = tags.last
      puts tag_changes(last_tag, 'HEAD')
    end
  end

  desc "Display html document for README in browser"
  task :readme do
    readme = File.join(ROOT_DIR, 'README.markdown')
    sh "rdiscount #{readme} > /tmp/README.html; open /tmp/README.html"
  end

  desc "Display changed files since last tag"
  task :changed_files do
    puts changed_files(tags.last, 'HEAD')
  end

  task "shows if there are any migrations since last tag"
  task :has_migrations do
    puts has_migrations?(tags.last, 'HEAD')
  end

  namespace :pivotal do
    desc "Display Pivotalprinter config"
    task :config do
      puts pivotalprinterrc.inspect
    end

    desc "show stories touched since last tag"
    task :stories do
      puts story_ids(tags.last, 'HEAD')
    end

    desc "show story titles touched since last tag"
    task :story_lines do
      puts story_lines(tags.last, 'HEAD')
    end
  end 
end
