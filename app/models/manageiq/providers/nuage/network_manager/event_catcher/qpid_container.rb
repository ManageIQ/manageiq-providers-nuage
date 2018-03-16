# NOTE: here we patch Qpid::Proton::Container object to tackle a blocking bug that we observed where
# sockets are not being closed properly upon connection close which results in file descriptor leakage,
# see https://issues.apache.org/jira/browse/PROTON-1791
# TODO: remove this entire class once the issues is fixed (hopefully with qpid_proton 0.22.0)

class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::QpidContainer < Qpid::Proton::Container
  # Override to capture connection drivers.
  def connection_driver(io, opts = nil, server = false)
    driver = super(io, opts, server)

    # Capture connection drivers so that we can manually close them later.
    @drivers ||= []
    @drivers << driver

    driver
  end

  # Override to manually close sockets upon container stop.
  def stop(error = nil)
    $nuage_log.debug("#{self.class.log_prefix} Stop container called")
    super(error)
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
end
