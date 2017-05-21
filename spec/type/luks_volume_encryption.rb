module Serverspec
  module Type
    class LuksVolumeEncryption < Base
      def initialize(volume)
        @volume = volume
      end

      def encrypted?
        Specinfra.backend.run_command("cryptsetup luksDump #{@volume}").exit_status == 0
      end
    end

    def encrypted_volume(volume)
      LuksVolumeEncryption.new(volume)
    end
  end
end
