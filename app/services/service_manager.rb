require 'fleet'

class ServiceManager

  def self.load(service)
    new(service).load
  end

  def self.start(service)
    new(service).start
  end

  def initialize(service)
    @service = service
  end

  def load
    fleet_client.load(@service.unit_name, service_def_from_service(@service))
  end

  def start
    fleet_client.start(@service.unit_name)
  end

  def stop
    fleet_client.stop(@service.unit_name)
  end

  def destroy
    fleet_client.destroy(@service.unit_name)
  end

  def get_state
    fleet_client.status(@service.unit_name)
  rescue
    {}
  end

  private

  def fleet_client
    Fleet.new
  end

  def service_def_from_service(service)

    unit_block = {
      'Description' => service.description
    }

    if service.links.any?
      dep_services = service.links.map do |link|
        link.linked_to_service.unit_name
      end.join(' ')

      unit_block['After'] = dep_services
      unit_block['Requires'] = dep_services
    end

    #docker_kill_silent = "-/bin/bash -c 'echo \"Killing the container (optional)\" && /usr/bin/docker kill #{service.name} 1>/dev/null 2>&1 || true'"
    #docker_rm_silent = "-/bin/bash -c 'echo \"Removing the container (optional)\" && /usr/bin/docker rm #{service.name} 1>/dev/null 2>&1 || true'"
    docker_kill = "-/usr/bin/docker kill #{service.name}"
    docker_rm = "-/usr/bin/docker rm #{service.name}"
    service_block =
      [
       ['ExecStartPre', "/usr/bin/docker pull #{service.from}"],
       ['ExecStartPre', docker_kill],
       ['ExecStartPre', docker_rm],
       ['ExecStart', service.docker_run_string],
       ['ExecStop', docker_kill],
       ['ExecStop', docker_rm],
       ['Restart', 'always'],
       ['RestartSec', '30s'],
       ['TimeoutStartSec', '10min']
      ]

    {
      'Unit' => unit_block,
      'Service' => service_block
    }
  end
end
