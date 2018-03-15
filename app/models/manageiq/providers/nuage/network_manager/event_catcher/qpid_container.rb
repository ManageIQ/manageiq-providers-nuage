# NOTE: here we patch Qpid::Proton::Container object to tackle two blocking bugs that we observed:
# a) sockets are not being closed properly upon connection close which resulty in file descriptor leakage
# b) AMQP heartbeat is not being sent which results in periodically closing connection every minute or two
# See https://issues.apache.org/jira/browse/PROTON-1791
# TODO: remove this entire class once the issues are fixed (should be in qpid_proton 0.22.0)

class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::QpidContainer < Qpid::Proton::Container
  # Override to capture connection drivers.
  def connection_driver(io, opts = nil, server = false)
    driver = super(io, opts, server)

    # Capture connection drivers so that we can manually poke them later.
    @drivers ||= []
    @drivers << driver

    driver
  end

  # Override to also start poking thread upon container start.
  def run
    $nuage_log.debug("#{self.class.log_prefix} Run container called")
    poke_drivers_thread_start
    super
  end

  # Override to also stop poking thread upon container stop.
  def stop(error = nil)
    $nuage_log.debug("#{self.class.log_prefix} Stop container called")
    super(error)
    poke_drivers_thread_stop
    close_sockets
  end

  def self.log_prefix
    "MIQ(#{name})"
  end

  private

  # Manually close sockets or else they remain in CLOSE_WAIT statue forever consuming file descriptors.
  def close_sockets
    $nuage_log.debug("#{self.class.log_prefix} Closing sockets")
    @drivers.each { |d| d.to_io.close } if @drivers
    @drivers = nil
  end

  # Invoke 'process' function on all current drivers to prevent ActiveMQ from disconnecting us with
  # 'amqp:resource-limit-exceeded: local-idle-timeout expired' error.
  def poke_drivers
    active_drivers = (@drivers || []).reject(&:finished?)
    $nuage_log.debug("#{self.class.log_prefix} Poking #{active_drivers.size} drivers")
    active_drivers.each(&:process) if @drivers
  end

  # Run poke_drivers function every 5 seconds (in auxilary thread).
  def poke_drivers_thread_start
    unless @poking
      @poking = true
      $nuage_log.debug("#{self.class.log_prefix} Start poking drivers")
      Thread.new do
        begin
          while @poking
            sleep(5)
            poke_drivers
          end
        rescue StandardError => e
          $nuage_log.debug("#{self.class.log_prefix} Error in poking drivers thread: #{e}")
        end
        $nuage_log.debug("#{self.class.log_prefix} Stop poking drivers")
        @poking = false
      end
    end
  end

  # Request auxilary thread to terminate.
  def poke_drivers_thread_stop
    $nuage_log.debug("#{self.class.log_prefix} Stop poking drivers requested")
    @poking = false
  end
end
