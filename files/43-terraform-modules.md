# What are modules for?

Here are some of the ways that modules help solve the problems listed above:

-   **Organize configuration:** Modules make it easier to navigate, understand, and update your configuration by keeping related parts of your configuration together. Even moderately complex infrastructure can require hundreds or thousands of lines of configuration to implement. By using modules, you can organize your configuration into logical components.
    
-   **Encapsulate configuration:** Another benefit of using modules is to encapsulate configuration into distinct logical components. Encapsulation can help prevent unintended consequences—such as a change to one part of your configuration accidentally causing changes to other infrastructure—and reduce the chances of simple errors like using the same name for two different resources.
    
-   **Re-use configuration:** Writing all of your configuration without using existing code can be time-consuming and error-prone. Using modules can save time and reduce costly errors by re-using configuration written either by yourself, other members of your team, or other Terraform practitioners who have published modules for you to use. You can also share modules that you have written with your team or the general public, giving them the benefit of your hard work.
    
-   **Provide consistency and ensure best practices:** Modules also help to provide consistency in your configurations. Consistency makes complex configurations easier to understand, and it also helps to ensure that best practices are applied across all of your configuration. For example, cloud providers offer many options for configuring object storage services, such as Amazon S3 (Simple Storage Service) or Google's Cloud Storage buckets. Many high-profile security incidents have involved incorrectly secured object storage, and because of the number of complex configuration options involved, it's easy to accidentally misconfigure these services.
    

Using modules can help reduce these errors. For example, you might create a module to describe how all of your organization's public website buckets will be configured, and another module for private buckets used for logging applications. Also, if a configuration for a type of resource needs to be updated, using modules allows you to make that update in a single place and have it be applied to all cases where you use that module.

# What is a Terraform module?
A Terraform module is a set of Terraform configuration files in a single directory. Even a simple configuration consisting of a single directory with one or more `.tf` files is a module. When you run Terraform commands directly from such a directory, it is considered the **root module**. So in this sense, every Terraform configuration is part of a module. You may have a simple set of Terraform configuration files like this:
```bash
$ tree minimal-module/
.
├── LICENSE
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
```
## Calling modules

Terraform commands will only directly use the configuration files in one directory, which is usually the current working directory. However, your configuration can use module blocks to call modules in other directories. When Terraform encounters a module block, it loads and processes that module's configuration files.

A module that is called by another configuration is sometimes referred to as a "child module" of that configuration.
## Local and remote modules
Modules can be loaded from either the local filesystem or a remote source. Terraform supports a variety of remote sources, including the Terraform Registry, most version control systems, HTTP URLs, and Terraform Cloud or Terraform Enterprise private module registries.

## Module best practices
In many ways, Terraform modules are similar to the concepts of libraries, packages, or modules found in most programming languages, and they provide many of the same benefits. Just like almost any non-trivial computer program, real-world Terraform configurations should almost always use modules to provide the benefits mentioned above.

It is recommended that every Terraform practitioner use modules by following these best practices:

-   Start writing your configuration with a plan for modules. Even for slightly complex Terraform configurations managed by a single person, the benefits of using modules outweigh the time it takes to use them properly.
-   Use local modules to organize and encapsulate your code. Even if you aren't using or publishing remote modules, organizing your configuration in terms of modules from the beginning will significantly reduce the burden of maintaining and updating your configuration as your infrastructure grows in complexity.
-   Use the public [Terraform Registry](https://registry.terraform.io/) to find useful modules. This way you can quickly and confidently implement your configuration by relying on the work of others.
-   Publish and share modules with your team. Most infrastructure is managed by a team of people, and modules are an important tool that teams can use to create and maintain infrastructure. As mentioned earlier, you can publish modules either publicly or privately. You will see how to do this in a later lab in this series.

# Task1 - Use modules from Registry
In this section, you use modules from the [Terraform Registry](https://registry.terraform.io/) to provision an example environment in Google Cloud. The concepts you use here will apply to any modules from any source.

-   Open the [Terraform Registry page](https://registry.terraform.io/modules/terraform-google-modules/network/google/3.3.0) for the Terraform Network module in a new browser tab or window. 

The page includes information about the module and a link to the source repository. The right side of the page includes a dropdown interface to select the module version and instructions for using the module to provision infrastructure.

When you call a module, the `source` argument is required. In this example, Terraform will search for a module in the Terraform registry that matches the given string. You could also use a URL or local file path for the source of your modules. See the [Terraform documentation](https://www.terraform.io/docs/modules/sources.html) for a list of possible module sources.

The other argument shown here is the `version`. For supported sources, the version will let you define what version or versions of the module will be loaded. In this lab, you will specify an exact version number for the modules you use. You can read about more ways to specify versions in the [module documentation](https://www.terraform.io/docs/configuration/modules.html#module-versions).
##  Create a Terraform configuration
To start, run the following commands in Cloud Shell to clone the example simple project from the Google Terraform modules GitHub repository and switch to the `v3.3.0` branch.
```bash
git clone https://github.com/terraform-google-modules/terraform-google-network
cd terraform-google-network
git checkout tags/v3.3.0 -b v3.3.0
```


### Set values for module input variables
ome input variables are _required_, which means that the module doesn't provide a default value; an explicit value must be provided in order for Terraform to run correctly.

1.  Within the module `"test-vpc-module"` block, review the input variables you are setting. Each of these input variables is documented in the [Terraform registry](https://registry.terraform.io/modules/terraform-google-modules/network/google/3.3.0?tab=inputs). The required inputs for this module are:

-   `network_name`: The name of the network being created
-   `project_id`: The ID of the project where this VPC will be created
-   `subnets`: The list of subnets being created

In order to use most modules, you will need to pass input variables to the module configuration. The configuration that calls a module is responsible for setting its input values, which are passed as arguments to the module block. Aside from `source` and `version`, most of the arguments to a module block will set variable values.

On the Terraform registry page for the Google Cloud network module, an Inputs tab describes all of the [input variables](https://registry.terraform.io/modules/terraform-google-modules/network/google/3.3.0?tab=inputs) that module supports.


### Define root input variables
Using input variables with modules is very similar to how you use variables in any Terraform configuration. A common pattern is to identify which module input variables you might want to change in the future, and then create matching variables in your configuration's `variables.tf` file with sensible default values. Those variables can then be passed to the module block as arguments.

En el archivo [[#variables tf]] configuramos las variables:
```hcl
variable "project_id" {
  description = "The project ID to host the network in"
  default     = "FILL IN YOUR PROJECT ID HERE"
}
```


### Define root output values
Modules also have output values, which are defined within the module with the `output` keyword. You can access them by referring to `module.<MODULE NAME>.<OUTPUT NAME>`. Like input variables, module outputs are listed under the `outputs` tab in the [Terraform registry](https://registry.terraform.io/modules/terraform-google-modules/network/google/3.3.0?tab=inputs).

Module outputs are usually either passed to other parts of your configuration or defined as outputs in your root module. You will see both uses in this lab.

## Provisión de infrastructura
Iniciamos la configuración de terraform:
```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply
```

### Understand how modules work
When using a new module for the first time, you must run either `terraform init` or `terraform get` to install the module. When either of these commands is run, Terraform will install any new modules in the `.terraform/modules` directory within your configuration's working directory. For local modules, Terraform will create a symlink to the module's directory. Because of this, any changes to local modules will be effective immediately, without your having to re-run `terraform get`.

## Archivos finales
### main.tf
El archivo main.tf contiene:
```hcl
provider "google" {
  version = "~> 3.45.0"
}
provider "null" {
  version = "~> 2.1"
}
module "test-vpc-module" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 3.2.0"
  project_id   = var.project_id
  network_name = "my-custom-mode-network"
  mtu          = 1460
  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = "us-west1"
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = "us-west1"
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    },
    {
      subnet_name               = "subnet-03"
      subnet_ip                 = "10.10.30.0/24"
      subnet_region             = "us-west1"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    }
  ]
}
```

### output.tf
```hcl
output "network_name" {
  value       = module.test-vpc-module.network_name
  description = "The name of the VPC being created"
}

output "network_self_link" {
  value       = module.test-vpc-module.network_self_link
  description = "The URI of the VPC being created"
}

output "project_id" {
  value       = module.test-vpc-module.project_id
  description = "VPC project id"
} 

output "subnets_names" {
  value       = module.test-vpc-module.subnets_names
  description = "The names of the subnets being created"
}

output "subnets_ips" {
  value       = module.test-vpc-module.subnets_ips
  description = "The IP and cidrs of the subnets being created"
}

output "subnets_regions" {
  value       = module.test-vpc-module.subnets_regions
  description = "The region where subnets will be created"
}

output "subnets_private_access" {
  value       = module.test-vpc-module.subnets_private_access
  description = "Whether the subnets will have access to Google API's without a public IP"
}

output "subnets_flow_logs" {
  value       = module.test-vpc-module.subnets_flow_logs
  description = "Whether the subnets will have VPC flow logs enabled"
}

output "subnets_secondary_ranges" {
  value       = module.test-vpc-module.subnets_secondary_ranges
  description = "The secondary ranges associated with these subnets"
}

output "route_names" {
  value       = module.test-vpc-module.route_names
  description = "The routes associated with this VPC"
}
```

### variables.tf
```hcl
variable "project_id" {
  description = "The project ID to host the network in"
  default = "qwiklabs-gcp-01-cce205234c42"
}

variable "network_name" {
  description = "The name of the VPC network being created"
  default = "example-vpc"
}
```

### versions.tf
```hcl
terraform {
  required_version = ">=0.12.6"
}
```

# Task2 - Build a module
## Module structure
Terraform treats any local directory referenced in the `source` argument of a `module` block as a module. A typical file structure for a new module is:
```plain
$ tree minimal-module/
.
├── LICENSE
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
```

> [!INFO]
> None of these files are required or has any special meaning to Terraform when it uses your module. You can create a module with a single `.tf` file or use any other file structure you like.

Each of these files serves a purpose:
-   `LICENSE` contains the license under which your module will be distributed. When you share your module, the LICENSE file will let people using it know the terms under which it has been made available. Terraform itself does not use this file.
-   `README.md` contains documentation in markdown format that describes how to use your module. Terraform does not use this file, but services like the Terraform Registry and GitHub will display the contents of this file to visitors to your module's Terraform Registry or GitHub page.
-   `main.tf` contains the main set of configurations for your module. You can also create other configuration files and organize them in a way that makes sense for your project.
-   `variables.tf` contains the variable definitions for your module. When your module is used by others, the variables will be configured as arguments in the module block. Because all Terraform values must be defined, any variables that don't have a default value will become required arguments. A variable with a default value can also be provided as a module argument, thus overriding the default value.
-   `outputs.tf` contains the output definitions for your module. Module outputs are made available to the configuration using the module, so they are often used to pass information about the parts of your infrastructure defined by the module to other parts of your configuration.

Be aware of these files and ensure that you don't distribute them as part of your module:
-   `terraform.tfstate` and `terraform.tfstate.backup` files contain your Terraform state and are how Terraform keeps track of the relationship between your configuration and the infrastructure provisioned by it.
-   The `.terraform` directory contains the modules and plugins used to provision your infrastructure. These files are specific to an individual instance of Terraform when provisioning infrastructure, not the configuration of the infrastructure defined in `.tf` files.
-   `*.tfvars`files don't need to be distributed with your module unless you are also using it as a standalone Terraform configuration because module input variables are set via arguments to the module block in your configuration.

> [!WARNING]
> If you are tracking changes to your module in a version control system such as Git, you will want to configure your version control system to ignore these files. For an example, see this [.gitignore file](https://github.com/github/gitignore/blob/master/Terraform.gitignore) from GitHub.

## Create a module
Creamos una carpeta ad-hoc dentro del subdirectorio "modules":
```bash
mkdir -p modules/gcs-static-website-bucket
```

Aquí, creamos los siguientes archivos:
```bash
touch modules/gcs-static-website-bucket/website.tf
touch modules/gcs-static-website-bucket/variables.tf
touch modules/gcs-static-website-bucket/outputs.tf
touch modules/gcs-static-website-bucket/README.md
touch modules/gcs-static-website-bucket/LICENSE
```

Ver el contenido en la sección [[#Contenido de los archivos de módulo]].

A su vez, creamos el archivo `main.tf` en el directorio principal, con el siguiente contenido:
```hcl
module "gcs-static-website-bucket" {
  source = "./modules/gcs-static-website-bucket"
  name       = var.name
  project_id = var.project_id
  location   = "us-east1"
  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age        = 365
      with_state = "ANY"
    }
  }]
}
```

También un archivo llamado `outputs.tf`:
```hcl
output "bucket-name" {
  description = "Bucket names."
  value       = "module.gcs-static-website-bucket.bucket"
}
```

Y un archivo de `variables.tf`:
```hcl
variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
  default     = "qwiklabs-gcp-01-cce205XXXc42"
}
variable "name" {
  description = "Name of the buckets to create."
  type        = string
  default     = "qwiklabs-gcp-01-cce205XXXc42"
}
```

## Install local module & apply
```bash
terraform fmt    # Formatea correctamente archivos
terraform init   # Inicializa módulos, locales y remotos
terraform plan   # Ver cambios que serán aplicados
terraform apply  # Aplicar cambios
```

## Contenido de los archivos de módulo
### website.tf
```hcl
resource "google_storage_bucket" "bucket" {
  name               = var.name
  project            = var.project_id
  location           = var.location
  storage_class      = var.storage_class
  labels             = var.labels
  force_destroy      = var.force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = var.versioning
  }
  dynamic "retention_policy" {
    for_each = var.retention_policy == null ? [] : [var.retention_policy]
    content {
      is_locked        = var.retention_policy.is_locked
      retention_period = var.retention_policy.retention_period
    }
  }
  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      default_kms_key_name = var.encryption.default_kms_key_name
    }
  }
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
  }
}
```
### variables.tf
```hcl
variable "name" {
  description = "The name of the bucket."
  type        = string
}
variable "project_id" {
  description = "The ID of the project to create the bucket in."
  type        = string
}
variable "location" {
  description = "The location of the bucket."
  type        = string
}
variable "storage_class" {
  description = "The Storage Class of the new bucket."
  type        = string
  default     = null
}
variable "labels" {
  description = "A set of key/value label pairs to assign to the bucket."
  type        = map(string)
  default     = null
}
variable "bucket_policy_only" {
  description = "Enables Bucket Policy Only access to a bucket."
  type        = bool
  default     = true
}
variable "versioning" {
  description = "While set to true, versioning is fully enabled for this bucket."
  type        = bool
  default     = true
}
variable "force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
  type        = bool
  default     = true
}
variable "iam_members" {
  description = "The list of IAM members to grant permissions on the bucket."
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}
variable "retention_policy" {
  description = "Configuration of the bucket's data retention policy for how long objects in the bucket should be retained."
  type = object({
    is_locked        = bool
    retention_period = number
  })
  default = null
}
variable "encryption" {
  description = "A Cloud KMS key that will be used to encrypt objects inserted into this bucket"
  type = object({
    default_kms_key_name = string
  })
  default = null
}
variable "lifecycle_rules" {
  description = "The bucket's Lifecycle Rules configuration."
  type = list(object({
    # Object with keys:
    # - type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.
    # - storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.
    action = any
    # Object with keys:
    # - age - (Optional) Minimum age of an object in days to satisfy this condition.
    # - created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.
    # - with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".
    # - matches_storage_class - (Optional) Storage Class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, STANDARD, DURABLE_REDUCED_AVAILABILITY.
    # - num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.
    condition = any
  }))
  default = []
}
```
### `outputs.tf`
```hcl
output "bucket" {
  description = "The created storage bucket"
  value       = google_storage_bucket.bucket
}
```
### README.md
```plain
# GCS static website bucket
This module provisions Cloud Storage buckets configured for static website hosting.
```

### LICENSE
```plain
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```