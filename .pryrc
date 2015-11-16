require 'awesome_print'
require 'awesome_print/ext/active_record'
require 'awesome_print/ext/active_support'
Pry.print = proc { |output, value| output.puts value.ai }
Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'
Pry.commands.alias_command 'f', 'finish'
Pry.commands.alias_command 'w', 'whereami'
