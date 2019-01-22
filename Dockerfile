FROM java:openjdk-8-jdk

ENV JENKINS_SWARM_VERSION 3.9
ENV JENKINS_SWARM_DOWNLOAD_SITE https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client
ENV JENKINS_HOME /home/jenkins
ENV JENKINS_USER jenkins

RUN useradd -m -d "${JENKINS_HOME}" -u 1000 -U -s /sbin/nologin "${JENKINS_USER}"
RUN curl --create-dirs -sSLo /usr/share/jenkins/swarm-client-${JENKINS_SWARM_VERSION}-jar-with-dependencies.jar \
  ${JENKINS_SWARM_DOWNLOAD_SITE}/${JENKINS_SWARM_VERSION}/swarm-client-${JENKINS_SWARM_VERSION}-jar-with-dependencies.jar \
  && chmod 755 /usr/share/jenkins

COPY jenkins-slave.sh /usr/local/bin/jenkins-slave.sh
RUN chmod +x /usr/local/bin/jenkins-slave.sh

RUN mkdir /docker-entrypoint-init.d
ONBUILD ADD ./*.sh /docker-entrypoint-init.d/

# Set up environment variables
ENV GRADLE_URL="https://services.gradle.org/distributions/gradle-4.1-all.zip"

# Create a non-root user
RUN useradd -m user
USER user
WORKDIR /home/user

# Install Gradle
RUN wget $GRADLE_URL -O gradle.zip \
 && unzip gradle.zip \
 && mv gradle-4.1 gradle \
 && rm gradle.zip \
 && mkdir .gradle

ENV PATH="/home/user/gradle/bin:${PATH}"

USER "${JENKINS_USER}"

ENTRYPOINT ["/usr/local/bin/jenkins-slave.sh"]
