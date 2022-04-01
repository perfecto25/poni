require "./inotify.c.cr"

module Poni::Watcher
  extend self

  def watch(scope : String, &block)
    inotify = INotify.new
    inotify.register(scope) { yield }
  end
end