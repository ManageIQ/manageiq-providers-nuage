# Utility function to test Ansible::Runner bad status handling
def raises_upon_errored_playbook
  expect(Ansible::Runner).to receive(:run).and_return(response_bad)
  expect { yield }.to raise_error(MiqException::Error)
end
