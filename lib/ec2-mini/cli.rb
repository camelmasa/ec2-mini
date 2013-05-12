require 'aws-sdk'
require 'yaml'

module EC2Mini
  class CLI

    def initialize(options = nil, config_file = '')
      @options = options || load_config_file(config_file)

      ['access_key_id', 'secret_access_key', 'region'].each do |attribute|
        error "Not set #{attribute}." unless @options[attribute]
      end
    end

    def start(role = nil, command = nil)
      role_regex = /^[\w\-]+$/
      command_regex = /^([+-][0-9]+)|backup|count$/

      error "Not set role." if !(role =~ role_regex) && !(ARGV[0] =~ role_regex)
      error "Not set command." if !(command =~ command_regex) && !(ARGV[1] =~ command_regex)

      role = role || ARGV[0]
      command = command || ARGV[1]

      case command
      when /^\+[0-9]+/
        number = command.scan(/([0-9]+$)/)[0][0].to_i
        up(role, number)
      when /^\-[0-9]+/
        number = command.scan(/([0-9]+$)/)[0][0].to_i
        down(role, number)
      when 'backup'
        backup(role)
      when 'count'
        count(role)
      else
        error 'Not command'
      end
    end

    private
    def load_config_file(config_file)
      error "Not found .ec2-mini file." unless File.exist?(config_file)
      YAML.load_file(config_file)
    end

    def ec2_client
      AWS::EC2.new(
        access_key_id: @options['access_key_id'],
        secret_access_key: @options['secret_access_key'],
        region: @options['region']
      )
    end

    def backup(role)

      # TODO
      # deregister old ami
      amis = ec2_client.images.with_owner("self").filter("name", role)
      amis.first.deregister unless amis.count

      # search instance
      running_instance = ''
      ec2_client.instances.tagged('Mini', role).to_a.each do |instance|
        next if instance.status != :running
        running_instance = instance
        break
      end

      # create ami
      image = running_instance.create_image(role, { description: role, no_reboot: true })
      begin
        sleep 1
        print '.'
        image = ec2_client.images[image.id]
      end until image.state != :pending
      if image.state == :failure
        error "create image failed: #{image.state_reason}"
      end
      puts 'successfully created backup'
    end

    def count(role)
      count = 0
      ec2_client.instances.tagged('Mini', role).each do |instance|
        count += 1 if instance.status == :running
      end
      puts "#{role}: #{count} instances running"
    end

    def up(role, number)

      # search instance
      running_instance = ''
      ec2_client.instances.tagged('Mini', role).to_a.each do |instance|
        next if instance.status != :running
        running_instance = instance
        break
      end

      # search ami
      ami = ec2_client.images.with_owner("self").filter("name", role).first

      # for create instance
      image_id = ami.id
      security_groups = running_instance.groups
      zone = running_instance.availability_zone
      key_name = running_instance.key_name
      instance_type = running_instance.instance_type

      number.times do
        running_instance = ec2_client.instances.create(
          instance_type: instance_type,
          key_name: key_name,
          image_id: image_id,
          availability_zone: zone,
          security_groups: security_groups
        )
        running_instance.add_tag('Name', value: role)
        running_instance.add_tag('Mini', value: role)
      end
      puts "successfully created #{role} #{operation}"
    end

    def down(role, number)

      # search instance
      # TODO Warning launch_time sort
      instances = ec2_client.instances.tagged('Mini', role)
      instances = instances.to_a.reverse

      instances.each do |instance|
        next if instance.status != :running || number <= 0
        instance.terminate
        number -= 1
      end

      puts "successfully removed #{role} #{operation}"
    end

    def error(message = '')
      puts message
      exit 1
    end

  end
end
