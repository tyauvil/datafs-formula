module Serverspec
  module Type
    class LvmLogicalVolume < Base

      def initialize(volume)
        @volume = volume
      end

      def exist?
        lvm_display.include?(@volume)
      end

      def has_segments?(num_segments)
        check_lvm?(@name,'Segments', num_segments)
      end

      def has_size_in_GB?(size)
        check_lvm?(@name,'LV Size', size)
      end

      def available?
        check_lvm?(@volume,'LV Status','available')
      end

      private

      def run_command(command)
        Specinfra.backend.run_command(command).stdout
      end

      def lvm_display
        run_command("lvm lvdisplay")
      end

      def check_lvm?(lv_name,part,value)
        spaces=part.count(' ')
        system_value=run_command("echo '#{lvm_display}' |  awk '/#{lv_name}/{found=1}; /#{part}/ && found{print $#{spaces+2}; exit}'")
        value.strip == system_value.strip
      end
    end

    def lvm_volume(lvm_name)
      LvmLogicalVolume.new(lvm_name)
    end

  end
end

include Serverspec::Type
