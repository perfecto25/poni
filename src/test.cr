require "totem"

totem = Totem.from_file "/home/mreider/dev/crystal/poni/config2.yaml"

puts totem.get("sync")
#puts totem.                           # => true
##puts totem.get("age").as_i                                 # => 35
#puts totem.get("clothing").as_h["pants"].as_h["size"].as_s # => "large"