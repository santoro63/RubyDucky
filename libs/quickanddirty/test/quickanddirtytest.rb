$:.unshift( File.dirname(__FILE__) + "../src")

require 'test/unit'
require 'quickanddirty'

class OptionTest < Test::Unit::TestCase

  def setup
    @args = [ 'a' , 'b' ]
  end

  def test_no_flags
    flags, args = QandD.parse_options("", @args )
    assert( flags.empty? )
    assert_equal( @args, args )       
  end

  def test_single_flag
    flags, args = QandD.parse_options("f", [ '-f' ] + @args )
    assert( flags["f"] )
    assert_equal( @args, args )
  end

  def test_multiple_flags
    flags, args = QandD.parse_options("fb", [ "-f", "-b" ] + @args)
    assert( flags["f"] )
    assert( flags["b"] )
    assert_equal( @args, args )
  end

  def test_partial_flag_selection
    flags, args = QandD.parse_options("fb", [ '-b' ] + @args)
    assert( ! flags['f'] )
    assert( flags['b'] )
    assert_equal( @args, args )
  end

end

