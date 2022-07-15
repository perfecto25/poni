require "envy"

Envy.from_file "../config2.yml"

puts ENV["defaults"]