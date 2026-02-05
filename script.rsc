#----------SCRIPT INFORMATION---------------------------------------------------
#
# Script:  Domeneshop.no Dynamic DNS Update Script (WAN DHCP)
# Created:  06/02/2026
#
#----------MODIFY THIS SECTION AS NEEDED----------------------------------------

# Base64(token:secret)
:local authBase64 "YOUR_SECRET_HERE"

# Hostname to update (FQDN)
:local hostname "YOUR_DOMAIN_HERE"

# WAN Interface
:local wanIf "ether1-WAN"

#-------------------------------------------------------------------------------

:local previousIP ""
:local currentIP ""

:log warning "START: Domeneshop DynDNS Update"

#-------------------------------------------------------------------------------
# Resolve current DNS IP
#-------------------------------------------------------------------------------

:do {
    :set previousIP [:resolve $hostname]
} on-error={
    :log warning "Domeneshop: Could not resolve $hostname (forcing update)"
    :set previousIP ""
}

#-------------------------------------------------------------------------------
# Get IP from WAN DHCP
#-------------------------------------------------------------------------------

:local dhcpId [/ip dhcp-client find interface=$wanIf]

:if ([:len $dhcpId] = 0) do={
    :log error "Domeneshop: No DHCP client found on $wanIf"
    :error "No WAN DHCP"
}

:set currentIP [/ip dhcp-client get $dhcpId address]
:set currentIP [:pick $currentIP 0 [:find $currentIP "/"]]

:if ($currentIP = "") do={
    :log error "Domeneshop: WAN IP is empty"
    :error "Invalid WAN IP"
}

:log info "Domeneshop: DNS IP ($previousIP), WAN IP ($currentIP)"

#-------------------------------------------------------------------------------
# Update Domeneshop if needed
#-------------------------------------------------------------------------------

:if ($currentIP != $previousIP) do={

    :log info "Domeneshop: IP changed, updating DNS"

    :local updateUrl \
        "https://api.domeneshop.no/v0/dyndns/update\?hostname=$hostname&myip=$currentIP"

    :local response
    :do {
        :set response ([/tool fetch \
            url=$updateUrl \
            http-header-field=("Authorization: Basic $authBase64") \
            output=user as-value]->"data")
    } on-error={
        :log error "Domeneshop: DNS update failed"
        :error "Update failed"
    }

    :log info "Domeneshop: Server response: $response"

} else={
    :log info "Domeneshop: IP unchanged, no update needed"
}

:log warning "END: Domeneshop DynDNS Update finished"
