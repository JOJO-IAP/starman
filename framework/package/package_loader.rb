module STARMAN
  class PackageLoader
    @@packages = {}
    Dir.glob("#{ENV['STARMAN_ROOT']}/packages/*.rb").each do |file|
      name = File.basename(file, '.rb').to_sym
      @@packages[name] = { :file => file }
    end

    def self.transfer_command_line_options_to package
      # Check command line options for package options.
      CommandLine.options.each do |option, value|
        next unless package.options.has_key? option
        if package.options[option][:accept_value].class == Symbol
          accept_values = [package.options[option][:accept_value]]
        else
          accept_values = package.options[option][:accept_value]
        end
        accept_values.each do |value_type, default_value|
          case value_type
          when :boolean
            if value.class == TrueClass or value.class == FalseClass
              package.options[option][:value] = value
            elsif value == ''
              package.options[option][:value] = true
            end
          when :package
            if has_package? value
              package.options[option][:value] = value
            end
          end
        end
      end
    end

    def self.load_package name
      return if packages[name][:instance]
      load packages[name][:file]
      package = eval("#{name.to_s.capitalize}").new
      transfer_command_line_options_to package
      # Reload package, since the options may change dependencies.
      load packages[name][:file]
      package = eval("#{name.to_s.capitalize}").new
      Command::Install.packages_to_install << package # Record the package to install.
      packages[name][:instance] = package
      package.dependencies.each do |depend_name, options|
        load_package depend_name
      end
    end

    def self.run
      CommandLine.packages.each do |name|
        load_package name.to_s.downcase.to_sym
      end
    end

    def self.has_package? name
      @@packages.has_key? name.to_s.downcase.to_sym
    end

    def self.packages
      @@packages
    end
  end
end