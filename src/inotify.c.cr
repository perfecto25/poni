module Poni::Watcher
    # inotify API is the lowest API to listen for change events on files & folders
    # Reference: INOTIFY (7)
    lib C
      struct Fds
        fd : Int32
        events : Int16
        revents : Int16
      end
  
      STDIN_FILENO =    0
      IN_NONBLOCK  = 2048 # https://sites.uclouvain.be/SystInfo/usr/include/sys/inotify.h.html
      IN_MODIFY    =    2 # "
      POLLIN       =    1 # https://code.woboq.org/qt5/include/bits/poll.h.html
  
      fun inotify_init1(Int32) : Int32
      fun inotify_add_watch(Int64, UInt8*, UInt32) : Int32
      fun poll(Fds*, Int32, Int64) : Int32
    end
  
    class INotify
      @buf = Bytes.new(4096) # aligned as follow should improve perf: _attribute__ ((aligned(__alignof__(struct inotify_event))))
      @fd_id = IO::FileDescriptor
      @len : Int32 = 0
  
      def register(target : String, &block)
        fd = C.inotify_init1(C::IN_NONBLOCK)
        raise Exception.new("INOTIFY not available") if fd == -1
        @fd_io = IO::FileDescriptor.new(fd)
  
        watched = C.inotify_add_watch(fd, target, C::IN_MODIFY)
        fds = get_fds(fd)
  
        puts "Start watching '#{target}'"
        loop do
          poll_num = C.poll(fds, fds.size, -1)
          raise Exception.new("Poll error") if poll_num == -1
  
          if poll_num > 0 && (fds[1].revents & C::POLLIN)
            yield if consume_events
          end
        end
      end
  
      private def consume_events
        # Loop while we have events to read
        loop do
          @len = @fd_io.not_nil!.read(@buf)
          return false if @len == 0 # No more events - we exit
          return true
        end
      end
  
      private def get_fds(fd) : Array(C::Fds)
        console_input = C::Fds.new
        console_input.fd = C::STDIN_FILENO
        console_input.events = C::POLLIN
  
        inotify_input = C::Fds.new
        inotify_input.fd = fd
        inotify_input.events = C::POLLIN
  
        [console_input, inotify_input] of C::Fds
      end
    end
  end