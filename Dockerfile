FROM java:openjdk-8-jdk

ENV JENKINS_SWARM_VERSION 2.2
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

# Install Git and dependencies
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y file git curl zip libncurses5:i386 libstdc++6:i386 zlib1g:i386 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists /var/cache/apt

# Set up environment variables
ENV ANDROID_HOME="/home/user/android-sdk-linux" \
    SDK_URL="https://dl.google.com/android/repository/tools_r25.2.5-linux.zip" \
    GRADLE_URL="https://services.gradle.org/distributions/gradle-4.1-all.zip"

# Create a non-root user
RUN useradd -m user
USER user
WORKDIR /home/user

# Download Android SDK
RUN mkdir "$ANDROID_HOME" .android \
 && cd "$ANDROID_HOME" \
 && wget $SDK_URL -O sdk.zip \
 && unzip sdk.zip \
 && rm sdk.zip \
 && mkdir licenses \
 && echo -n 8933bad161af4178b1185d1a37fbf41ea5269c55 \
        > licenses/android-sdk-license \
 && echo -n 84831b9409646a918e30573bab4c9c91346d8abd \
        > licenses/android-sdk-preview-license \
 && echo -n d975f751698a77b662f1254ddbeed3901e976f5a \
        > licenses/intel-android-extra-license       

# Install Gradle
RUN wget $GRADLE_URL -O gradle.zip \
 && unzip gradle.zip \
 && mv gradle-4.1 gradle \
 && rm gradle.zip \
 && mkdir .gradle

ENV PATH="/home/user/gradle/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}:${ANDROID_HOME}/platform-tools:${PATH}"

RUN sdkmanager --update

RUN sdkmanager "platform-tools" "platforms;android-23" "platforms;android-26" "platforms;android-27" "build-tools;23.0.0" "build-tools;26.0.0" "build-tools;27.0.0" "build-tools;26.0.1" "build-tools;26.0.2" "extras;android;m2repository"

USER "${JENKINS_USER}"

ENTRYPOINT ["/usr/local/bin/jenkins-slave.sh"]
