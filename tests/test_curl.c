#include <curl/curl.h>
#include <stdio.h>

static const char *feature_name(unsigned int flag) {
    switch (flag) {
    case CURL_VERSION_IPV6:         return "IPv6";
    case CURL_VERSION_KERBEROS4:    return "Kerberos4";
    case CURL_VERSION_SSL:          return "SSL";
    case CURL_VERSION_LIBZ:         return "libz";
    case CURL_VERSION_NTLM:         return "NTLM";
    case CURL_VERSION_GSSNEGOTIATE: return "GSS-Negotiate";
    case CURL_VERSION_DEBUG:        return "Debug";
    case CURL_VERSION_ASYNCHDNS:    return "AsynchDNS";
    case CURL_VERSION_SPNEGO:       return "SPNEGO";
    case CURL_VERSION_LARGEFILE:    return "Largefile";
    case CURL_VERSION_IDN:          return "IDN";
    case CURL_VERSION_SSPI:         return "SSPI";
    case CURL_VERSION_CONV:         return "Conv";
    case CURL_VERSION_CURLDEBUG:    return "CurlDebug";
    case CURL_VERSION_TLSAUTH_SRP:  return "TLS-SRP";
    case CURL_VERSION_NTLM_WB:      return "NTLM-WB";
    case CURL_VERSION_HTTP2:        return "HTTP2";
    case CURL_VERSION_GSSAPI:       return "GSSAPI";
    case CURL_VERSION_KERBEROS5:    return "Kerberos5";
    case CURL_VERSION_UNIX_SOCKETS: return "UnixSockets";
    case CURL_VERSION_PSL:          return "PSL";
    case CURL_VERSION_HTTPS_PROXY:  return "HTTPS-proxy";
    case CURL_VERSION_MULTI_SSL:    return "MultiSSL";
    case CURL_VERSION_BROTLI:       return "Brotli";
    case CURL_VERSION_ALTSVC:       return "AltSvc";
    case CURL_VERSION_HTTP3:        return "HTTP3";
    case CURL_VERSION_ZSTD:         return "Zstd";
    case CURL_VERSION_UNICODE:      return "Unicode";
    case CURL_VERSION_HSTS:         return "HSTS";
    case CURL_VERSION_GSASL:        return "GSASL";
    default:                        return "Unknown";
    }
}

int main(void) {
    curl_version_info_data *info = curl_version_info(CURLVERSION_NOW);

    printf("libcurl capabilities\n");
    printf("====================\n");
    printf("Version:       %s\n", info->version);
    printf("Version num:   0x%06x\n", info->version_num);
    printf("Host:          %s\n", info->host);

    if (info->ssl_version)
        printf("SSL backend:   %s\n", info->ssl_version);
    if (info->libz_version)
        printf("libz version:  %s\n", info->libz_version);
    if (info->ares)
        printf("c-ares:        %s\n", info->ares);
    if (info->libidn)
        printf("libidn:        %s\n", info->libidn);

    printf("\nSupported protocols:\n");
    if (info->protocols) {
        for (int i = 0; info->protocols[i]; i++)
            printf("  %s\n", info->protocols[i]);
    }

    printf("\nBuild features:\n");
    /* Print features from the bitmask */
    unsigned int known[] = {
        CURL_VERSION_IPV6,
        CURL_VERSION_SSL,
        CURL_VERSION_LIBZ,
        CURL_VERSION_ASYNCHDNS,
        CURL_VERSION_DEBUG,
        CURL_VERSION_LARGEFILE,
        CURL_VERSION_IDN,
        CURL_VERSION_SSPI,
        CURL_VERSION_CONV,
        CURL_VERSION_TLSAUTH_SRP,
        CURL_VERSION_HTTP2,
        CURL_VERSION_GSSAPI,
        CURL_VERSION_KERBEROS5,
        CURL_VERSION_UNIX_SOCKETS,
        CURL_VERSION_PSL,
        CURL_VERSION_HTTPS_PROXY,
        CURL_VERSION_MULTI_SSL,
        CURL_VERSION_BROTLI,
        CURL_VERSION_ALTSVC,
        CURL_VERSION_HTTP3,
        CURL_VERSION_ZSTD,
        CURL_VERSION_UNICODE,
        CURL_VERSION_HSTS,
        CURL_VERSION_GSASL,
        CURL_VERSION_NTLM,
        CURL_VERSION_SPNEGO,
        CURL_VERSION_NTLM_WB,
        CURL_VERSION_KERBEROS4,
        CURL_VERSION_GSSNEGOTIATE,
        CURL_VERSION_CURLDEBUG,
    };    for (size_t i = 0; i < sizeof(known)/sizeof(known[0]); i++) {
        if (info->features & known[i])
            printf("  %s\n", feature_name(known[i]));
    }

    return 0;
}
