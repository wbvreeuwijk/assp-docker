# ==========================================
# STAGE 1: Builder
# ==========================================
FROM alpine:3.20 AS builder

# Install build dependencies
RUN apk add --no-cache \
    perl perl-dev perl-app-cpanminus make automake gcc libc-dev \
    openssl-dev db-dev yaml-dev mariadb-connector-c-dev musl-obstack-dev \
    wget zip unzip \
    perl-net-ssleay perl-io-socket-ssl \
    clamav tesseract-ocr poppler-utils imagemagick

# Build and compile CPAN modules
RUN cpanm --notest --local-lib /perl-lib \
    CPAN::DistnameInfo Text::Glob Number::Compare Compress::Zlib Convert::TNEF Digest::MD5 Digest::SHA1 Email::MIME::Modifier Email::Send \
    Email::Valid File::ReadBackwards LWP::Simple MIME::Types Mail::SPF Mail::SRS Net::CIDR::Lite Net::DNS Net::IP::Match::Regexp Net::LDAP Net::SMTP \
    Net::SenderBase Net::Syslog PerlIO::scalar threads threads::shared Thread::Queue Thread::State Tie::DBI Time::HiRes Sys::MemInfo IO::Socket::SSL \
    BerkeleyDB Crypt::CBC Crypt::OpenSSL::AES DBD::CSV DBD::File DBD::LDAP DBD::MariaDB DBIx::AnyDBD YAML \
    File::Find::Rule File::Slurp File::Which https://backpan.perl.org/authors/id/L/LE/LEOCHARRE/LEOCHARRE-Debug-1.03.tar.gz File::chmod Linux::usermod Crypt::RC4 Text::PDF Smart::Comments CAM::PDF PDF::API2 \
    Convert::Scalar

RUN cpanm --notest --local-lib /perl-lib \
    File::Scan::ClamAV Mail::DKIM::Verifier Mail::SPF::Query Schedule::Cron \
    https://backpan.perl.org/authors/id/L/LE/LEOCHARRE/LEOCHARRE-CLI-1.19.tar.gz \
    PDF::Burst PDF::GetImages Image::OCR::Tesseract PDF::OCR PDF::OCR2

# ==========================================
# STAGE 2: Runtime
# ==========================================
FROM alpine:3.20

ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install only runtime dependencies (no compilers, dev libraries, etc.)
RUN apk add --no-cache \
    tzdata bash supervisor perl clamav zip unzip \
    mariadb-connector-c musl-obstack imagemagick poppler-utils \
    tesseract-ocr rsvg-convert xpdf \
    # Install runtime package-manager equivalents for system perl extensions
    perl-lwp-protocol-https perl-dbd-pg perl-dbd-mysql perl-dbd-sqlite \
    perl-cgi-psgi perl-cgi perl-fcgi perl-term-readkey perl-xml-rss \
    perl-crypt-ssleay perl-crypt-eksblowfish perl-crypt-x509 \
    perl-html-mason-psgihandler perl-fcgi-procmanager perl-mime-types \
    perl-list-moreutils perl-json perl-html-quoted perl-html-scrubber \
    perl-email-address perl-text-password-pronounceable perl-email-address-list \
    perl-html-formattext-withlinks-andtables perl-html-rewriteattributes \
    perl-text-wikiformat perl-text-quoted perl-datetime-format-natural \
    perl-date-extract perl-data-guid perl-data-ical perl-string-shellquote \
    perl-convert-color perl-dbix-searchbuilder perl-file-which perl-css-squish \
    perl-tree-simple perl-plack perl-log-dispatch perl-module-versions-report \
    perl-symbol-global-name perl-devel-globaldestruction perl-parallel-prefork \
    perl-cgi-emulate-psgi perl-text-template perl-net-cidr perl-apache-session \
    perl-locale-maketext-lexicon perl-locale-maketext-fuzzy perl-regexp-common-net-cidr \
    perl-module-refresh perl-date-manip perl-regexp-ipv6 perl-text-wrapper \
    perl-universal-require perl-role-basic perl-convert-binhex perl-test-sharedfork \
    perl-test-tcp perl-server-starter perl-starlet

# Copy compiled Perl modules from the builder stage
COPY --from=builder /perl-lib /usr/local

# Set environment variables for Perl to see the copied local-lib paths
ENV PERL5LIB=/usr/local/lib/perl5

# Get ASSP
RUN mkdir -p /usr/share/assp && cd /usr/share && \
    wget https://sourceforge.net/projects/assp/files/latest/download?source=files -O ASSP.zip && \
    unzip -o ASSP.zip && \
    cd assp && \
    wget https://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/filecommander/1.05.ZIP && \
    unzip -o 1.05.ZIP && \
    mv 1.05/images/* /usr/share/assp/images && \
    mv 1.05/lib/* /usr/share/assp/lib && \
    wget https://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/lib/lib.zip && \
    unzip -o lib.zip && \
    chmod +x /usr/share/assp/assp.pl && \
    rm -f ASSP.zip 1.05.ZIP lib.zip

RUN mkdir -p /etc/assp && ln -s /etc/assp/assp.cfg /usr/share/assp/assp.cfg

EXPOSE 55555 225 465 25

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

VOLUME ["/usr/share/assp/assp.cfg", \
    "/usr/share/assp/errors", \
    "/usr/share/assp/spam", \
    "/usr/share/assp/files", \
    "/usr/share/assp/notspam", \
    "/usr/share/assp/certs"]

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
