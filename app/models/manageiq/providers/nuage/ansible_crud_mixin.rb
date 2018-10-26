module ManageIQ::Providers::Nuage::AnsibleCrudMixin
  extend ActiveSupport::Concern

  module ClassMethods
    def ansible_stats(ansible_response, *keys, default: {})
      ansible_response.parsed_stdout.dig(-1, 'event_data', 'artifact_data', *keys) || default
    end

    def ansible_raise_for_status(ansible_response)
      $nuage_log.debug("Ansible response:\n#{ansible_outputs(ansible_response)}")
      # TODO: introduce new error type say MiqException::AnsibleReturnCodeError
      raise MiqException::Error, ansible_outputs(ansible_response) unless ansible_response.return_code.zero?
    end

    def ansible_outputs(ansible_response)
      "Playbook finished with return code #{ansible_response.return_code}\n" + \
        ansible_response.parsed_stdout.map { |line| line['stdout'].to_s.strip }.join("\n")
    end
  end
end
