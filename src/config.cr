require "yaml"

module Poni
  class Config
    def self.load_from_yml_file(file_path : String) : Config
      File.open(file_path) { |f| Config.from_yaml(f) }
    end
  end
end