require 'test/unit'
require 'coderay'
$VERBOSE = true

class LinesOfCodeTest < Test::Unit::TestCase
  
  def test_creation
    assert CodeRay::Encoders::LinesOfCode < CodeRay::Encoders::Encoder
    filter = nil
    assert_nothing_raised do
      filter = CodeRay.encoder :loc
    end
    assert_kind_of CodeRay::Encoders::LinesOfCode, filter
    assert_nothing_raised do
      filter = CodeRay.encoder :lines_of_code
    end
    assert_kind_of CodeRay::Encoders::LinesOfCode, filter
  end
  
  def test_lines_of_code
    tokens = CodeRay.scan <<-RUBY, :ruby
#!/usr/bin/env ruby

# a minimal Ruby program
puts "Hello world!"
    RUBY
    assert_equal 1, CodeRay::Encoders::LinesOfCode.new.encode_tokens(tokens)
    assert_equal 1, tokens.lines_of_code
    assert_equal 1, tokens.loc
  end
  
  class ScannerMockup
    KINDS_NOT_LOC = [:space]
  end
  
  def test_filtering_block_tokens
    tokens = CodeRay::Tokens.new
    tokens.concat ["Hello\n", :world]
    tokens.concat ["\n", :space]
    tokens.concat ["Hello\n", :comment]
    
    stderr, fake_stderr = $stderr, Object.new
    begin
      $err = ''
      def fake_stderr.write x
        $err << x
      end
      $stderr = fake_stderr
      assert_equal 1, tokens.lines_of_code
      assert_equal "Tokens have no associated scanner, counting all nonempty lines.\n", $err
    ensure
      $stderr = stderr
    end
    
    tokens.scanner = ScannerMockup.new
    assert_equal 2, tokens.lines_of_code
  end
  
end