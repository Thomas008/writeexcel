##########################################################################
# test_23_note.rb
#
# Tests for the internal methods used to write the MSODRAWINGGROUP record.
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
#########################################################################
base = File.basename(Dir.pwd)
if base == "test" || base =~ /spreadsheet/i
  Dir.chdir("..") if base == "test"
  $LOAD_PATH.unshift(Dir.pwd + "/lib/spreadsheet")
  Dir.chdir("test") rescue nil
end

require "test/unit"
require "biffwriter"
require "olewriter"
require "format"
require "formula"
require "worksheet"
require "workbook"
require "excel"
include Spreadsheet


class TC_mso_drawing_group < Test::Unit::TestCase

  def setup
    @test_file  = 'temp_test_file.xls'
    @workbook   = Excel.new(@test_file)
    @worksheet  = @workbook.add_worksheet
  end

  def test_blank_author_name
    data = @worksheet.comment_params(2,0,'Test')
    row      = data[0]
    col      = data[1]
    author   = data[4]
    encoding = data[5]
    visible  = data[6]
    obj_id   = 1
    
    caption = sprintf(" \tstore_note")
    target  = %w(
        1C 00 0C 00 02 00 00 00 00 00 01 00 00 00 00 00
    ).join(' ')
    result = unpack_record(
        @worksheet.store_note(row,col,obj_id,author,encoding,visible))
    assert_equal(target, result, caption)
  end

  def test_defined_author_name
    data = @worksheet.comment_params(2,0,'Test', :author => 'Username')
    row      = data[0]
    col      = data[1]
    author   = data[4]
    encoding = data[5]
    visible  = data[6]
    obj_id   = 1
    
    caption = sprintf(" \tstore_note")
    target  = %w(
        1C 00 14 00 02 00 00 00 00 00 01 00 08 00 00 55
        73 65 72 6E 61 6D 65 00
    ).join(' ')
    result = unpack_record(
        @worksheet.store_note(row,col,obj_id,author,encoding,visible))
    assert_equal(target, result, caption)
  end

  ###############################################################################
  #
  # Unpack the binary data into a format suitable for printing in tests.
  #
  def unpack_record(data)
    data.unpack('C*').map! {|c| sprintf("%02X", c) }.join(' ')
  end

end
