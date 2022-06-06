# Terraform Workflow
A simple workflow for deployment will follow closely to the steps below:

-   **Scope** - Confirm what resources need to be created for a given project.
-   **Author** - Create the configuration file in HCL based on the scoped parameters.
-   **Initialize** - Run `terraform init` in the project directory with the configuration files. This will download the correct provider plug-ins for the project.
-   **Plan & Apply** - Run `terraform plan` to verify creation process and then `terraform apply` to create real resources as well as the state file that compares future changes in your configuration files to what actually exists in your deployment environment.

# Crear infrastructura
En el archivo ``main.tf`` escribimos:
```hcl
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  version = "3.5.0"
  project = "<PROJECT_ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```

## Terraform block
The `terraform {}` block is required so Terraform knows which provider to download from the [Terraform Registry](https://registry.terraform.io/). In the configuration above, the `google` provider's source is defined as `hashicorp/google` which is shorthand for `registry.terraform.io/hashicorp/google`.

You can also assign a version to each provider defined in the `required_providers` block. The `version` argument is optional, but recommended. It is used to constrain the provider to a specific version or a range of versions in order to prevent downloading a new provider that may possibly contain breaking changes. If the version isn't specified, Terraform will automatically download the most recent provider during initialization.

To learn more, reference the [provider source documentation](https://www.terraform.io/docs/configuration/provider-requirements.html).

## Providers
The `provider` block is used to configure the named provider, in this case `google`. A provider is responsible for creating and managing resources. Multiple provider blocks can exist if a Terraform configuration manages resources from different providers.

# Primera aplicación
```bash
terraform init
```

```bash
terraform apply
```

The output has a `+` next to resource `"google_compute_network" "vpc_network"`, meaning that Terraform will create this resource. Beneath that, it shows the attributes that will be set. When the value displayed is `(known after apply)`, it means that the value won't be known until the resource is created.

# Cambio en la infra
Creamos el archivo `instance.tf`. Copiamos el siguiente contenido. Nótese que también podríamos hacer editado el archivo `main.tf`.
```hcl
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
```

Ejecutamos:
```bash
terraform plan
```

```bash
terraform apply
```

# Cambio en la infra 2
Editamos `instance.tf` para añadir el siguiente contenido:
```hcl
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["web", "dev"]
  # ...
}
```

# Cambios destructivos
A destructive change is a change that requires the provider to replace the existing resource rather than updating it. This usually happens because the cloud provider doesn't support updating the resource in the way described by your configuration.
Changing the disk image of your instance is one example of a destructive change.

Editamos el archivo instance.tf para que contenga:
```hcl
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
```

Veremos en la consola:
```plain
google_compute_instance.vm_instance: Destroying... [id=projects/qwiklabs-gcp-04-a20a5a34b7bc/zones/us-central1-c/instances/terraform-instance]
google_compute_instance.vm_instance: Still destroying... [id=projects/qwiklabs-gcp-04-a20a5a34b7bc/z...entral1-c/instances/terraform-instance, 10s elapsed]
google_compute_instance.vm_instance: Destruction complete after 17s
google_compute_instance.vm_instance: Creating...
google_compute_instance.vm_instance: Creation complete after 10s [id=projects/qwiklabs-gcp-04-a20a5a34b7bc/zones/us-central1-c/instances/terraform-instance]
```

# Destroy infra
```
terraform destroy
```

# Crear dependencia entre recursos
Volvemos a crear la infra:
```
terraform apply
```

Ahora editamos el archivo de la instancia, `ìnstance.tf` para añadirle una IP estática:
```hcl
resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}
```

También la sección `network_interface` del recurso "google_compute_instance":
``` hcl
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  tags         = ["web", "dev"]
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}

```

The `access_config` block has several optional arguments, and in this case you'll set `nat_ip` to be the static IP address. When Terraform reads this configuration, it will:
-   Ensure that `vm_static_ip` is created before `vm_instance`
-   Save the properties of `vm_static_ip` in the state
-   Set `nat_ip` to the value of the `vm_static_ip.address` property

## plan -out
Ejecutamos como lo haríamos siempre, pero con la opción *-out* para asegurarnos que se en la aplicación se aplica lo que hemos visto durante la planificación. 
```bash
terraform plan -out static_ip
```

# Implicit and Explicit Dependencies
By studying the resource attributes used in interpolation expressions, Terraform can automatically infer when one resource depends on another. In the example above, the reference to `google_compute_address.vm_static_ip.address` creates an _implicit dependency_ on the `google_compute_address` named `vm_static_ip`.

Terraform uses this dependency information to determine the correct order in which to create and update different resources. In the example above, Terraform knows that the `vm_static_ip` must be created before the `vm_instance` is updated to use it.

Implicit dependencies via interpolation expressions are the primary way to inform Terraform about these relationships, and should be used whenever possible.

Sometimes there are dependencies between resources that are _not_ visible to Terraform. The `depends_on` argument can be added to any resource and accepts a list of resources to create explicit dependencies for.

For example, perhaps an application you will run on your instance expects to use a specific Cloud Storage bucket, but that dependency is configured inside the application code and thus not visible to Terraform. In that case, you can use `depends_on` to explicitly declare the dependency.

Creamos el archivo `instance-2.tf` :
```hcl
# New resource for the storage bucket our application will use.
resource "google_storage_bucket" "example_bucket" {
  name     = "qwiklabs-gcp-04-a20a5a34b7bc"
  location = "US"
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}
# Create a new instance that uses the bucket
resource "google_compute_instance" "another_instance" {
  # Tells Terraform that this VM instance must be created only after the
  # storage bucket has been created.
  depends_on = [google_storage_bucket.example_bucket]
  name         = "terraform-instance-2"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}
```

# Provision Infrastructure
The compute instance you launched at this point is based on the Google image given, but has no additional software installed or configuration applied.

Google Cloud allows customers to manage their own [custom operating system images](https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images). This can be a great way to ensure the instances you provision with Terraform are pre-configured based on your needs. [Packer](https://www.packer.io/) is the perfect tool for this and includes a [builder for Google Cloud](https://www.packer.io/docs/builders/googlecompute.html).

Terraform uses provisioners to upload files, run shell scripts, or install and trigger other software like configuration management tools.

To define a provisioner, modify the resource block defining the first `vm_instance` in your configuration to look like the following:
```hcl
resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  tags         = ["web", "dev"]
  machine_type = "f1-micro"
  provisioner "local-exec" {
    command = "echo ${google_compute_instance.vm_instance.name}:  ${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
  }
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}
```

Con `terraform apply` no detectará cambios. Esto es debido a que _Terraform treats provisioners differently from other arguments. Provisioners only run when a resource is created, but adding a provisioner does not force that resource to be destroyed and recreated._

Para que terraform lo considere como "fallido/erróneo/manchado" usamos:

```bash
terraform taint google_compute_instance.vm_instance
```

Por último aplicamos los cambios:
```bash
terraform apply
```

En este momento terraform recreará el recurso marcado con *taint* y veremos el contenido de *ip_address.txt*