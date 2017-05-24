# Creating Packer Images in Azure with Terraform
The repository demonstrates simple usage of Terraform to configure an Azure infrastructure to store and use Packer images, and Packer templates to generate images to store in the Storage Account created in Azure.

## Getting Started
You will need an Azure Service Principal Account. See [Authorizing Packer Builds in Azure](https://www.packer.io/docs/builders/azure-setup.html).

### Variables used by Terraform
| Variable                |Required| Default | Description |
|-------------------------|--------|---------|-------------|
| `azure_client_id`       | Yes    |         | Azure Client ID, Azure portal shows this as the *Application ID*.                 |
| `azure_client_secret`   | Yes    |         | Service principal secret / password. Found in _Keys_ from the Settings menu.      |
| `azure_subscription_id` | Yes    |         | UUID identifying your Azure subscription.                                         |
| `azure_tenant_id`       | Yes    |         | Tenant ID found in the application configure parameters, authorization endpoint ID|
| `azure_object_id`       | Yes    |         | Specify an OAuth Object ID to protect WinRM certificates created at runtime.      |
| `resourceGroupName`     | Yes    |         | name of the resource group where your VHD(s) will be stored.                      |
| `location`              | No     | `southcentralus` | Primary location for the resource group and storage account.             |
| `storageAccountPrefix`  | No     | `packerimages`   | Prefix used for the storage account name where your VHDs will be stored. |
| `storageAccountType`    | No     | `Standard_GRS`   | `Standard_LRS``Standard_GRS``Standard_RAGRS``Standard_ZRS``Premium_LRS`  |

These variables are expected to be defined as environment variables, which are prefixed with `TF_VAR_`. If using with Jenkins, these can be defined as parameters and the azure connection information (first 4 variables above) defined as password parameters to mask them.
See Notes (below) for obtaining the subscription and tenant IDs through the Azure CLI

### Variables used by Packer
| Variable                |Required | Default / Source                        |
|-------------------------|---------|-----------------------------------------|
| `azure_subscription_id` | Yes     | env var: `TF_VAR_azure_subscription_id` |
| `azure_client_id`       | Yes     | env var: `TF_VAR_azure_client_id`       |
| `azure_client_secret`   | Yes     | env var: `TF_VAR_azure_client_secret`   |
| `azure_object_id`       | Yes     | env var: `azure_object_id`              |
| `resource_group_name`   | Yes     | env var: `TF_VAR_resourceGroupName`     |
| `location`              | Yes     | env var: `TF_VAR_location`              |
| `storage_account`       | Yes     | env var: `storageAccountName`           |
| `container_name`        | No      | `packer-images`                         |
| `capture_name_prefix`   | No      | `packer`                                |
| `vm_size`               | No      | `Standard_DS1_V2`                       |
| `image_publisher`       | No      | `MicrosoftWindowsServer`                |
| `image_offer`           | No      | `WindowsServer`                         |
| `image_sku`             | No      | `2016-Datacenter`                       |
| `winrm_username`        | No      | `Administrator`                         |

## Step 1: Set Parameters for Terraform and Packer

```shell
# Mask these first 5 parameters...
export TF_VAR_azure_client_id=.....
export TF_VAR_azure_client_secret=.....
export TF_VAR_azure_subscription_id=.....
export TF_VAR_azure_tenant_id=.....
export azure_object_id=.....

export TF_VAR_resourceGroupName="packerimages"
export TF_VAR_location="westus"
export TF_VAR_storageAccountPrefix="images"
export captureContainerName="custom-images"
```

## Step 2: Run Terraform

Validate and apply terraform plan.

```shell
terraform plan

terraform apply
```

## Step 3: Run Packer

Validate packer template and apply using storage account name from Terraform tfstate:

### Option 1: Packer Variables from Environment
Packer will take variables assigned previously as environment variables.

```shell
packer validate -var storage_account=$(terraform output storage_account_name) packer_windows.json

packer build -var storage_account=$(terraform output storage_account_name) packer_windows.json
```

Variables can be overwritten with `-var 'key=value'` arguments.

### Option 2: Variable File
Variables for Packer can also be set from an external JSON file. The -var-file flag reads a file containing a basic key/value mapping of variables to values and sets those variables. The JSON file is simple:

```json
{
  "azure_subscription_id":  "xxxxx-xxxxx-xxxxxx-xxxxxx",
  "azure_client_id":        "xxxxx-xxxxx-xxxxxx-xxxxxx",
  "azure_client_secret":    "xxxxx-xxxxx-xxxxxx-xxxxxx",
  "azure_object_id":        "xxxxx-xxxxx-xxxxxx-xxxxxx",
  "azure_tenant_id":        "xxxxx-xxxxx-xxxxxx-xxxxxx",

  "resource_group_name":    "MyResourceGroup",
  "location":               "westus",
  "container_name":         "packer-images",
  "capture_name_prefix":    "packer",

  "vm_size":                "Standard_DS1_V2",
  "image_publisher":        "MicrosoftWindowsServer",
  "image_offer":            "WindowsServer",
  "image_sku":              "2016-Datacenter",

  "winrm_username":         "Administrator"
}
```
It is a single JSON object where the keys are variables and the values are the variable values. Assuming this file is in variables.json, we can build our template using the following command:

```shell
packer validate\
  -var-file=variables.json\
  -var storage_account=$(terraform output storage_account_name)\
  packer_windows.json

packer build\
  -var-file=variables.json\
  -var storage_account=$(terraform output storage_account_name)\
  packer_windows.json
```

## Notes:
The Subscription ID, Object ID, and Tenant ID can be obtained by using the azure cli. Ensure you're logged in by using `azure login` and following instructions.

```shell
$ azure account show
info:    Executing command account show
data:    Name                        : <Your Subscription Name>
data:    ID                          : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
data:    State                       : Enabled
data:    Tenant ID                   : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
data:    Is Default                  : true
data:    Environment                 : AzureCloud
data:    Has Certificate             : Yes
data:    Has Access Token            : Yes
data:    User name                   : myemail@domain.com
data:
info:    account show command OK
```

To obtain the `object_id` required by Packer:

```shell
$ azure ad sp show -n CLIENT_ID
```
