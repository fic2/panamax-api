class ServiceManager

  def self.submit(service)
    new(service).submit
  end

  def self.start(service)
    new(service).start
  end

  def initialize(service)
    @service = service
  end

  def submit
    fleet_client.submit(service_def_from_service(@service))
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

  private

  def fleet_client
    PanamaxAgent.fleet_client
  end

  def service_def_from_service(service)
    PanamaxAgent::Fleet::ServiceDefinition.new(service.unit_name) do |sd|
      sd.description = service.description

      # Collect service dependencies
      dep_services = service.links.map { |link| link.linked_to_service.unit_name }.join(' ')
      sd.after = dep_services
      sd.requires = dep_services

      # The '-' prefix in the docker rm command causes the return value to be
      # ignored. We want to try and remove the container if it has exited, but
      # don't really care if it fails.
      docker_rm = "-/usr/bin/docker rm #{service.name}"

      sd.exec_start_pre = "-/usr/bin/docker pull #{service.from}"
      sd.exec_start = service.docker_run_string
      sd.exec_start_post = docker_rm
      sd.exec_stop = "/usr/bin/docker kill #{service.name}"
      sd.exec_stop_post = docker_rm
      sd.restart_sec = '10'
    end
  end
end