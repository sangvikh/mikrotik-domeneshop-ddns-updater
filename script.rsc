#----------SCRIPT INFORMATION---------------------------------------------------
#
# Script:  Domeneshop.no Dynamic DNS Update Script (WAN DHCP)
# Created:  06/02/2026
#
#----------MODIFY THIS SECTION AS NEEDED----------------------------------------

# Domeneshop API token
:local apiToken "YOUR_API_TOKEN"

# Domeneshop API secret
:local apiSecret "YOUR_API_SECRET"

# Hostname to update (FQDN)
:local hostname "YOUR_DOMAIN_HERE"

# WAN Interface
:local wanIf "ether1-WAN"

#-------------------------------------------------------------------------------
# Resolve current DNS IP
#-------------------------------------------------------------------------------

:log warning "START: Domeneshop DynDNS Update"

:local waitCount 0
:local previousIP ""

:while ($waitCount < 15) do={
    :do {
        :set previousIP [:resolve $hostname]
        :log info "Domeneshop: DNS is ready ($previousIP)"
        :set waitCount 255
    } on-error={
        :delay 1
        :set waitCount ($waitCount + 1)
    }
}

:if ($previousIP = "") do={
    :log warning "Domeneshop: DNS not ready after 15s, forcing update"
}

#-------------------------------------------------------------------------------
# Get IP from WAN DHCP
#-------------------------------------------------------------------------------

:local dhcpId [/ip dhcp-client find interface=$wanIf]
:local currentIP ""

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

    :log info "Domeneshop: Updating $hostname ($previousIP -> $currentIP)"

    :local updateUrl \
        "https://api.domeneshop.no/v0/dyndns/update\?hostname=$hostname&myip=$currentIP"

    :local fetchResult
    :local response
    :local status

    :do {
        :set fetchResult [/tool fetch \
            url=$updateUrl \
            user=$apiToken \
            password=$apiSecret \
            output=user as-value]

        :set status ($fetchResult->"status")
        :set response ($fetchResult->"data")
    } on-error={
        :log error "Domeneshop: /tool fetch failed (transport or TLS error)"
        :log error "Domeneshop: URL = $updateUrl"
        :error "Update failed"
    }

    :log info "Domeneshop: Update result for $hostname: status=$status"
    :log info "Domeneshop: Response for $hostname: $response"

    :if ($status != "finished") do={
        :log error "Domeneshop: HTTP request did not complete successfully"
        :error "Update failed"
    }

} else={
    :log info "Domeneshop: $hostname unchanged ($currentIP)"
}

:log warning "END: Domeneshop DynDNS Update finished"
