FROM python
LABEL maintainer="plaintext@andromedarabbit.net"

# Set the timezone to KST
RUN cat /usr/share/zoneinfo/Asia/Seoul > /etc/localtime

RUN useradd --user-group --system --create-home --no-log-init --uid 1000 --shell /bin/bash app

ENV SLACKCAT_VERSION 1.6

RUN set -ex; \
	export DEBIAN_FRONTEND=noninteractive; \
	runDeps='curl ca-certificates xvfb wkhtmltopdf'; \
	buildDeps=''; \
	pipDeps='awscli ansi2html'; \
	apt-get update && apt-get install -y $runDeps $buildDeps --no-install-recommends; \
	rm -rf /var/lib/apt/lists/*; \
	apt-get purge -y --auto-remove $buildDeps; \
	rm /var/log/dpkg.log /var/log/apt/*.log; \
	pip install $pipDeps;

RUN curl --silent -Lo slackcat https://github.com/bcicen/slackcat/releases/download/v${SLACKCAT_VERSION}/slackcat-${SLACKCAT_VERSION}-$(uname -s)-amd64 \
	&& chmod +x slackcat \
	&& chown app:app slackcat \
	&& mv slackcat /usr/local/bin/

RUN curl -sL https://github.com/toniblyx/prowler/archive/master.tar.gz | tar xz \
	&& mv prowler-master /prowler \
	&& chown -R app:app /prowler

USER app
WORKDIR /home/app

CMD ./prowler