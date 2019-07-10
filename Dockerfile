FROM openjdk:latest

MAINTAINER Yuta Yamori yuta.y@root42.jp
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NOWARNINGS=yes
RUN apt-get update
RUN apt-get install -y xvfb sudo curl

# Install Gradle Version: 5.2.1
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/gradle.zip     https://services.gradle.org/distributions/gradle-5.5-bin.zip   && unzip -d /opt /tmp/gradle.zip   && rm /tmp/gradle.zip   && ln -s /opt/gradle-* /opt/gradle   && /opt/gradle/bin/gradle -version
ENV PATH="/opt/gradle/bin:$PATH"

RUN gradle -version

# install chrome
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      && (sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb || sudo apt-get -fy install)  \
      && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
      && sudo sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' \
           "/opt/google/chrome/google-chrome" \
      && google-chrome --version

# install chromedriver
RUN export CHROMEDRIVER_RELEASE=$(curl --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
      && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
      && cd /tmp \
      && unzip chromedriver_linux64.zip \
      && rm -rf chromedriver_linux64.zip \
      && sudo mv chromedriver /usr/local/bin/chromedriver \
      && sudo chmod +x /usr/local/bin/chromedriver \
      && chromedriver --version

# start xvfb automatically to avoid needing to express
ENV DISPLAY :99
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
    && chmod +x /tmp/entrypoint \
    && sudo mv /tmp/entrypoint /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

RUN mkdir /app
WORKDIR /app
COPY ./ ./
CMD gradle test
