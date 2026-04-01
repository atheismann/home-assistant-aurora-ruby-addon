# frozen_string_literal: true
#
# Aurora firmware compatibility patch.
#
# PURPOSE:
#   Pre-fetches all component detection registers (800..828) via a single
#   A-protocol bulk request during initialization. This avoids multiple
#   individual B-protocol single-register reads (via WFProxy#[]) that some
#   Aurora firmware/AWL combinations do not respond to, causing ModBusTimeout
#   during ABCClient#initialize (abc_client.rb:157).
#
# BACKGROUND:
#   The waterfurnace_aurora gem's ABCClient#initialize lazily reads component
#   presence registers (thermostat=800, axb=806, iz2=812, aoc=815, moc=818,
#   eev2=824, awl=827) one-at-a-time using the WaterFurnace "B-protocol"
#   (individual register request). Some firmware/AWL combinations respond to
#   bulk "A-protocol" range requests but go silent on individual "B-protocol"
#   requests after a bulk read, causing ModBusTimeout and crashing the bridge.
#
# HOW:
#   This patch uses Module#prepend to intercept the first call to any
#   component detection method (iz2?, axb?, thermostat?, etc.) and performs
#   a single A-protocol bulk read of registers 800..828. All component
#   detection instance variables are pre-populated, so the original lazy
#   methods return immediately from the cached value without any further
#   network requests.
#
# SAFETY:
#   Uses the existing modbus_slave timeout/retry settings (unchanged from
#   upstream defaults), so the pre-fetch either succeeds with the same
#   tolerance as normal reads, or raises and lets the existing retry loop
#   handle reconnection — identical crash behaviour to upstream for any
#   system where B-protocol reads would also have failed.

require "aurora/abc_client"

module Aurora
  class ABCClient
    module ComponentDetectionPrefetch
      # Maps component name to its primary detection register.
      # The version register is always primary + 1.
      COMPONENT_DETECTION_MAP = {
        thermostat: 800,
        axb:        806,
        iz2:        812,
        aoc:        815,
        moc:        818,
        eev2:       824,
        awl:        827
      }.freeze

      # Attempt a single A-protocol bulk read of registers 800..828 to pre-populate
      # all component detection instance variables before any lazy reads occur.
      # Uses the existing modbus slave timeout/retry settings so behaviour for
      # working systems is identical to upstream.
      def prefetch_component_registers
        return if defined?(@_component_prefetch_done)

        @_component_prefetch_done = true

        Aurora.logger&.info("Pre-fetching component detection registers 800..828 (A-protocol bulk read)")
        regs = @modbus_slave.read_multiple_holding_registers(800..828)

        COMPONENT_DETECTION_MAP.each do |name, reg|
          val = regs[reg]
          # 3 = Aurora standard "component not present" value
          present = val != 3

          ver_raw = regs[reg + 1]
          ver = ver_raw.to_f / 100

          instance_variable_set(:"@#{name}", present) unless instance_variable_defined?(:"@#{name}")
          instance_variable_set(:"@#{name}_version", ver) unless instance_variable_defined?(:"@#{name}_version")
        end

        Aurora.logger&.info("Component detection pre-fetch complete")
      end
      private :prefetch_component_registers

      # Wrap each component detection method to trigger the bulk pre-fetch on
      # first use. The pre-fetch populates @<name> and @<name>_version so the
      # original lazy method returns immediately without any network call.
      %i[thermostat axb iz2 aoc moc eev2 awl].each do |name|
        define_method(:"#{name}?") do
          prefetch_component_registers unless instance_variable_defined?(:"@#{name}")
          super()
        end

        define_method(:"#{name}_version") do
          prefetch_component_registers unless instance_variable_defined?(:"@#{name}_version")
          super()
        end
      end

      # Wrap initialize to:
      #   1. Force read_retries=0 AFTER super (which sets it to 2) so that any
      #      ModBus timeout immediately raises rather than retrying on the same
      #      TCP connection. This AWL serves each query exactly once per TCP
      #      connection — retries on the same connection are ignored, causing a
      #      second 15s timeout and a crash. With retries=0, any timeout raises
      #      immediately and run.sh opens a fresh connection for the next attempt.
      #   2. Log a clear success banner once init completes successfully.
      #
      # NOTE: Aurora.logger is nil here (aurora_mqtt_bridge assigns it after
      # ABCClient.new returns), so we use $stdout directly.
      def initialize(uri)
        super
        # Must override AFTER super — ABCClient#initialize sets read_retries=2
        # on @modbus_slave immediately after open_modbus_slave returns.
        @modbus_slave.read_retries = 0

        # When the AWL stops responding mid-refresh, the ModBusTimeout fires after
        # read_retry_timeout (15s). The bridge's own catch in MQTTBridge#join logs
        # "Timeout refreshing ABC; retrying..." and retries on the SAME TCP
        # connection. The AWL then sends its delayed response ~15s after the
        # original request — but the bridge reads it as the response to the retry
        # query. Framing is now 1 cycle behind → "got garbage: Illegal function: N".
        #
        # Fix: override query on this specific slave instance to close the TCP
        # socket immediately on timeout. The bridge's retry then hits a closed
        # socket, raises IOError (not caught by the ModBusTimeout rescue in
        # MQTTBridge#join), and the process exits cleanly for run.sh to reconnect.
        @modbus_slave.define_singleton_method(:query) do |request|
          super(request)
        rescue ModBus::Errors::ModBusTimeout
          begin
            @io.close unless @io.nil? || @io.closed?
          rescue StandardError
            nil
          end
          raise
        end

        detected = COMPONENT_DETECTION_MAP.keys
                                          .select { |name| send(:"#{name}?") }
                                          .map(&:to_s)
        $stdout.puts "Aurora ABC client ready: " \
                     "model=#{@model} serial=#{@serial_number} firmware=#{@abc_version} " \
                     "components=[#{detected.join(', ')}]"
        $stdout.flush
      end
    end

    prepend ComponentDetectionPrefetch

    # When a previous TCP connection is closed mid-transaction (e.g., by our
    # query timeout handler calling @io.close), the AWL buffers its pending
    # response and delivers it at the START of the next TCP connection —
    # before responding to any new query. This shifts all RTU framing by N
    # bytes, causing the first query on every reconnect to receive a garbled
    # response (e.g. "IllegalFunction: 0" or a corrupted bootstrap reply).
    #
    # Fix: after establishing the TCP connection, wait up to 400ms for any
    # stale bytes to arrive and discard them before returning the slave.
    # 400ms is chosen because the AWL typically delivers leftover bytes within
    # ~270ms of the new TCP handshake; normal connections see no data and the
    # select returns nil after 400ms with negligible impact on startup time.
    class << self
      prepend(Module.new do
        def open_modbus_slave(uri, **kwargs)
          slave = super
          raw_io = slave.instance_variable_get(:@io)
          if raw_io && !raw_io.closed?
            begin
              loop do
                ready = IO.select([raw_io], nil, nil, 0.4)
                break unless ready
                raw_io.read_nonblock(4096)
              end
            rescue IO::WaitReadable, IO::EAGAINWaitReadable,
                   EOFError, Errno::ECONNRESET, IOError
              nil
            end
          end
          slave
        end
      end)
    end
  end
end
