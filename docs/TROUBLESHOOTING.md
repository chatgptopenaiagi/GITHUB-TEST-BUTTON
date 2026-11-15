# Troubleshooting

| Result | Interpretation / next step |
|---|---|
| NETWORK_UNAVAILABLE | Check the connection, captive portal, or network policy. |
| DNS_FAILURE | The resolver could not resolve the target. Check DNS configuration. |
| TLS_FAILURE | Certificate verification or TLS negotiation failed. Do not bypass certificate verification. |
| TIMEOUT | A bounded request did not finish; check latency, firewall, or proxy policy. |
| API_UNAVAILABLE | The response or API payload could not be used. Compare the separate service-status result. |
| RATE_LIMITED | Respect response rate-limit headers and retry after the indicated interval. |
| UNAUTHENTICATED | Public access still works. Configure a supported authentication provider if private access is needed. |
| AUTHENTICATION_EXPIRED | Existing credentials were rejected; reauthenticate using the provider. |
| ACCESS_DENIED | The resource is inaccessible; a private repository may also appear as 404. |
| TOOL_NOT_INSTALLED | Install the optional tool only if its functionality is needed. Codex is not required. |
| NOT_TESTED | No execution evidence; it is neither a pass nor a failure. |

Successful read access does not establish write access. A service incident does not necessarily break your specific connection. Avoid repeatedly retrying authentication failures. See GitHub's [rate-limit guidance](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api).
