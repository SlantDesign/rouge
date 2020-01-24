def lexer_cache_source(filename, lexer)
  const_name = lexer.name.split('::').last.to_sym

  yield "  Lexer.cache #{filename.inspect}, #{const_name.inspect}, #{lexer.tag.inspect} do"
  yield "    @props[:tag] = #{lexer.tag.inspect}"
  yield "    @props[:title] = #{lexer.title.inspect}"
  yield "    @props[:desc] = #{lexer.desc.inspect}"
  yield "    @props[:option_docs] = #{lexer.option_docs.to_hash.inspect}"
  yield "    @props[:demo_file] = Pathname.new(#{lexer.demo_file.to_s.inspect})"
  yield "    @props[:aliases] = #{lexer.aliases.inspect}"
  yield "    @props[:filenames] = #{lexer.filenames.inspect}"
  yield "    @props[:mimetypes] = #{lexer.mimetypes.inspect}"

  if lexer.detectable?
    yield lexer.method(:detect?).source
    yield "    @props[:detectable?] = true"
  else
    yield "    @props[:detectable?] = false"
  end

  yield "  end"
end

namespace :generate do
  cache_file = './lib/rouge/langspec_cache.rb'

  desc "Update the language cache file"
  task :cache do
    sh "echo '# noop' > #{cache_file}"
    require 'rouge'
    require 'method_source'

    File.open(cache_file, 'w') do |out|
      out.puts "# -*- coding: utf-8 -*- #"
      out.puts "# frozen_string_literal: true"
      out.puts "# automatically generated by #{__FILE__}"
      out.puts
      out.puts "module Rouge"

      Dir.glob('./lib/rouge/lexers/*.rb').each do |source_file|
        load source_file
        lexer_cache_source(source_file, Rouge::Lexer.last_registered) do |line|
          out.puts line
        end
        out.puts
      end
      out.puts "end"
    end
  end
end
