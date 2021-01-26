#!groovy

import jenkins.model.Jenkins

// Jenkins instance
final Jenkins instance = Jenkins.instance

// Disable CLI over remoting
def descriptor = instance.getDescriptor("jenkins.CLI")
if (descriptor != null) {
  descriptor.get().setEnabled(false)
  // Save security settings
  instance.save()
}
