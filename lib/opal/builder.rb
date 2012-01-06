require 'fileutils'

module Opal
  class Builder
    def initialize(sources, options = {})
      @sources = Array(sources)
      @options = options

      @options[:output] = '.' if @options[:output] == '' or !@options[:output]
    end

    def build
      @parser     = Parser.new
      @factories  = {}
      @libs       = {}

      @sources.each { |s| build_path s }

      if @options[:join]
        File.open(@options[:join], 'w+') do |o|
          @factories.each do |file, factory|
            o.write "opal.file('/#{file}', function() {\n#{factory}\n});\n"
          end
          @libs.each do |lib, factory|
            o.write "opal.lib('#{lib}', function() {\n#{factory}\n});\n"
          end
        end
      end
    end

    def build_path(path)
      if File.directory? path
        Dir.entries(path).each do |e|
          next if e == '.' or e == '..'
          build_path File.join(path, e)
        end

      elsif File.extname(path) == '.rb'
        build_file path
      end
    end

    def build_file(source)
      compiled = @parser.parse File.read(source), source


      if @options[:join]
        if /^lib.*\.rb/ =~ source
          @libs[source[4..-4]] = compiled
        else
          @factories[source] = compiled
        end
      elsif @options[:output]
        output = output_path(source)

        FileUtils.mkdir_p File.dirname(output)
        File.open(output, 'w+') { |o| o.write compiled }
      end
    end

    def output_path(base, source)
        fname = source.chomp('.rb') + '.js'
      if @options[:output] == '.'
        base == '.' ? fname : File.join(base, fname)
      else
        if base == '.'
          File.join @options[:output], fname
        else
          parts = base.split '/'
          parts[0] = @options[:output]
          parts << fname
          File.join *parts
        end
      end
    end
  end
end
