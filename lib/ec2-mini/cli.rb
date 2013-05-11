require 'aws-sdk'
require 'yaml'

module EC2Mini
  class CLI
    def self.start(options = {})

      unless File.exist?(ENV['HOME'] + '/.ec2-mini')
        puts ".ec2-mini is not found."
        exit 0
      end

      options = YAML.load_file(ENV['HOME'] + '/.ec2-mini')

      exit 0 unless ARGV[0] =~ /^[\w\-]+$/
      exit 0 unless ARGV[1] =~ /^([+-]?[0-9]+)|backup|count$/

      role = ARGV[0]
      operation = ARGV[1]

      access_key_id = options['access_key_id']
      secret_access_key =  options['secret_access_key']
      region = options['region']
      ec2 = AWS::EC2.new(access_key_id: access_key_id, secret_access_key: secret_access_key, region: region)

      #operation
      case operation
      when /^\+/

        command = operation.scan(/([0-9]+$)/)[0][0].to_i

        # search instance
        running_instance = ''
        ec2.instances.tagged('Mini', role).to_a.each do |instance|
          next if instance.status != :running
          running_instance = instance
          break
        end

        # search ami
        ami = ec2.images.with_owner("self").filter("name", role).first

        # for create instance
        image_id = ami.id
        security_groups = running_instance.groups
        zone = running_instance.availability_zone
        key_name = running_instance.key_name
        instance_type = running_instance.instance_type

        command.times do
          running_instance = ec2.instances.create(
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

      when /^\-/

        command = operation.scan(/([0-9]+$)/)[0][0].to_i

        # search instance
        # TODO Warning launch_time sort
        instances = ec2.instances.tagged('Mini', role)
        instances = instances.to_a.reverse

        instances.each do |instance|
          next if instance.status != :running || command <= 0
          instance.terminate
          command -= 1
        end

        puts "successfully removed #{role} #{operation}"

      when 'backup'

        # TODO
        # deregister old ami
        amis = ec2.images.with_owner("self").filter("name", role)
        amis.first.deregister unless amis.count.zero?

        # search instance
        running_instance = ''
        ec2.instances.tagged('Mini', role).to_a.each do |instance|
          next if instance.status != :running
          running_instance = instance
          break
        end

        # create ami
        image = running_instance.create_image(role, {:description => role, :no_reboot => true})
        begin
          sleep 1
          print '.'
          image = ec2.images[image.id]
        end until image.state != :pending
        if image.state == :failure
          puts "create image failed: #{image.state_reason}"
          exit 1
        end
        puts 'successfully created backup'

      when 'count'
        count = 0
        ec2.instances.tagged('Mini', role).each do |instance|
          count += 1 if instance.status == :running
        end
        puts "#{role}: #{count} instances running"
      end
    end
  end
end
