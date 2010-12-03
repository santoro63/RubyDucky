module QandD

  # A "quick and dirty" option parsing command. Accepts as parameters
  # a string representation of the single character option flags, and
  # an array of arguments from which to extract the flags.
  # Returns:
  #   option_map: a map where the defined options are set to true/false
  #               or the value of the option parameter
  #   args: the input arguments array, after the flag-related values have
  #         been removed
  def self.parse_options(option_string, args)
    keys = option_string.split(//)
    stripped_args = [ ]
    option_map = { }
    keys.each { |k| option_map[k] = false }
    args.each do |arg|
       if arg.start_with?('-')
         key = arg[1,1] #so we get the char, not the code
         option_map[key] = true  
       else
         stripped_args << arg
       end
    end
    return option_map, stripped_args
  end



end
