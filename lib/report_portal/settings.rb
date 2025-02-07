require 'yaml'
require 'singleton'

module ReportPortal
  class Settings
    include Singleton

    def initialize
      @filename = get_settings_file
      @properties = @filename.nil? ? {} : YAML.load_file(@filename)
      keys = {
        'uuid' => true,
        'endpoint' => true,
        'project' => true,
        'launch' => true,
        'tags' => false,
        'description' => false,
        'attributes' => false,
        'is_debug' => false,
        'disable_ssl_verification' => false,
        # for parallel execution only
        'use_standard_logger' => false,
        'launch_id' => false,
        'file_with_launch_id' => false,
        'logLaunchLink' => false,
        'cucumber_formatter' => false
      }

      keys.each do |key, is_required|
        define_singleton_method(key.to_sym) { setting(key) }
        next unless is_required && public_send(key).nil?

        env_variable_name = env_variable_name(key)
        raise "ReportPortal: Define environment variable '#{env_variable_name.upcase}', '#{env_variable_name}' "\
          "or key #{key} in the configuration YAML file"
      end
    end

    def launch_mode
      is_debug ? 'DEBUG' : 'DEFAULT'
    end

    def formatter_modes
      setting('formatter_modes') || []
    end

    def use_same_thread_for_reporting?
      formatter_modes.include?('use_same_thread_for_reporting')
    end

    def attach_to_launch?
      formatter_modes.include?('attach_to_launch')
    end

    def cucumber_formatter
      :pretty unless setting('cucumber_formatter').to_sym
    end

    def get_launch_id
      if ReportPortal::Settings.instance.launch_id
        ReportPortal::Settings.instance.launch_id
      elsif ReportPortal::Settings.instance.file_with_launch_id
        File.read(ReportPortal::Settings.instance.file_with_launch_id)
      elsif File.exist?(Pathname(Dir.pwd) + 'rp_launch_id.tmp')
        file_path = Pathname(Dir.pwd) + 'rp_launch_id.tmp'
        File.read(file_path)
      else
        cmd_args = ARGV.map { |arg| arg.include?('rp_uuid=') ? 'rp_uuid=[FILTERED]' : arg }.join(' ')
        file_to_write_launch_id = ENV['file_for_launch_id'] || ReportPortal::Settings.instance.file_with_launch_id
        file_to_write_launch_id ||= Pathname(Dir.pwd) + 'rp_launch_id.tmp'
        launch_id = ReportPortal.start_launch(cmd_args)
        File.write(file_to_write_launch_id, launch_id)
      end
    end

    private

    def setting(key)
      env_variable_name = env_variable_name(key)
      return YAML.safe_load(ENV[env_variable_name.upcase]) if ENV.key?(env_variable_name.upcase)

      return YAML.safe_load(ENV[env_variable_name]) if ENV.key?(env_variable_name)

      @properties[key]
    end

    def get_settings_file
      ENV.fetch('rp_config') do
        glob = Dir.glob('{,.config/,config/}report{,-,_}portal{.yml,.yaml}')
        p "Multiple configuration files found for ReportPortal. Using the first one: #{glob.first}" if glob.size > 1
        glob.first
      end
    end

    def env_variable_name(key)
      'rp_' + key
    end
  end
end