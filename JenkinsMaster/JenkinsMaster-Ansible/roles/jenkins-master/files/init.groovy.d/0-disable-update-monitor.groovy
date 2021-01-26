#!groovy
import jenkins.model.*

Jenkins.instance.getAdministrativeMonitor('hudson.model.UpdateCenter$CoreUpdateMonitor').disable(true)
