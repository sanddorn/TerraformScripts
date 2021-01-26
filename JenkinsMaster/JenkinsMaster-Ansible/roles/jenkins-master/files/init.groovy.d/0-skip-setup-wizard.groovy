#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def instance = Jenkins.instance

instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
