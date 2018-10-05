# Copyright (c) 2012-2017 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc.- initial API and implementation


FROM registry.centos.org/che-stacks/centos-stack-base

EXPOSE 8085 8087


RUN sudo yum -y update && \
    sudo yum install -y epel-release

RUN sudo yum install -y supervisor &&\
    sudo yum clean all 




RUN mkdir $HOME/.m2 && \
   wget -O  /home/user/tomcat8.zip "https://oss.sonatype.org/content/repositories/releases/org/eclipse/che/lib/che-tomcat8-slf4j-logback/6.11.0/che-tomcat8-slf4j-logback-6.11.0.zip" ;\
   unzip   /home/user/tomcat8.zip -d /home/user/tomcat8;\
   rm /home/user/tomcat8.zip;\
   mkdir /home/user/tomcat8/webapps;\
   sed -i -- 's/autoDeploy=\"false\"/autoDeploy=\"true\"/g' /home/user/tomcat8/conf/server.xml; \
   sed -i 's/<Context>/<Context reloadable=\"true\">/g' /home/user/tomcat8/conf/context.xml; 
  

USER user

ENV LD_LIBRARY_PATH=\
 TOMCAT_HOME=/home/user/tomcat8 \
 TERM=xterm 


RUN mkdir /home/user/traefik ;\
    wget -O /home/user/traefik/traefik "https://github.com/containous/traefik/releases/download/v1.4.3/traefik_linux-amd64"; \
    chmod +x /home/user/traefik/traefik
COPY traefik.toml /home/user/traefik/
ADD entrypoint.sh /home/user/entrypoint.sh

RUN mkdir /tmp/agent

COPY --from=eclipse/che-server:6.11.1 /home/user/eclipse-che/tomcat/webapps/ROOT.war /home/user/tomcat8/webapps/ide.war
COPY --from=eclipse/che-server:6.11.1 /home/user/eclipse-che/lib/ws-agent.tar.gz /tmp/agent

RUN cd /tmp/agent && tar -xvf ws-agent.tar.gz && cp webapps/ROOT.war /home/user/tomcat8/webapps/ && rm -rf /tmp/agent



# Change permissions to allow editing of files for openshift user
RUN find ${HOME} -exec sh -c "sudo chgrp 0 {}; sudo chmod g+rwX {}" \;
# Grant permissions for modifying supervisor log file
RUN sudo touch /var/log/supervisord.log && sudo chmod g+rwX /var/log/supervisord.log && sudo chgrp 0 /var/log/supervisord.log

ADD supervisord.conf /etc/

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
