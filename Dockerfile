#Creating Images for ASSP web service 
FROM alpine:3.5

RUN { \
       echo '@edge http://nl.alpinelinux.org/alpine/edge/main'; \
       echo '@testing http://nl.alpinelinux.org/alpine/edge/testing'; \
    } | tee >> /etc/apk/repositories


ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk update && apk upgrade
RUN true && \
	apk add --update tzdata postfix bash supervisor perl perl-sys-hostname-long perl-net-dns make automake gcc \
	perl-lwp-protocol-https perl-dbd-pg perl-dbd-mysql perl-dbd-sqlite perl-cgi-psgi perl-cgi perl-fcgi perl-term-readkey \ 
	perl-xml-rss perl-crypt-ssleay perl-crypt-eksblowfish perl-crypt-x509 perl-html-mason-psgihandler perl-fcgi-procmanager \ 
	perl-mime-types perl-list-moreutils perl-json perl-html-quoted perl-html-scrubber perl-email-address perl-text-password-pronounceable \
	perl-email-address-list perl-html-formattext-withlinks-andtables perl-html-rewriteattributes perl-text-wikiformat perl-text-quoted \
	perl-datetime-format-natural perl-date-extract perl-data-guid perl-data-ical perl-string-shellquote perl-convert-color perl-dbix-searchbuilder \
	perl-file-which perl-css-squish perl-tree-simple perl-plack perl-log-dispatch perl-module-versions-report perl-symbol-global-name \
	perl-devel-globaldestruction perl-parallel-prefork perl-cgi-emulate-psgi perl-text-template perl-net-cidr perl-apache-session \
	perl-locale-maketext-lexicon perl-locale-maketext-fuzzy perl-regexp-common-net-cidr perl-module-refresh perl-date-manip perl-regexp-ipv6 \
	perl-text-wrapper perl-universal-require perl-role-basic perl-convert-binhex perl-test-sharedfork perl-test-tcp perl-server-starter \
	perl-starlet perl-dev libc-dev openssl openssl-dev db-dev yaml opendkim gnupg linux-headers dnssec-root rsyslog && \
	(rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)

# Install CPAN modules
RUN cpan CPAN Log::Log4perl
# RUN cpan -T Authen::SASL
RUN cpan BerkeleyDB BerkeleyDB_DBEngine Convert::TNEF DB_File Email::MIME Email::Send File::ReadBackwards MIME::Types Mail::DKIM::Verifier
RUN cpan -T Mail::SPF Mail::SPF::Query Schedule::Cron Filesys::DiskSpace Sys::CpuAffinity
RUN cpan Mail::SRS Net::CIDR::Lite Net::IP Net::LDAP NetAddr::IP::Lite Regexp::Optimizer Sys::MemInfo Text::Unidecode Thread::State Tie::RDBM \
         Unicode::GCString Convert::Scalar Lingua::Stem::Snowball Lingua::Identify IO::Socket::SSL Archive::Extract Archive::Zip \
         IO::Socket::INET6 Filesys::Df
RUN rm -rf /root/.cpan/* 2>/dev/null

# Get ASSP
RUN true & \
    mkdir -p /usr/share/assp && cd /usr/share && \
    wget https://sourceforge.net/projects/assp/files/latest/download?source=files -O ASSP.zip && \
    unzip ASSP.zip && \
    cd assp && \
    wget http://assp.cvs.sourceforge.net/viewvc/assp/assp2/filecommander/?view=tar -O assp-filecommander.tar.gz && \
    tar xzvf assp-filecommander.tar.gz && \
    unzip filecommander/1.05.ZIP && \
    mv 1.05/images/* /usr/share/assp/images && \
    mv 1.05/lib/* /usr/share/assp/lib && \
    wget  http://assp.cvs.sourceforge.net/viewvc/assp/assp2/lib/?view=tar -O assp-lib.tar.gz && \
    tar xzvf assp-lib.tar.gz

# Configure DKIM
RUN cp /etc/opendkim/opendkim.conf.sample /etc/opendkim/opendkim.conf && \
    { \
      echo 'Canonicalization        relaxed/simple'; \
      echo 'ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts'; \
      echo 'InternalHosts           refile:/etc/opendkim/TrustedHosts'; \
      echo 'KeyTable                refile:/etc/opendkim/KeyTable'; \
      echo 'SigningTable            refile:/etc/opendkim/SigningTable'; \
    } | tee >> /etc/opendkim/opendkim.conf && \
    sed -i -r -e 's/inet:port@localhost/inet:12301@localhost/' /etc/opendkim/opendkim.conf

# Configure supervisord
RUN { \
	echo '[supervisord]'; \
	echo 'nodaemon        = true'; \
	echo 'logfile         = /dev/null'; \
	echo 'logfile_maxbytes= 0'; \
	echo; \
	echo '[program:postfix]'; \
	echo 'process_name    = postfix'; \
	echo 'autostart       = true'; \
	echo 'autorestart     = false'; \
	echo 'directory       = /etc/postfix'; \
	echo 'command         = /usr/sbin/postfix.sh'; \
	echo 'startsecs       = 0'; \
	echo; \
	echo '[program:opendkim]'; \
	echo 'process_name    = opendkim'; \
	echo 'autostart       = true'; \
	echo 'autorestart     = false'; \
	echo 'directory       = /etc/opendkim'; \
	echo 'command         = /usr/sbin/opendkim -p inet:12301 -x /etc/opendkim/opendkim.conf'; \
	echo 'startsecs       = 0'; \
	echo; \
	echo '[program:assp]'; \
	echo 'process_name    = assp'; \
	echo 'autostart       = true'; \
	echo 'autorestart     = true'; \
	echo 'directory       = /usr/share/assp'; \
	echo 'command         = /usr/share/assp/assp.pl'; \
	echo 'startsecs       = 0'; \
	echo; \
	echo '[program:syslog]'; \
	echo 'process_name    = syslog'; \
	echo 'autostart       = true'; \
	echo 'autorestart     = false'; \
	echo 'directory       = /etc'; \
	echo 'command         = /sbin/syslogd'; \
	echo 'startsecs       = 0'; \
	} | tee /etc/supervisord.conf

# Configure postfix
RUN postconf -e smtputf8_enable=no
RUN postalias /etc/postfix/aliases
RUN postconf -e mydestination=
RUN postconf -e relay_domains=
RUN postconf -e smtpd_delay_reject=yes
RUN postconf -e smtpd_helo_required=yes
RUN postconf -e "smtpd_helo_restrictions=permit_mynetworks,reject_invalid_helo_hostname,permit"
RUN postconf -e "mynetworks=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
RUN sed -i -r -e 's/^#submission/submission/' -e 's/smtp      inet  n       -       n       -       -       smtpd/125      inet  n       -       n       -       -       smtpd/' /etc/postfix/master.cf

# Create postfix.sh
RUN { \
    echo '# Fix permissions'; \
    echo 'chown root /var/spool/postfix/.'; \
    echo 'chown root /var/spool/postfix/pid'; \
    echo 'chown root /etc/postfix/*'; \
    echo ; \
    echo '/usr/sbin/postfix -c /etc/postfix start'; \
} | tee /postfix.sh

RUN chmod +x /postfix.sh
RUN chmod +x /usr/share/assp/assp.pl
RUN mkdir -p /etc/assp && ln -s /etc/assp/assp.cfg /usr/share/assp/assp.cfg

#Exposing tcp ports
EXPOSE 55555
EXPOSE 225
EXPOSE 25

#Adding volumes
VOLUME ["/etc/postfix", \
        "/usr/share/assp/assp.cfg", \
		"/usr/share/assp/errors", \
		"/usr/share/assp/spam", \
		"/usr/share/assp/notspam", \
		"/usr/share/assp/certs", \
		"/etc/opendkim"]

# Running final script
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
