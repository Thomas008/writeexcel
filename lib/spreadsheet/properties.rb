   ###############################################################################
   #
   # create_summary_property_set().
   #
   # Create the SummaryInformation property set. This is mainly used for the
   # Title, Subject, Author, Keywords, Comments, Last author keywords and the
   # creation date.
   #
   def create_summary_property_set(properties)
       byte_order          = [0xFFFE].pack 'v'
       version             = [0x0000].pack 'v'
       system_id           = [0x00020105].pack 'V'
       class_id            = ['00000000000000000000000000000000'].pack 'H*'
       num_property_sets   = [0x0001].pack 'V'
       format_id           = ['E0859FF2F94F6810AB9108002B27B3D9'].pack 'H*'
       offset              = [0x0030].pack 'V'
       num_property        = [properties.size].pack 'V'
       property_offsets    = ''
   
       # Create the property set data block and calculate the offsets into it.
       property_data, offsets = _pack_property_data(properties)
   
       # Create the property type and offsets based on the previous calculation.
       (0 .. properties.size -1).each do |i|
           property_offsets = property_offsets +
                [properties[i][0], offsets[i]]pack('VV')
       end
   
       # Size of size (4 bytes) +  num_property (4 bytes) + the data structures.
       size = 8 + property_offsets.length + property_data.length
       size = [size].pack('V')
   
       return  byte_order         +
               version            +
               system_id          +
               class_id           +
               num_property_sets  +
               format_id          +
               offset             +
               size               +
               num_property       +
               property_offsets   +
               property_data
   end

   ###############################################################################
   #
   # Create the DocSummaryInformation property set. This is mainly used for the
   # Manager, Company and Category keywords.
   #
   # The DocSummary also contains a stream for user defined properties. However
   # this is a little arcane and probably not worth the implementation effort.
   #
   def create_doc_summary_property_set(properties)
       byte_order          = [0xFFFE].pack 'v'
       version             = [0x0000].pack 'v'
       system_id           = [0x00020105].pack 'V'
       class_id            = ['00000000000000000000000000000000'].pack 'H*'
       num_property_sets   = [0x0002].pack 'V'
   
       format_id_0         = ['02D5CDD59C2E1B10939708002B2CF9AE'].pack 'H*'
       format_id_1         = ['05D5CDD59C2E1B10939708002B2CF9AE'].pack 'H*'
       offset_0            = [0x0044].pack 'V'
       num_property_0      = [properties.size].pack 'V'
       property_offsets_0  = ''
   
       # Create the property set data block and calculate the offsets into it.
       property_data_0, offsets = _pack_property_data(properties)
   
       # Create the property type and offsets based on the previous calculation.
       (0 .. @properties -1).each do |i|
           property_offsets_0 .= [properties[i][0], offsets[i]].pack('VV')
       end
   
       # Size of size (4 bytes) +  num_property (4 bytes) + the data structures.
       data_len = 8 + property_offsets_0.length + property_data_0.length
       size_0   = [data_len].pack 'V'

       # The second property set offset is at the end of the first property set.
       offset_1 = [0x0044 + data_len].pack 'V'
   
       # We will use a static property set stream rather than try to generate it.
       property_data_1 =
          [
              98,00,00,00,03,00,00,00,00,00,00,00,20,00,00,00,
              01,00,00,00,36,00,00,00,02,00,00,00,3E,00,00,00,
              01,00,00,00,02,00,00,00,0A,00,00,00,5F,50,49,44,
              5F,47,55,49,44,00,02,00,00,00,E4,04,00,00,41,00,
              00,00,4E,00,00,00,7B,00,31,00,36,00,43,00,34,00,
              42,00,38,00,33,00,42,00,2D,00,39,00,36,00,35,00,
              46,00,2D,00,34,00,42,00,32,00,31,00,2D,00,39,00,
              30,00,33,00,44,00,2D,00,39,00,31,00,30,00,46,00,
              41,00,44,00,46,00,41,00,37,00,30,00,31,00,42,00,
              7D,00,00,00,00,00,00,00,2D,00,39,00,30,00,33,00
          ].join('').pack('H*')

       return  byte_order         +
               version            +
               system_id          +
               class_id           +
               num_property_sets  +
               format_id_0        +
               offset_0           +
               format_id_1        +
               offset_1           +
   
               size_0             +
               num_property_0     +
               property_offsets_0 +
               property_data_0    +
   
               property_data_1
   end

   ###############################################################################
   #
   # _pack_property_data().
   #    my @properties          = @{$_[0]};
   #    my $offset              = $_[1] || 0;
   #
   # Create a packed property set structure. Strings are null terminated and
   # padded to a 4 byte boundary. We also use this function to keep track of the
   # property offsets within the data structure. These offsets are used by the
   # calling functions. Currently we only need to handle 4 property types:
   # VT_I2, VT_LPSTR, VT_FILETIME.
   #
   def _pack_property_data(properties, offset = 0)
       packed_property     = ''
       data                = ''
       offsets             = []
   
       # Get the strings codepage from the first property.
       codepage = properties[0][2]
   
       # The properties start after 8 bytes for size + num_properties + 8 bytes
       # for each propety type/offset pair.
       offset += 8 * (properties.size + 1)
   
       properties.each do |property|
           offsets.push(offset)
   
           property_type = property[1]
   
           if    property_type == 'VT_I2'
               packed_property = _pack_VT_I2(property[2])
           elsif property_type == 'VT_LPSTR'
               packed_property = _pack_VT_LPSTR(property[2], codepage)
           elsif property_type == 'VT_FILETIME'
               packed_property = _pack_VT_FILETIME(property[2])
           else
               raise "Unknown property type: property_type\n"
           end
   
           offset += packed_property.length
           data    = data + packed_property
       end
   
       return [data, offsets]
   end

   ###############################################################################
   #
   # _pack_VT_I2().
   #    my $value   = $_[0];
   #
   # Pack an OLE property type: VT_I2, 16-bit signed integer.
   #
   def _pack_VT_I2(value)
       type    = 0x0002
       data = [type, value].pack('VV')

       return data
   end

   ###############################################################################
   #
   # _pack_VT_LPSTR().
   #
   # Pack an OLE property type: VT_LPSTR, String in the Codepage encoding.
   # The strings are null terminated and padded to a 4 byte boundary.
   #
   def pack_VT_LPSTR (string, codepage)
   
       type        = 0x001E
       string      = string + "\0"
   
       if codepage == 0x04E4
           # Latin1
           byte_string = string
           length      = byte_string.length
       elsif codepage == 0xFDE9
           # UTF-8
#           if ( ] > 5.008 ) {
#               require Encode
#               if (Encode::is_utf8(string)) {
#                   byte_string = Encode::encode_utf8(string)
#               }
#               else {
#                   byte_string = string
#               }
#           }
#           else {
#               byte_string = string
#           }
   
           length = byte_string.length
       else
           raise "Unknown codepage: codepage\n"
       end
   
       # Pack the data.
       data  = [type, length].pack 'VV' + byte_string
   
       # The packed data has to null padded to a 4 byte boundary.
       if extra = length % 4
           data = data + "\0" * (4 - extra)
       end
   
       return data
   end

#   ###############################################################################
#   #
#   # _pack_VT_FILETIME().
#   #
#   # Pack an OLE property type: VT_FILETIME.
#   #
#   def _pack_VT_FILETIME(localtime)
#   
#       type        = 0x0040
#   
#       # Convert from localtime to seconds.
#       seconds = Time::Local::timelocal(localtime)
 #  
#       # Add the number of seconds between the 1601 and 1970 epochs.
#       seconds += 11644473600
#   
#       # The FILETIME seconds are in units of 100 nanoseconds.
#       nanoseconds = seconds * 1E7
#   
#       # Pack the total nanoseconds into 64 bits.
#       time_hi = int(nanoseconds / 2**32)
#       time_lo = POSIX::fmod(nanoseconds, 2**32)
#   
#       data = pack 'VVV', type, time_lo, time_hi
#   
#       return data
#   end
