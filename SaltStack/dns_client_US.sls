config_dns_servers:
  win_dns_client.dns_exists:
    - interface: 'NIC' #Put name of NIC here. Default = 'Local Area Connection'
    - replace: True #remove any servers not in the "servers" list, default is False
    - servers:
      - 8.8.8.8
      - 8.8.4.4
      - 192.168.1.1

# This will change the DNS servers on the clients to the IP's listed.  
