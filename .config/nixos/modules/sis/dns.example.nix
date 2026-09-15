# Copy to dns.local.nix and replace these documentation-only values.
# Local network addresses and suffixes stay outside Git. No credentials here.
{
  servers = [
    "192.0.2.53"
    "192.0.2.54"
  ];
  domains = [
    "corp.example"
    "internal.example"
  ];
}
