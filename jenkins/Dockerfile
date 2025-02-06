FROM jenkins/jenkins:lts



ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
COPY --chown=jenkins:jenkins ./jenkins-plugins.txt /usr/share/jenkins/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/plugins.txt
COPY --chown=jenkins:jenkins init.groovy.d/ /var/jenkins_home/init.groovy.d/