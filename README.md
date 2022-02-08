# tchallenge
Requirements for the Terraform Script:

- Creates a Resource Group
- Creates a Virtual Network and Subnet
- Attaches a Network Security Group to the Subnet
- Creates a Key Vault
- Creates a Storage Account and Container
- Tags all resources with the key "Owner" and value = <your name>
- Storage Account should be locked down so it is only accessible on the above VNET and your IP.
- Key Vault should be locked down so it is only accessible on the above VNET and your IP.
- Once you deploy the Infrastructure, move the Terraform state file to the above Storage Account.

  We're looking forward to seeing your solution! Please let us know if you have any questions.

Good luck!
