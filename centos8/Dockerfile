FROM centos:centos8
MAINTAINER "Hiroki Takeyama"

# openssl
RUN mkdir /ssl_certs; \
    dnf -y install openssl; \
    dnf clean all;

# mailbox
RUN mkdir /mailbox; \
    groupadd -g 5000 vmail; \
    useradd -u 5000 -g vmail -s /sbin/nologin vmail;

# postfix
RUN dnf -y install epel-release; \
    dnf -y install postfix cyrus-sasl-plain cyrus-sasl-md5; \
    sed -i 's/^\(inet_interfaces =\) .*/\1 all/' /etc/postfix/main.cf; \
    sed -i 's/^\(smtpd_tls_cert_file =\) .*/\1 \/ssl_certs\/cert.pem/' /etc/postfix/main.cf; \
    sed -i 's/^\(smtpd_tls_key_file =\) .*/\1 \/ssl_certs\/key.pem/' /etc/postfix/main.cf; \
    { \
    echo 'smtpd_sasl_type = dovecot'; \
    echo 'smtpd_sasl_path = private/auth'; \
    echo 'smtpd_sasl_auth_enable = yes'; \
    echo 'broken_sasl_auth_clients = yes'; \
    echo 'smtpd_sasl_security_options = noanonymous'; \
    echo 'disable_vrfy_command = yes'; \
    echo 'smtpd_helo_required = yes'; \
    echo 'smtpd_client_restrictions = permit_sasl_authenticated, reject_unknown_client_hostname'; \
    echo 'smtpd_helo_restrictions = permit_sasl_authenticated, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname, reject_unknown_helo_hostname'; \
    echo 'smtpd_sender_restrictions = reject_non_fqdn_sender, reject_unknown_sender_domain'; \
    echo 'smtpd_recipient_restrictions = permit_sasl_authenticated, reject_unauth_destination'; \
    echo 'smtpd_data_restrictions = reject_unauth_pipelining'; \
    echo 'smtpd_tls_security_level = may'; \
    echo 'smtpd_tls_received_header = yes'; \
    echo 'smtpd_tls_loglevel = 1'; \
    echo 'smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache'; \
    echo 'smtp_tls_security_level = may'; \
    echo 'smtp_tls_loglevel = 1'; \
    echo 'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache'; \
    echo 'tls_random_source = dev:/dev/urandom'; \
    echo 'virtual_mailbox_base = /mailbox'; \
    echo 'virtual_mailbox_maps = hash:/etc/postfix/vmailbox'; \
    echo 'virtual_alias_maps = hash:/etc/postfix/virtual'; \
    echo 'virtual_gid_maps = static:5000'; \
    echo 'virtual_uid_maps = static:5000'; \
    echo 'home_mailbox = /'; \
    } >> /etc/postfix/main.cf; \
    sed -i 's/^#\(submission .*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(smtps .*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(.* syslog_name=.*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(.* smtpd_sasl_auth_enable=.*\)/\1/' /etc/postfix/master.cf; \
    sed -i 's/^#\(.* smtpd_recipient_restrictions=\).*/\1permit_sasl_authenticated,reject/' /etc/postfix/master.cf; \
    sed -i 's/^#\(.* smtpd_tls_wrappermode=.*\)/\1/' /etc/postfix/master.cf; \
    echo 'unknown: /dev/null' >> /etc/aliases; \
    newaliases; \
    dnf clean all;

# dovecot
RUN dnf -y install dovecot; \
    sed -i '/^service auth {$/a unix_listener /var/spool/postfix/private/auth {\nmode = 0660\nuser = postfix\ngroup = postfix\n}' /etc/dovecot/conf.d/10-master.conf; \
    sed -i 's/^#\(mail_location =\).*/\1 maildir:~\//' /etc/dovecot/conf.d/10-mail.conf; \
    sed -i 's/^#\(disable_plaintext_auth =\).*/\1 no/' /etc/dovecot/conf.d/10-auth.conf; \
    sed -i 's/^\(auth_mechanisms =\).*/\1 plain login cram-md5/' /etc/dovecot/conf.d/10-auth.conf; \
    sed -i 's/^\(!include auth-system.conf.ext\)/#\1/' /etc/dovecot/conf.d/10-auth.conf; \
    sed -i 's/^#\(!include auth-passwdfile.conf.ext\)/\1/' /etc/dovecot/conf.d/10-auth.conf; \
    sed -i 's/^#\(!include auth-static.conf.ext\)/\1/' /etc/dovecot/conf.d/10-auth.conf; \
    { \
    echo 'passdb {'; \
    echo '  driver = passwd-file'; \
    echo '  args = username_format=%u /etc/dovecot/users'; \
    echo '}'; \
    } > /etc/dovecot/conf.d/auth-passwdfile.conf.ext; \
    { \
    echo 'userdb {'; \
    echo '  driver = static'; \
    echo '  args = uid=vmail gid=vmail home=/mailbox/%u'; \
    echo '}'; \
    } > /etc/dovecot/conf.d/auth-static.conf.ext; \
    sed -i 's/^\(ssl =\).*/\1 yes/' /etc/dovecot/conf.d/10-ssl.conf; \
    sed -i 's/^\(ssl_cert = <\).*/\1\/ssl_certs\/cert.pem/' /etc/dovecot/conf.d/10-ssl.conf; \
    sed -i 's/^\(ssl_key = <\).*/\1\/ssl_certs\/key.pem/' /etc/dovecot/conf.d/10-ssl.conf; \
    dnf clean all;

# opendkim
RUN mkdir /dkim_keys; \
    dnf -y install opendkim glibc-locale-source; \
    sed -i 's/^\(Mode\t\).*/\1sv/' /etc/opendkim.conf; \
    sed -i 's/^\(SoftwareHeader\t\).*/\1no/' /etc/opendkim.conf; \
    sed -i 's/^# *\(Domain\t.*\)/\1/' /etc/opendkim.conf; \
    echo 'smtpd_milters = inet:localhost:8891' >> /etc/postfix/main.cf; \
    echo 'non_smtpd_milters = $smtpd_milters' >> /etc/postfix/main.cf; \
    echo 'milter_default_action = accept' >> /etc/postfix/main.cf; \
    dnf clean all;

# opendmarc
RUN dnf -y install opendmarc; \
    sed -i 's/^# *\(AuthservID\) .*/\1 OpenDMARC/' /etc/opendmarc.conf; \
    sed -i 's/^# *\(IgnoreAuthenticatedClients\) .*/\1 true/' /etc/opendmarc.conf; \
    sed -i 's/^# *\(RejectFailures\) .*/\1 true/' /etc/opendmarc.conf; \
    sed -i 's/^# *\(RequiredHeaders\) .*/\1 true/' /etc/opendmarc.conf; \
    sed -i 's/^\(smtpd_milters = .*\)/\1,inet:localhost:8893/' /etc/postfix/main.cf; \
    dnf clean all;

# rsyslog
RUN dnf -y install rsyslog; \
    sed -i 's/\(SysSock\.Use\)="off"/\1="on"/' /etc/rsyslog.conf; \
    sed -i 's/\(^module.*load.*imjournal.*\)/#\1/' /etc/rsyslog.conf; \
    sed -i 's/\(.*StateFile.*imjournal.*\)/#\1/' /etc/rsyslog.conf; \
    dnf clean all;

# supervisor
RUN mkdir /run/supervisor; \
    dnf -y install supervisor; \
    sed -i 's/^\(nodaemon\)=false/\1=true/' /etc/supervisord.conf; \
    sed -i 's/^;\(user\)=chrism/\1=root/' /etc/supervisord.conf; \
    sed -i '/^\[unix_http_server\]$/a username=dummy\npassword=dummy' /etc/supervisord.conf; \
    sed -i '/^\[supervisorctl\]$/a username=dummy\npassword=dummy' /etc/supervisord.conf; \
    { \
    echo '[program:postfix]'; \
    echo 'command=/usr/sbin/postfix -c /etc/postfix start'; \
    echo 'priority=6'; \
    echo 'startsecs=0'; \
    } > /etc/supervisord.d/postfix.ini; \
    { \
    echo '[program:opendmarc]'; \
    echo 'command=/usr/sbin/opendmarc -f -c /etc/opendmarc.conf'; \
    echo 'priority=5'; \
    } > /etc/supervisord.d/opendmarc.ini; \
    { \
    echo '[program:opendkim]'; \
    echo 'command=/usr/sbin/opendkim -f -x /etc/opendkim.conf'; \
    echo 'priority=4'; \
    } > /etc/supervisord.d/opendkim.ini; \
    { \
    echo '[program:dovecot]'; \
    echo 'command=/usr/sbin/dovecot -F'; \
    echo 'priority=3'; \
    } > /etc/supervisord.d/dovecot.ini; \
    { \
    echo '[program:rsyslog]'; \
    echo 'command=/usr/sbin/rsyslogd -n'; \
    echo 'priority=2'; \
    } > /etc/supervisord.d/rsyslog.ini; \
    { \
    echo '[program:tail]'; \
    echo 'command=/usr/bin/tail -F /var/log/maillog'; \
    echo 'priority=1'; \
    echo 'stdout_logfile=/dev/fd/1'; \
    echo 'stdout_logfile_maxbytes=0'; \
    } > /etc/supervisord.d/tail.ini; \
    dnf clean all;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime'; \
    echo 'rm -f /var/log/maillog'; \
    echo 'touch /var/log/maillog'; \
    echo 'if [ ! -e /ssl_certs/cert.pem ] || [ ! -e /ssl_certs/key.pem ]; then'; \
    echo '  openssl genrsa -out "/ssl_certs/key.pem" 2048 &>/dev/null'; \
    echo '  openssl req -new -key "/ssl_certs/key.pem" -subj "/CN=${HOSTNAME}" -out "/ssl_certs/csr.pem"'; \
    echo '  openssl x509 -req -days 36500 -in "/ssl_certs/csr.pem" -signkey "/ssl_certs/key.pem" -out "/ssl_certs/cert.pem" &>/dev/null'; \
    echo 'fi'; \
    echo 'sed -i "s/^\(smtpd_sasl_auth_enable =\).*/\1 yes/" /etc/postfix/main.cf'; \
    echo 'if [ ${DISABLE_SMTP_AUTH_ON_PORT_25,,} = "true" ]; then'; \
    echo '  sed -i "s/^\(smtpd_sasl_auth_enable =\).*/\1 no/" /etc/postfix/main.cf'; \
    echo 'fi'; \
    echo 'if [ -e /etc/dovecot/users ]; then'; \
    echo '  rm -f /etc/dovecot/users'; \
    echo '  rm -f /etc/postfix/vmailbox'; \
    echo '  rm -f /etc/postfix/virtual'; \
    echo 'fi'; \
    echo 'ARRAY_USER=(`echo ${AUTH_USER} | tr "," " "`)'; \
    echo 'ARRAY_PASSWORD=(`echo ${AUTH_PASSWORD} | tr "," " "`)'; \
    echo 'INDEX=0'; \
    echo 'for e in ${ARRAY_USER[@]}; do'; \
    echo '  echo "${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}:`doveadm pw -s CRAM-MD5 -p ${ARRAY_PASSWORD[${INDEX}]}`" >> /etc/dovecot/users'; \
    echo '  echo "${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME} ${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}/" >> /etc/postfix/vmailbox'; \
    echo '  echo "${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME} ${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}" >> /etc/postfix/virtual'; \
    echo '  mkdir -p /mailbox/${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}'; \
    echo '  chown -R vmail:vmail /mailbox/${ARRAY_USER[${INDEX}]}@${DOMAIN_NAME}'; \
    echo '  ((INDEX+=1))'; \
    echo 'done'; \
    echo 'if [ ${BOUNCE_MESSAGE,,} != "true" ]; then'; \
    echo '  echo "@${DOMAIN_NAME} unknown@localhost" >> /etc/postfix/virtual'; \
    echo 'fi'; \
    echo 'postmap /etc/postfix/vmailbox'; \
    echo 'postmap /etc/postfix/virtual'; \
    echo 'chown vmail:vmail /mailbox'; \
    echo 'sed -i "/^notify_classes =.*/d" /etc/postfix/main.cf'; \
    echo 'sed -i "/^bounce_notice_recipient =.*/d" /etc/postfix/main.cf'; \
    echo 'sed -i "/^error_notice_recipient =.*/d" /etc/postfix/main.cf'; \
    echo 'if [ -n "${NOTICE_RECIPIENT}" ]; then'; \
    echo '  echo "notify_classes = bounce, resource, software" >> /etc/postfix/main.cf'; \
    echo '  echo "bounce_notice_recipient = ${NOTICE_RECIPIENT}@${DOMAIN_NAME}" >> /etc/postfix/main.cf'; \
    echo '  echo "error_notice_recipient = ${NOTICE_RECIPIENT}@${DOMAIN_NAME}" >> /etc/postfix/main.cf'; \
    echo 'fi'; \
    echo 'sed -i '\''/^# BEGIN SMTP SETTINGS$/,/^# END SMTP SETTINGS$/d'\'' /etc/postfix/main.cf'; \
    echo '{'; \
    echo 'echo "# BEGIN SMTP SETTINGS"'; \
    echo 'echo "myhostname = ${HOSTNAME}"'; \
    echo 'echo "mydomain = ${DOMAIN_NAME}"'; \
    echo 'echo "smtpd_banner = \$myhostname ESMTP"'; \
    echo 'echo "virtual_mailbox_domains = ${DOMAIN_NAME}"'; \
    echo 'echo "virtual_mailbox_limit = ${MAILBOX_SIZE_LIMIT}"'; \
    echo 'echo "message_size_limit = ${MESSAGE_SIZE_LIMIT}"'; \
    echo 'echo "anvil_rate_time_unit = ${ANVIL_RATE_TIME_UNIT}"'; \
    echo 'echo "smtpd_client_connection_rate_limit = ${SMTPD_CLIENT_CONNECTION_RATE_LIMIT}"'; \
    echo 'echo "# END SMTP SETTINGS"'; \
    echo '} >> /etc/postfix/main.cf'; \
    echo 'if [ -e /etc/supervisord.d/opendkim.ini ]; then'; \
    echo '  mv /etc/supervisord.d/opendkim.ini /etc/supervisord.d/opendkim.disabled'; \
    echo 'fi'; \
    echo 'sed -i "s/^\(smtpd_milters .*\)/#\1/" /etc/postfix/main.cf'; \
    echo 'sed -i "s/^\(non_smtpd_milters .*\)/#\1/" /etc/postfix/main.cf'; \
    echo 'if [ ${ENABLE_DKIM,,} = "true" ]; then'; \
    echo '  mv /etc/supervisord.d/opendkim.disabled /etc/supervisord.d/opendkim.ini'; \
    echo '  sed -i "s/^#\(smtpd_milters =\).*/\1 inet:localhost:8891/" /etc/postfix/main.cf'; \
    echo '  sed -i "s/^#\(non_smtpd_milters .*\)/\1/" /etc/postfix/main.cf'; \
    echo '  sed -i "s/^\(Domain\t\).*/\1${DOMAIN_NAME}/" /etc/opendkim.conf'; \
    echo '  sed -i "s/^\(Selector\t\).*/\1${DKIM_SELECTOR}/" /etc/opendkim.conf'; \
    echo '  sed -i "s/^\(KeyFile\t\).*/\1\/dkim_keys\/${DKIM_SELECTOR}\.private/" /etc/opendkim.conf'; \
    echo '  if [ ! -e /dkim_keys/${DKIM_SELECTOR}.private ] || [ ! -e /dkim_keys/${DKIM_SELECTOR}.txt ]; then'; \
    echo '    opendkim-genkey -b ${DKIM_KEY_LENGTH} -d ${DOMAIN_NAME} -s ${DKIM_SELECTOR} -D /dkim_keys'; \
    echo '  fi'; \
    echo '  chown -R opendkim:opendkim /dkim_keys'; \
    echo '  chmod o-rwx /dkim_keys/${DKIM_SELECTOR}.private'; \
    echo '  cat /dkim_keys/${DKIM_SELECTOR}.txt'; \
    echo 'fi'; \
    echo 'if [ -e /etc/supervisord.d/opendmarc.ini ]; then'; \
    echo '  mv /etc/supervisord.d/opendmarc.ini /etc/supervisord.d/opendmarc.disabled'; \
    echo 'fi'; \
    echo 'if [ ${ENABLE_DMARC,,} = "true" ]; then'; \
    echo '  mv /etc/supervisord.d/opendmarc.disabled /etc/supervisord.d/opendmarc.ini'; \
    echo '  sed -i "s/^\(smtpd_milters .*\)/\1,inet:localhost:8893/" /etc/postfix/main.cf'; \
    echo '  sed -i "s/^#\(smtpd_milters =\).*/\1 inet:localhost:8893/" /etc/postfix/main.cf'; \
    echo '  sed -i "s/^#\(non_smtpd_milters .*\)/\1/" /etc/postfix/main.cf'; \
    echo '  sed -i "s/^#* *\(TrustedAuthservIDs\) .*/\1 ${HOSTNAME}/" /etc/opendmarc.conf'; \
    echo 'fi'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh; \
    chmod +x /usr/local/bin/entrypoint.sh;

ENV TIMEZONE Asia/Tokyo

ENV HOSTNAME mail.example.com
ENV DOMAIN_NAME example.com

ENV MAILBOX_SIZE_LIMIT 0
ENV MESSAGE_SIZE_LIMIT 10240000

ENV AUTH_USER user1,user2
ENV AUTH_PASSWORD password1,password2

ENV DISABLE_SMTP_AUTH_ON_PORT_25 true
ENV BOUNCE_MESSAGE true
ENV NOTICE_RECIPIENT user1

ENV ANVIL_RATE_TIME_UNIT 60s
ENV SMTPD_CLIENT_CONNECTION_RATE_LIMIT 0

ENV ENABLE_DKIM true
ENV DKIM_KEY_LENGTH 1024
ENV DKIM_SELECTOR default

ENV ENABLE_DMARC true

# MailBox
VOLUME /mailbox
# SSL Certificates
VOLUME /ssl_certs
# DKIM Keys
VOLUME /dkim_keys

# SMTP
EXPOSE 25
# Submission
EXPOSE 587
# SMTPS
EXPOSE 465

# POP3
EXPOSE 110
# IMAP
EXPOSE 143

# POP3S
EXPOSE 995
# IMAPS
EXPOSE 993

ENTRYPOINT ["entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
