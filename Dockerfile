FROM debian:buster

# install apt dependencies
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y unzip wget git default-jdk chromium=90.0.4430.93-1~deb10u1 xorg tightvncserver autocutsel lxde-core novnc python-websockify 

WORKDIR /app

# download gradle
RUN wget https://services.gradle.org/distributions/gradle-7.0-bin.zip  -P /tmp/ && \
    unzip -d /opt/gradle /tmp/gradle-7.0-bin.zip && \
    rm -rf /tmp/gradle-7.0-bin.zip

# copy whole folder into container
COPY . .

RUN sed -i -e 's/\ \ \ \ val\ chromeDriver\ =\ ChromeDriver(chromeOptions)/\ \ \ \ System.setProperty("webdriver.chrome.whitelistedIps", "");\n\ \ \ \ chromeOptions.addArguments\("--no-sandbox"\);\n\ \ \ \ chromeOptions.addArguments\("--disable-dev-shm-usage"\);\n\ \ \ \ val\ chromeDriver\ =\ ChromeDriver\(chromeOptions\)/g' src/main/kotlin/de/tfr/impf/selenium/DriverFactory.kt

# run gradle build
RUN cat src/main/kotlin/de/tfr/impf/selenium/DriverFactory.kt && \
    /opt/gradle/gradle-7.0/bin/gradle build && \
    cat src/main/kotlin/de/tfr/impf/selenium/DriverFactory.kt

# setup vnc
RUN echo "# XScreenSaver Preferences File\nmode:		off\nselected:  -1" > /root/.xscreensaver && \
  cat /root/.xscreensaver && mkdir /root/.vnc/ && \
  echo "#!/bin/bash\necho -n \${VNC_PASSWORD:-impf-bot} | vncpasswd -f > /root/.vnc/passwd\nchmod 400 ~/.vnc/passwd\n\nexport USER=root\nvncserver :1 -geometry 1920x1080 -depth 24 && websockify -D --web=/usr/share/novnc/ 6901 localhost:5901\ntail -f /app/impflog" > /root/vnc-startup.sh && \
  chmod +x /root/.vnc/xstartup && \
  cat /root/.vnc/xstartup && \
  mv /usr/share/novnc/vnc.html /usr/share/novnc/index.html && \
  echo "#!/bin/bash\nxmodmap -e \"keycode 22 = 5 percent\"\nxmodmap -e \"keycode 23 = 6\"\necho -n \${VNC_PASSWORD:-impf-bot} | vncpasswd -f > /root/.vnc/passwd\nchmod 400 ~/.vnc/passwd\n\nexport USER=root\nvncserver :1 -geometry 1920x1080 -depth 24 && websockify -D --web=/usr/share/novnc/ 6901 localhost:5901\ntail -f /app/impflog" > /root/vnc-startup.sh && \
  chmod +x /root/vnc-startup.sh && \
  cat /root/vnc-startup.sh && \
  chmod go-rwx /root/.vnc 

EXPOSE 5901
EXPOSE 6901

CMD ["/root/vnc-startup.sh"]
