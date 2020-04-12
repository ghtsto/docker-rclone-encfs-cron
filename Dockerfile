FROM ubuntu:18.04
LABEL maintainer="ghtsto"

ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_MIRROR="archive.ubuntu.com"

ARG PLATFORM_ARCH="amd64"

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1

ENV LANG=C.UTF-8
ENV PS1="\u@\h:\w\\$ "

RUN \
 echo "**** apt source change for local build ****" && \
 sed -i "s/archive.ubuntu.com/\"$APT_MIRROR\"/g" /etc/apt/sources.list && \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
	ca-certificates \
	fuse \
	tzdata \
	cron \
	encfs && \
 update-ca-certificates && \
 apt-get install -y openssl && \
 sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf && \
 echo "**** install build packages ****" && \
 apt-get install -y \
	curl && \
 echo "**** add s6 overlay ****" && \
 OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
 tar xfz  /tmp/s6-overlay.tar.gz -C / && \
 echo "**** add rclone ****" && \
 RCLONE_VERSION=$(curl -sX GET "https://api.github.com/repos/rclone/rclone/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o /tmp/rclone.deb -L "https://github.com/rclone/rclone/releases/download/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.deb" && \
 dpkg -i  /tmp/rclone.deb && \
 echo "**** create abc user ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 echo "**** cleanup ****" && \
 apt-get purge -y \
	curl && \
 apt-get clean autoclean && \
 apt-get autoremove -y && \
 cd $(mktemp -d) && \
 rm -rf /tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
 echo "**** crontab setup ****" && \
 mkdir -p /etc/cron.minute && \
 # every minute
 (crontab -l 2>/dev/null; echo "* * * * * cd / && run-parts --report /etc/cron.minute > /proc/1/fd/1") | crontab - && \
 # hourly on the hour
 (crontab -l 2>/dev/null; echo "0 * * * * cd / && run-parts --report /etc/cron.hourly > /proc/1/fd/1") | crontab - && \
 # daily at 02:00
 (crontab -l 2>/dev/null; echo "0 2 * * * cd / && run-parts --report /etc/cron.daily > /proc/1/fd/1") | crontab - && \
 # weekly at 05:00 on Monday
 (crontab -l 2>/dev/null; echo "0 5 * * 1 cd / && run-parts --report /etc/cron.weekly > /proc/1/fd/1") | crontab - && \
 # monthly at 00:00 on 1st of month
 (crontab -l 2>/dev/null; echo "0 0 1 * * cd / && run-parts --report /etc/cron.monthly > /proc/1/fd/1") | crontab -

COPY root/ /

ENV XDG_CONFIG_HOME=/config

VOLUME /config

ENTRYPOINT ["/init"]
