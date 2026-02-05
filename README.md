# MikroTik Domeneshop DDNS Updater

MikroTik RouterOS script to automatically update a Domeneshop DNS record using the public IP address obtained from the WAN DHCP client.

The script is designed to run on a main/edge router that receives a public IPv4 address directly on its WAN interface (no CGNAT, no external IP lookup services).

---

## Features

- Uses WAN DHCP as the single source of truth
- No external IP detection services
- Uses native RouterOS HTTP Basic Auth
- Updates DNS only when the IP changes
- Intended to run on DHCP bind / renew
- Simple and deterministic behavior

---

## Requirements

- MikroTik RouterOS v6 or v7
- Public IPv4 address assigned via DHCP on the WAN interface
- A Domeneshop account with:
  - An existing domain
  - An API token and secret

---

## 1. Create a Domeneshop API Token

1. Log in to Domeneshop
2. Go to **My account → API**
3. Create a new API token
4. Save:
   - **Token**
   - **Secret**

> ⚠️ The API token is **not** your Domeneshop login email, and the secret is **not** your account password.  
> MFA does not affect API tokens.

---

## 2. Add the Script to MikroTik

1. Open **System → Scripts**
2. Create a new script (e.g. `Domeneshop-DDNS`)
3. Paste the script contents
4. Update the following variables:

```
# Domeneshop API token
:local apiToken "YOUR_API_TOKEN"

# Domeneshop API secret
:local apiSecret "YOUR_API_SECRET"

# Hostname to update (FQDN)
:local hostname "home.example.com"

# WAN interface name
:local wanIf "ether1-WAN"
```

5. Save the script

---

## 3. Test the Script Manually

Run the script once to verify everything works:

```
/system script run Domeneshop-DDNS
```

Check **Log** for messages like:

```
Domeneshop: IP changed, updating DNS
Domeneshop: Fetch status = finished
```

> Note: Domeneshop may return an empty response body.  
> A `finished` fetch status indicates success.

---

## 4. Run Automatically on DHCP Change (Recommended)

Attach the script to the WAN DHCP client so it runs:
- At boot
- On lease renew
- When the IP changes

```
/ip dhcp-client
set [find interface=ether1-WAN] script="/system script run Domeneshop-DDNS"
```

This removes the need for a scheduler.

---

## Notes and Limitations

- IPv4 only
- Assumes the WAN interface receives a **public IP**
- Does not support CGNAT
- Does not update AAAA (IPv6) records

---

## Security Notes

- The API token grants API access — protect the script accordingly
- Avoid exporting scripts with credentials
- Regenerate the API token if the router configuration is shared

---

## Credits

Inspired by the original DuckDNS MikroTik script by Alexander Tebiev (beeyev), adapted for Domeneshop and WAN DHCP–based operation.

---

## License

MIT
