FROM jenkins/jenkins:lts-jdk17

USER root

# rsync + python3 pipelinea varten
RUN apt-get update \
  && apt-get install -y --no-install-recommends rsync python3 ca-certificates \
  && rm -rf /var/lib/apt/lists/*

USER jenkins

# Pluginien asennus buildissä (ei “first run” -klikkailua)
COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
