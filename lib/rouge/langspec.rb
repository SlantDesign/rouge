module Rouge
  class LangSpec
    def to_s; inspect; end

    def self.delegate(m)
      define_method(m) { find_prop(m) }
    end

    def self.load_and_delegate(m)
      define_method(m) { |*a, &b| lexer_class.send(m, *a, &b) }
    end

    delegate :tag
    delegate :title
    delegate :desc
    delegate :option_docs
    delegate :demo_file
    delegate :aliases
    delegate :filenames
    delegate :mimetypes
    delegate :detectable?

    load_and_delegate :lex
    load_and_delegate :continue_lex
    load_and_delegate :new
    load_and_delegate :demo

    def load!
      # noop
    end

    # overridden with a `def self.detect?` in
    # the cache file, but some classes don't
    # define it. this is the default implementation.
    def detect?(analyzer)
      false
    end

    # for compat reasons, a LangSpec is considered == to the
    # lexer class itself.
    def ==(other)
      return true if other.respond_to?(:tag) && other.tag == self.tag
      super
    end

    ### abstract methods ###

    def find_prop(prop)
      raise 'abstract'
    end

    def lexer_class
      raise 'abstract'
    end

    def name
      raise 'abstract'
    end
  end

  class BakedLangSpec < LangSpec
    def inspect
      "#<BakedLangSpec #{@lexer_class}>"
    end

    attr_reader :lexer_class
    def initialize(lexer_class)
      @lexer_class = lexer_class
    end

    delegate :name

    def detect?(text)
      @lexer_class.detect?(text)
    end

    def find_prop(prop)
      @lexer_class.send(prop)
    end
  end

  class CachedLangSpec < LangSpec
    def inspect
      "#<CachedLangSpec:#{@const_name} #{@source_file}>"
    end

    def initialize(source_file, const_name, &b)
      @const_name = const_name
      @source_file = source_file
      @props = {}
      instance_eval(&b)
    end

    def find_prop(prop)
      @props[prop]
    end

    def lexer_class
      load! unless @lexer_class
      @lexer_class
    end

    def name
      "Rouge::Lexers::#{@const_name}"
    end

    def load!
      LOAD_LOCK.synchronize do
        load File.join(ROOT, @source_file)
        @lexer_class = Lexer.last_registered
      end
    end
  end
end
