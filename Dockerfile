#Creating Images for ASSP web service
FROM alpine

#RUN { \
#       echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main'; \
#       echo '@testing http:/dl-cdn.alpinelinux.org/alpine/edge/testing'; \
#    } | tee >> /etc/apk/repositories


ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk update && apk upgrade
RUN true && \
    apk add --update tzdata bash supervisor perl perl-sys-hostname-long perl-net-dns make automake gcc \
        perl-lwp-protocol-https perl-dbd-pg perl-dbd-mysql perl-dbd-sqlite perl-cgi-psgi perl-cgi perl-fcgi perl-term-readkey \
        perl-xml-rss perl-crypt-ssleay perl-crypt-eksblowfish perl-crypt-x509 perl-html-mason-psgihandler perl-fcgi-procmanager \
        perl-mime-types perl-list-moreutils perl-json perl-html-quoted perl-html-scrubber perl-email-address perl-text-password-pronounceable \
        perl-email-address-list perl-html-formattext-withlinks-andtables perl-html-rewriteattributes perl-text-wikiformat perl-text-quoted \
        perl-datetime-format-natural perl-date-extract perl-data-guid perl-data-ical perl-string-shellquote perl-convert-color perl-dbix-searchbuilder \
        perl-file-which perl-css-squish perl-tree-simple perl-plack perl-log-dispatch perl-module-versions-report perl-symbol-global-name \
        perl-devel-globaldestruction perl-parallel-prefork perl-cgi-emulate-psgi perl-text-template perl-net-cidr perl-apache-session \
        perl-locale-maketext-lexicon perl-locale-maketext-fuzzy perl-regexp-common-net-cidr perl-module-refresh perl-date-manip perl-regexp-ipv6 \
        perl-text-wrapper perl-universal-require perl-role-basic perl-convert-binhex perl-test-sharedfork perl-test-tcp perl-server-starter \
        perl-starlet perl-dev libc-dev openssl openssl-dev db-dev yaml gnupg linux-headers krb5-dev zip clamav \
        musl-dev mariadb-connector-c-dev gcc musl-obstack-dev imagemagick imagemagick-perlmagick poppler-utils tesseract-ocr rsvg-convert xpdf && \
        (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)

# Install CPAN modules
RUN cpan CPAN CPAN::DistnameInfo 
RUN cpan Text::Glob Number::Compare Compress::Zlib Convert::TNEF Digest::MD5 Digest::SHA1 Email::MIME::Modifier Email::Send \
         Email::Valid File::ReadBackwards LWP::Simple MIME::Types Mail::SPF Mail::SRS Net::CIDR::Lite Net::DNS Net::IP::Match::Regexp Net::LDAP Net::SMTP \
         Net::SenderBase Net::Syslog PerlIO::scalar threads threads::shared Thread::Queue Thread::State Tie::DBI Time::HiRes Sys::MemInfo IO::Socket::SSL \
         BerkeleyDB Crypt::CBC Crypt::OpenSSL::AES DBD::CSV DBD::File DBD::LDAP DBD::mysql::informationschema DBD::mysqlPP DBD::MariaDB DBIx::AnyDBD YAML \
         File::Find::Rule File::Slurp File::Which LEOCHARRE::DEBUG File::chmod Linux::usermod Crypt::RC4 Text::PDF Smart::Comments CAM::PDF PDF::API2 \
         Convert::Scalar
RUN cpan -T File::Scan::ClamAV Mail::DKIM::Verifier Mail::SPF::Query Schedule::Cron LEOCHARRE::CLI
# RUN cpan  Image::Magick
# RUN cpan  -T PDF::Burst
# RUN cpan   PDF::GetImages
# RUN cpan  -T Image::OCR::Tesseract
# RUN cpan   PDF::OCR
# RUN cpan   PDF::OCR2
# RUN cpan   LEOCHARRE::DEBUG

RUN rm -rf /root/.cpan/* 2>/dev/null

# Get ASSP
RUN true & \
    mkdir -p /usr/share/assp && cd /usr/share && \
    wget https://sourceforge.net/projects/assp/files/latest/download?source=files -O ASSP.zip && \
    unzip ASSP.zip && \
    cd assp && \
#    wget http://assp.cvs.sourceforge.net/viewvc/assp/assp2/filecommander/?view=tar -O assp-filecommander.tar.gz && \
    wget https://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/filecommander/1.05.ZIP && \
#    tar xzvf assp-filecommander.tar.gz && \
#    unzip filecommander/1.05.ZIP && \
    unzip 1.05.ZIP && \
    mv 1.05/images/* /usr/share/assp/images && \
    mv 1.05/lib/* /usr/share/assp/lib && \
#    wget http://assp.cvs.sourceforge.net/viewvc/assp/assp2/lib/?view=tar -O assp-lib.tar.gz && \
    wget https://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/lib/lib.zip
#   unzip lib.zip
#    tar xzvf assp-lib.tar.gz

RUN chmod +x /usr/share/assp/assp.pl
RUN mkdir -p /etc/assp && ln -s /etc/assp/assp.cfg /usr/share/assp/assp.cfg

#Exposing tcp ports
EXPOSE 55555
EXPOSE 225
EXPOSE 465
EXPOSE 25

# Configure supervisord
RUN { \
	echo '[supervisord]'; \
	echo 'nodaemon        = true'; \
	echo 'logfile         = /dev/null'; \
	echo 'logfile_maxbytes= 0'; \
	echo; \
	echo '[program:assp]'; \
	echo 'process_name    = assp'; \
	echo 'autostart       = true'; \
	echo 'autorestart     = true'; \
	echo 'directory       = /usr/share/assp'; \
	echo 'command         = /usr/share/assp/assp.pl'; \
	echo 'startsecs       = 0'; \
	} | tee /etc/supervisord.conf


#Adding volumes
VOLUME ["/usr/share/assp/assp.cfg", \
        "/usr/share/assp/errors", \
        "/usr/share/assp/spam", \
        "/usr/share/assp/files", \
        "/usr/share/assp/notspam", \
        "/usr/share/assp/certs"]

# Running final script
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
