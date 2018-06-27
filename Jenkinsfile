pipeline {
    agent {
      label "jenkins-maven"
    }
    environment {
      ORG               = 'ryandawsonuk'
      APP_NAME          = 'example-runtime-bundle'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          container('maven') {
            sh "mvn versions:set -DnewVersion=$PREVIEW_VERSION"
            sh "mvn install"
            sh 'export VERSION=$PREVIEW_VERSION && skaffold run -f skaffold.yaml'

            sh "jx step validate --min-jx-version 1.2.36"
            sh "jx step post build --image \$JENKINS_X_DOCKER_REGISTRY_SERVICE_HOST:\$JENKINS_X_DOCKER_REGISTRY_SERVICE_PORT/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }

          dir ('./charts/preview') {
           container('maven') {
             sh "make preview"
             sh "jx preview --app $APP_NAME --dir ../.."
           }
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'develop'
        }
        steps {
          container('maven') {
            // ensure we're not on a detached head
            sh "git checkout develop"
            sh "git config --global credential.helper store"
            sh "jx step validate --min-jx-version 1.1.73"
            sh "jx step git credentials"
            // so we can retrieve the version in later steps
            sh "echo \$(jx-release-version) > VERSION"
            sh "mvn versions:set -DnewVersion=\$(cat VERSION)"
          }
          dir ('./charts/example-runtime-bundle') {
            container('maven') {
              sh "make tag"
            }
          }
          container('maven') {
            sh 'mvn clean deploy -DskipTests'

            sh 'export VERSION=`cat VERSION` && skaffold run -f skaffold.yaml'

            sh "jx step validate --min-jx-version 1.2.36"
            sh "jx step post build --image \$JENKINS_X_DOCKER_REGISTRY_SERVICE_HOST:\$JENKINS_X_DOCKER_REGISTRY_SERVICE_PORT/$ORG/$APP_NAME:\$(cat VERSION)"

            withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]){
              sh "echo about to login to docker"
              sh "docker --config /tmp/ login docker.io -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
              sh "echo about to build docker image"
              sh "docker build . -t docker.io/activiti/rb-my-app:jx"
              sh "echo about to push docker image"
              sh "docker --config /tmp/ login docker.io -u ${env.dockerHubUser} -p ${env.dockerHubPassword} && docker build . -t docker.io/activiti/rb-my-app:jx && docker push docker.io/activiti/rb-my-app:jx"
            }
          }
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'develop'
        }
        steps {
          dir ('./charts/example-runtime-bundle') {
            container('maven') {
              sh 'jx step changelog --version v\$(cat ../../VERSION)'

              // release the helm chart
              sh 'make release'

              // promote through all 'Auto' promotion Environments
              sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'
            }
          }
        }
      }
    }
    post {
        always {
            cleanWs()
        }
        failure {
            input """Pipeline failed. 
We will keep the build pod around to help you diagnose any failures. 

Select Proceed or Abort to terminate the build pod"""
        }
    }
  }
