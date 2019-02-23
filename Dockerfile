FROM centos:centos7
MAINTAINER "Hiroki Takeyama"

# postfix
RUN groupadd -g 5000 vmail; \
    useradd -g 5000 -u 5000 -s /sbin/nologin vmail; \
    mkdir /mailbox; \
    yum -y install postfix cyrus-sasl-plain cyrus-sasl-md5 openssl; \
    sed -i 's/^\(inet_interfaces =\) .*/\1 all/' /etc/postfix/main.cf; \
    { \
    echo 'smtpd_sasl_path = smtpd'; \
    echo 'smtpd_sasl_auth_enable = yes'; \
    echo 'broken_sasl_auth_clients = yes'; \
    echo 'smtpd_sasl_security_options = noanonymous'; \
    echo 'smtpd_recipient_restrictions = permit_sasl_authenticated, reject_unauth_destination'; \
    echo 'virtual_mailbox_base = /mailbox'; \
    echo 'virtual_mailbox_maps = hash:/etc/postfix/vmailbox'; \
    echo 'virtual_uid_maps = static:5000'; \
    echo 'virtual_gid_maps = static:5000'; \
    echo 'home_mailbox = /'; \
    echo 'local_recipient_maps ='; \
    echo 'luser_relay = unknown_user@localhost'; \
    } >> /etc/postfix/main.cf; \
    { \
    echo 'pwcheck_method: auxprop'; \
    echo 'auxprop_plugin: sasldb'; \
    echo 'mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5'; \
    } > /etc/sasl2/smtpd.conf; \
    sed -i 's/^#\(submission .*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(.*smtpd_sasl_auth_enable.*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(.*smtpd_recipient_restrictions.*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(smtps .*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(.*smtpd_tls_wrappermode.*\)/\1/' /etc/postfix/master.cf; \
    echo 'unknown_user: /dev/null' >> /etc/aliases; \
    newaliases; \
    openssl genrsa -aes128 -passout pass:dummy -out "/etc/postfix/key.pass.pem" 2048; \
    openssl rsa -passin pass:dummy -in "/etc/postfix/key.pass.pem" -out "/etc/postfix/key.pem"; \
    rm -f "/etc/postfix/key.pass.pem"; \
    { \
    echo 'smtpd_tls_cert_file = /etc/postfix/cert.pem'; \
    echo 'smtpd_tls_key_file = /etc/postfix/key.pem'; \
    echo 'smtpd_tls_security_level = may'; \
    echo 'smtpd_tls_received_header = yes'; \
    echo 'smtpd_tls_loglevel = 1'; \
    echo 'smtp_tls_security_level = may'; \
    echo 'smtp_tls_loglevel = 1'; \
    echo 'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache'; \
    echo 'tls_random_source = dev:/dev/urandom'; \
    } >> /etc/postfix/main.cf; \
    yum clean all;

# dovecot
RUN yum -y install dovecot; \
    echo 'mail_location = maildir:~/' >> /etc/dovecot/conf.d/10-mail.conf; \
    echo 'disable_plaintext_auth = no' >> /etc/dovecot/conf.d/10-auth.conf; \
    sed -i 's/^\(!include auth-system.conf.ext\)/#\1/' /etc/dovecot/conf.d/10-auth.conf; \
    sed -i 's/^#\(!include auth-passwdfile.conf.ext\)/\1/' /etc/dovecot/conf.d/10-auth.conf; \
    sed -i 's/^#\(!include auth-static.conf.ext\)/\1/' /etc/dovecot/conf.d/10-auth.conf; \
    { \
    echo 'passdb {'; \
    echo '  driver = passwd-file'; \
    echo '  args = scheme=CRAM-MD5 username_format=%u /etc/dovecot/users'; \
    echo '}'; \
    } > /etc/dovecot/conf.d/auth-passwdfile.conf.ext; \
    { \
    echo 'userdb {'; \
    echo '  driver = static'; \
    echo '  args = uid=vmail gid=vmail home=/mailbox/%u'; \
    echo '}'; \
    } > /etc/dovecot/conf.d/auth-static.conf.ext; \
    sed -i 's/^\(ssl =\).*/\1 yes/' /etc/dovecot/conf.d/10-ssl.conf; \
    sed -i 's/^\(ssl_cert = <\).*/\1\/etc\/postfix\/cert.pem/' /etc/dovecot/conf.d/10-ssl.conf; \
    sed -i 's/^\(ssl_key = <\).*/\1\/etc\/postfix\/key.pem/' /etc/dovecot/conf.d/10-ssl.conf; \
    yum clean all;

# rsyslog
RUN yum -y install rsyslog; \
    sed -i 's/^\(\$SystemLogSocketName\) .*/\1 \/dev\/log/' /etc/rsyslog.d/listen.conf; \
    sed -i 's/^\(\$ModLoad imjournal\)/#\1/' /etc/rsyslog.conf; \
    sed -i 's/^\(\$OmitLocalLogging\) .*/\1 off/' /etc/rsyslog.conf; \
    sed -i 's/^\(\$IMJournalStateFile .*\)/#\1/' /etc/rsyslog.conf; \
    yum clean all;

# supervisor
RUN yum -y install epel-release; \
    yum -y --enablerepo=epel install supervisor; \
    sed -i 's/^\(nodaemon\)=false/\1=true/' /etc/supervisord.conf; \
    sed -i '/^\[unix_http_server\]$/a username=dummy' /etc/supervisord.conf; \
    sed -i '/^\[unix_http_server\]$/a password=dummy' /etc/supervisord.conf; \
    sed -i '/^\[supervisorctl\]$/a username=dummy' /etc/supervisord.conf; \
    sed -i '/^\[supervisorctl\]$/a password=dummy' /etc/supervisord.conf; \
    { \
    echo '[program:postfix]'; \
    echo 'command=/usr/sbin/postfix -c /etc/postfix start'; \
    echo 'startsecs=0'; \
    } > /etc/supervisord.d/postfix.ini; \
    { \
    echo '[program:dovecot]'; \
    echo 'command=/usr/sbin/dovecot -F'; \
    } > /etc/supervisord.d/dovecot.ini; \
    { \
    echo '[program:rsyslog]'; \
    echo 'command=/usr/sbin/rsyslogd -n'; \
    } > /etc/supervisord.d/rsyslog.ini; \
    { \
    echo '[program:tail]'; \
    echo 'command=/usr/bin/tail -f /var/log/maillog'; \
    echo 'stdout_logfile=/dev/fd/1'; \
    echo 'stdout_logfile_maxbytes=0'; \
    } > /etc/supervisord.d/tail.ini; \
    yum clean all;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'rm -f /etc/localtime'; \
    echo 'ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime'; \
    echo 'if [ ! -e /etc/postfix/cert.pem ]; then'; \
    echo '  openssl req -new -key "/etc/postfix/key.pem" -subj "/CN=${HOST_NAME}" -out "/etc/postfix/csr.pem"'; \
    echo '  openssl x509 -req -days 36500 -in "/etc/postfix/csr.pem" -signkey "/etc/postfix/key.pem" -out "/etc/postfix/cert.pem" &>/dev/null'; \
    echo 'fi'; \
    echo 'if [ -e /etc/sasldb2 ]; then'; \
    echo '  rm -f /etc/sasldb2'; \
    echo '  rm -f /etc/dovecot/users'; \
    echo '  rm -f /etc/postfix/vmailbox'; \
    echo 'fi'; \
    echo 'ARRAY_USER=(`echo ${AUTH_USER} | tr "," " "`)'; \
    echo 'ARRAY_PASSWORD=(`echo ${AUTH_PASSWORD} | tr "," " "`)'; \
    echo 'INDEX=0'; \
    echo 'for e in ${ARRAY_USER[@]}; do'; \
    echo '  echo "${ARRAY_PASSWORD[${INDEX}]}" | /usr/sbin/saslpasswd2 -p -c -u ${DOMAIN_NAME} ${ARRAY_USER[${INDEX}]}'; \
    echo '  echo "${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}:`doveadm pw -p ${ARRAY_PASSWORD[${INDEX}]}`" >> /etc/dovecot/users'; \
    echo '  echo "${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME} ${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}/" >> /etc/postfix/vmailbox'; \
    echo '  mkdir -p /mailbox/${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}'; \
    echo '  chown -R vmail:vmail /mailbox/${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}'; \
    echo '  ((INDEX+=1))'; \
    echo 'done'; \
    echo 'chown postfix:postfix /etc/sasldb2'; \
    echo 'postmap /etc/postfix/vmailbox'; \
    echo 'rm -f /var/log/maillog'; \
    echo 'touch /var/log/maillog'; \
    echo 'sed -i '\''/^# BEGIN SMTP SETTINGS$/,/^# END SMTP SETTINGS$/d'\'' /etc/postfix/main.cf'; \
    echo '{'; \
    echo 'echo "# BEGIN SMTP SETTINGS"'; \
    echo 'echo "myhostname = ${HOST_NAME}"'; \
    echo 'echo "mydomain = ${DOMAIN_NAME}"'; \
    echo 'echo "myorigin = \$mydomain"'; \
    echo 'echo "smtpd_banner = \$myhostname ESMTP unknown"'; \
    echo 'echo "message_size_limit = ${MESSAGE_SIZE_LIMIT}"'; \
    echo 'echo "virtual_mailbox_domains = ${DOMAIN_NAME}"'; \
    echo 'echo "# END SMTP SETTINGS"'; \
    echo '} >> /etc/postfix/main.cf'; \
    echo 'chown vmail:vmail /mailbox'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh; \
    chmod +x /usr/local/bin/entrypoint.sh;
ENTRYPOINT ["entrypoint.sh"]

ENV TIMEZONE Asia/Tokyo

ENV HOST_NAME mail.example.com
ENV DOMAIN_NAME example.com

ENV MESSAGE_SIZE_LIMIT 10240000

ENV AUTH_USER user1,user2
ENV AUTH_PASSWORD password1,password2

# SMTP
EXPOSE 25
EXPOSE 587

# SMTPS
EXPOSE 465

# POP3/IMAP
EXPOSE 110
EXPOSE 143

# POP3S/IMAPS
EXPOSE 995
EXPOSE 993

VOLUME /mailbox

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
