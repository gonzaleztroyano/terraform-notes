# Inicio de sesión y creación de un ResourceGroup en Azure

## Configuración inicial

Si estamos trabajando con Cloud Shell de Azure no es necesario instalar nada, pues las herramientas de gestión del clouder ya están instaladas. Si estuviéramos trabajando con un equipo físico basta con ejecutar lo siguiente en PoweShell:

```PowerShell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
```

Depués, iniciar la sesión (tampoco necesario en Cloud Shell):
```PowerShell
az login
```

En Cloud Shell, basta con ejecutar el siguiente comando para ver la información sobre nuestras suscripciones:
```PowerShell
az account show
```
Una vez conseguido el ID de nuestra suscripción:
```PowerShell
az account set --subscription "$ID_SUSCRIPCION"
```

## Creación de un _Service Principal_

_Next, create a Service Principal. A Service Principal is an application within Azure Active Directory with the authentication tokens Terraform needs to perform actions on your behalf. Update the <SUBSCRIPTION_ID> with the subscription ID you specified in the previous step._

```PowerShell
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"
```

Terraform recomienda guardar la siguiente información en variables de sesión para que sea más sencillo el proceso:

```PowerShell
$Env:ARM_CLIENT_ID = "<APPID_VALUE>"
$Env:ARM_CLIENT_SECRET = "<PASSWORD_VALUE>"
$Env:ARM_SUBSCRIPTION_ID = "<SUBSCRIPTION_ID>"
$Env:ARM_TENANT_ID = "<TENANT_VALUE>"
```

## Declaración de TF

Creemos un nuevo directorio:
```PowerShell
New-Item -Name "learn-terraform-azure" -ItemType "directory"
```

Aquí crearemos un archivo nuevo llamado "main.tf" (por convenio) y añadiremos el siguiente texto. Es posible que tengamos que cambiar la zona.

```
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "RG-Terraform"
  location = "westeurope"
}

```

### Bloque Terraform
_The `terraform {}` block contains Terraform settings, including the required providers Terraform will use to provision your infrastructure. For each provider, the `source` attribute defines an optional hostname, a namespace, and the provider type. Terraform installs providers from the Terraform Registry by default. In this example configuration, the `azurerm` provider's source is defined as `hashicorp/azurerm`, which is shorthand for registry.terraform.io/hashicorp/azurerm._

_You can also define a version constraint for each provider in the `required_providers` block. The version attribute is optional, but we recommend using it to enforce the provider version. Without it, Terraform will always use the latest version of the provider, which may introduce breaking changes._

### Bloque Providers

_The `provider` block configures the specified provider, in this case `azurerm`. A provider is a plugin that Terraform uses to create and manage your resources. You can define multiple provider blocks in a Terraform configuration to manage resources from different providers._

### Bloque Resources

_Use resource blocks to define components of your infrastructure. A resource might be a physical component such as a server, or it can be a logical resource such as a Heroku application._

_Resource blocks have two strings before the block: the resource type and the resource name. In this example, the resource type is `azurerm_resource_group` and the name is rg. The prefix of the type maps to the name of the provider. In the example configuration, Terraform manages the `azurerm_resource_group` resource with the azurerm provider. Together, the resource type and resource name form a unique ID for the resource. For example, the ID for your network is `azurerm_resource_group.rg`._

_Resource blocks contain arguments which you use to configure the resource. The Azure provider documentation documents supported resources and their configuration options, including `azurerm_resource_group` and its supported arguments._


## Aplicación de IaC

```PowerShell
terraform init
```

Con el siguiente comando, Terraform formateará correctamente el código para estandarizarlo y facilitar la legibilidad. También comprobaremos la validez de las expresiones
```PowerShell
terraform fmt
terraform validate
```

Aplicamos los cambios:
```PowerShell
terraform apply
```

La salida del comando es:

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_resource_group.rg will be created
  + resource "azurerm_resource_group" "rg" {
      + id       = (known after apply)
      + location = "westeurope"
      + name     = "RG-Terraform"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Creation complete after 1s [id=/subscriptions/5dd87b30-e0b5-49b1-aaf4-dfb441917e37/resourceGroups/RG-Terraform]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## Revisión de resultados

Para ver el resultado de los archivos de IaC aplicados, podemos usar el siguiente comando:
```PowerShell
terraform show
```

El resultado será similar al siguiente:
```
# azurerm_resource_group.rg:
resource "azurerm_resource_group" "rg" {
    id       = "/subscriptions/5dd87b30-e0b5-49b1-aaf4-dfb441917e37/resourceGroups/RG-Terraform"
    location = "westeurope"
    name     = "RG-Terraform"
}
```


REFERENCES:
https://learn.hashicorp.com/tutorials/terraform/azure-build?in=terraform/azure-get-started 