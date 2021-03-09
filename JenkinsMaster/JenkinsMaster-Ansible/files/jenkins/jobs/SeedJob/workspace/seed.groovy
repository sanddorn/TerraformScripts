import groovy.transform.Field
import groovy.json.JsonSlurper
import hudson.model.Item
import hudson.security.ACL
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.StandardCredentials

@Field
def gitUrl = 'https://gitlab.bermuda.de/api/v4'
@Field
def privateToken = CredentialsProvider
		.lookupCredentials(StandardCredentials, (Item) null, ACL.SYSTEM)
		.find { it.id == "gitlab-api" }
		.apiToken

def projectNamespaces = []
// Reading projects from GitLab REST API
for (int page = 0;; ++page) {
    def projects = new URL("${gitUrl}/projects/?membership=yes&private_token=${privateToken}&page=${page}")
            .withReader { new JsonSlurper().parse(it) }
    if (projects.isEmpty()) {
        println("no projects found")
        break
    }

    projects.each {
        def projectName = buildProjectName(it)
        def friendlyProjectName = projectName.replace('-', ' ')
        def projectNamespace = ''
        if (it.namespace.name.length() > 0 ) {
            projectNamespace = it.namespace.name
        }

        def sshUrl = it.ssh_url_to_repo
        println("Found Project: " + projectName)
        try {
            def branches = new URL("${gitUrl}/projects/${it.id}/repository/branches?private_token=${privateToken}").withReader {
                new JsonSlurper().parse(it)
            }
            def defaultBranchObject = branches.find {
                it["default"]
            }
            def defaultBranch = defaultBranchObject == null ? "development" : defaultBranchObject["name"]
            def jenkinsfiles = new URL("${gitUrl}/projects/${it.id}/repository/tree?path=Jenkinsfiles&private_token=${privateToken}").withReader {
                new JsonSlurper().parse(it)
            }

            if (!projectNamespaces.contains(projectNamespace)) {
                createNamespace(projectNamespace)
                projectNamespaces.add(projectNamespace)
            }

            jenkinsfiles.findAll { it.name.endsWith(".jf") }.each {
                println(it.name)
                println(it.path)
                def typeName = it.name.replace(".jf", "")
                createPipelineJob(sshUrl, projectNamespace, projectName, friendlyProjectName, typeName, it.path, defaultBranch)
            }
        } catch (Exception e) {
            println("Problem getting Jenkinsfiles for Project " + projectName)
        }
    }
}


String buildProjectName(def project) {
    def name = toCamelCase(project.name)
    return name;
}
String toCamelCase( String text, boolean capitalized = true ) {
    text = text.replaceAll( "(_)([A-Za-z0-9])", { Object[] it -> it[2].toUpperCase() } )
    return capitalized ? text.capitalize() : text
}

def createPipelineJob(def sshUrl, def projectNamespace, def projectName, def friendlyProjectName, def typeName, def jenkinsfilePath, def branchname) {
    println("CreatePipeline " + projectName)
    def projectname = "${projectNamespace}/${typeName}${projectName}"
    pipelineJob(projectname) {
        displayName("${friendlyProjectName} ${typeName}")
        definition {
            cpsScm {
                lightweight()
                scm {
                    git {
                        remote {
                            url(sshUrl)
                            credentials("gitlab-ssh")
                        }
                        branch(branchname)
                        extensions {
                            wipeOutWorkspace()
                        }
                    }
                }
                scriptPath(jenkinsfilePath)
            }
        }
    }
    queue(projectname)
}

def void createNamespace(String projectnamespace) {
    println("CreateNamespace " +  projectnamespace)
    folder(projectnamespace)
}
