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

      # Log a clear success banner after the full ABCClient initialization
      # completes. This is the definitive "add-on is up and working" signal —
      # TCP connected, registers read, components detected, ready to poll.
      def initialize(uri)
        super
        detected = COMPONENT_DETECTION_MAP.keys
                                          .select { |name| send(:"#{name}?") }
                                          .map(&:to_s)
        Aurora.logger&.info(
          "Aurora ABC client ready: " \
          "model=#{@model} serial=#{@serial_number} firmware=#{@abc_version} " \
          "components=[#{detected.join(', ')}]"
        )
      end
    end

    prepend ComponentDetectionPrefetch
  end
end
