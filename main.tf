variable "resourceGroupName" {}
variable "location" {
  default = "southcentralus"
}
variable "storageAccountPrefix" {
  default = "packerimages"
}
variable "storageAccountType" {
  default = "Standard_GRS"
}

resource "random_id" "storageaccount" {
  keepers = {
    name = "${var.storageAccountPrefix}"
  }

  byte_length = 12
}

resource "azurerm_resource_group" "packer" {
  name     = "${var.resourceGroupName}"
  location = "${var.location}"
}

resource "azurerm_storage_account" "packer" {
  name                = "${format("%.24s", lower("${var.storageAccountPrefix}${random_id.storageaccount.id}"))}"
  resource_group_name = "${azurerm_resource_group.packer.name}"

  location     = "${var.location}"
  account_type = "${var.storageAccountType}"
}

output "storage_account_name" {
  value = "${azurerm_storage_account.packer.name}"
}
