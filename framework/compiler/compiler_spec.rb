module STARMAN
  class CompilerSpec
    [:vendor].each do |attr|
      class_eval <<-EOT
        def #{attr} val = nil, &block
          if block_given?
            @#{attr} = block.call
          else
            @#{attr} = val if val
          end
          @#{attr}
        end
      EOT
    end

    attr_reader :languages, :flags

    def initialize
      @languages = {}
      @flags = {}
      @features = {}
    end

    def version val = nil, &block
      if block_given?
        @version = block
      else
        if val
          @version = VersionSpec.new val
        elsif @version.class == Proc
          @version = VersionSpec.new @version.call
        end
      end
      @version
    end

    def language val, **options
      @languages[val] = options if val
    end

    def flag val
      @flags = val.merge(@flags)
    end

    def feature val, &block
      if block_given?
        @features[val] = block
      else
        @features[val] = true
      end
    end

    def feature? val
      @features[val] = @features[val].call if @features[val].class == Proc
      @features[val]
    end
  end
end
