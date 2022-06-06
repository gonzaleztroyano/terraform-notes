# Overview
Terraform must store state about your managed infrastructure and configuration. This state is used by Terraform to map real-world resources to your configuration, keep track of metadata, and improve performance for large infrastructures.

This state is stored by default in a local file named `terraform.tfstate`, but it can also be stored remotely, which works better in a team environment.

Terraform uses this local state to create plans and make changes to your infrastructure. Before any operation, Terraform does a [refresh](https://www.terraform.io/docs/commands/refresh.html) to update the state with the real infrastructure.

The primary purpose of Terraform state is to store bindings between objects in a remote system and resource instances declared in your configuration. When Terraform creates a remote object in response to a change of configuration, it will record the identity of that remote object against a particular resource instance and then potentially update or delete that object in response to future configuration changes.

## Mapping 
Terraform requires some sort of database to map Terraform config to the real world. When your configuration contains a `resource resource "google_compute_instance" "foo"`, Terraform uses this map to know that instance `i-abcd1234` is represented by that resource.

## Metadata
In addition to tracking the mappings between resources and remote objects, Terraform must also track metadata such as resource dependencies.

Terraform typically uses the configuration to determine dependency order. However, when you remove a resource from a Terraform configuration, Terraform must know how to delete that resource. Terraform can see that a mapping exists for a resource that is not in your configuration file and plan to destroy. However, because the resource no longer exists, the order cannot be determined from the configuration alone.

To ensure correct operation, Terraform retains a copy of the most recent set of dependencies within the state. Now Terraform can still determine the correct order for destruction from the state when you delete one or more items from the configuration.

## Performance
In addition to basic mapping, Terraform stores a cache of the attribute values for all resources in the state. This is an optional feature of Terraform state and is used only as a performance improvement.

When running a `terraform plan`, Terraform must know the current state of resources in order to effectively determine the changes needed to reach your desired configuration.

For small infrastructures, Terraform can query your providers and sync the latest attributes from all your resources. This is the default behavior of Terraform: for every `plan` and `apply`, Terraform will sync all resources in your state.

For larger infrastructures, querying every resource is too slow. Many cloud providers do not provide APIs to query multiple resources at the same time, and the round trip time for each resource is hundreds of milliseconds. In addition, cloud providers almost always have API rate limiting, so Terraform can only request a limited number of resources in a period of time. Larger users of Terraform frequently use both the `-refresh=false` flag and the `-target` flag in order to work around this. In these scenarios, the cached state is treated as the record of truth.

## Syncing
In the default configuration, Terraform stores the state in a file in the current working directory where Terraform was run. This works when you are getting started, but when Terraform is used in a team, it is important for everyone to be working with the same state so that operations will be applied to the same remote objects.

[Remote state](https://www.terraform.io/docs/state/remote.html) is the recommended solution to this problem. With a fully featured state backend, Terraform can use remote locking as a measure to avoid multiple different users accidentally running Terraform at the same time; this ensures that each Terraform run begins with the most recent updated state.

## State locking
If supported by your [backend](https://www.terraform.io/docs/backends/), Terraform will lock your state for all operations that could write state. This prevents others from acquiring the lock and potentially corrupting your state.

State locking happens automatically on all operations that could write state. You won't see any message that it is happening. If state locking fails, Terraform will not continue. You can disable state locking for most commands with the `-lock` flag, but it is not recommended.

If acquiring the lock is taking longer than expected, Terraform will output a status message. If Terraform doesn't output a message, state locking is still occurring.

## Wokspaces
Each Terraform configuration has an associated [backend](https://www.terraform.io/docs/backends/index.html) that defines how operations are executed and where persistent data such as the Terraform state is stored.

The persistent data stored in the backend belongs to a _workspace_. Initially the backend has only one workspace, called _default_, and thus only one Terraform state is associated with that configuration.

Certain backends support _multiple_ named workspaces, which allows multiple states to be associated with a single configuration. The configuration still has only one backend, but multiple distinct instances of that configuration can be deployed without configuring a new backend or changing authentication credentials.

# Working with backends
A _backend_ in Terraform determines how state is loaded and how an operation such as `apply` is executed. This abstraction enables non-local file state storage, remote execution, etc.

By default, Terraform uses the "local" backend, which is the normal behavior of Terraform you're used to.

Here are some of the benefits of backends:
-   **Working in a team:** Backends can store their state remotely and protect that state with locks to prevent corruption. Some backends, such as Terraform Cloud, even automatically store a history of all state revisions.
-   **Keeping sensitive information off disk:** State is retrieved from backends on demand and only stored in memory.
-   **Remote operations:** For larger infrastructures or certain changes, `terraform apply` can take a long time. Some backends support remote operations, which enable the operation to execute remotely. You can then turn off your computer, and your operation will still complete. Combined with remote state storage and locking (described above), this also helps in team environments.

**Backends are completely optional:** You can successfully use Terraform without ever having to learn or use backends. However, they do solve pain points that afflict teams at a certain scale. If you're working as an individual, you can probably succeed without ever using backends.

Even if you only intend to use the "local" backend, it may be useful to learn about backends because you can also change the behavior of the local backend.

## Add a local backend
When configuring a backend for the first time (moving from no defined backend to explicitly configuring one), Terraform will give you the option to migrate your state to the new backend. This lets you adopt backends without losing any existing state.

To be extra careful, we always recommend that you also manually back up your state. You can do this by simply copying your `terraform.tfstate` file to another location. The initialization process should also create a backup, but it never hurts to be safe!

Configuring a backend for the first time is no different from changing a configuration in the future: create the new configuration and run `terraform init`. Terraform will guide you the rest of the way.

Creemos un nuevo archivo:
```bash
touch main.tf
```

Añadimos el siguiente contenido:
```hcl
# Declaración del backend
terraform {
  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }
}

# Declaración del proveedor
provider "google" {
  project     = "qwiklabs-gcp-01-58cece9419b9"
  region      = "us-central-1"
}

# Declaración del bucket
resource "google_storage_bucket" "test-bucket-for-state" {
  name        = "qwiklabs-gcp-01-58cece9419b9"
  location    = "US"
  uniform_bucket_level_access = true
}
```

Iniciemos terraform y apliquemos los cambios:
```bash
terraform init
terraform apply
```

Para ver el estado:
```plain
pablo@cloudshell:~ $ terraform show
# google_storage_bucket.test-bucket-for-state:
resource "google_storage_bucket" "test-bucket-for-state" {
    default_event_based_hold    = false
    force_destroy               = false
    id                          = "qwiklabs-gcp-01-58cece9419b9"
    location                    = "US"
    name                        = "qwiklabs-gcp-01-58cece9419b9"
    project                     = "qwiklabs-gcp-01-58cece9419b9"
    requester_pays              = false
    self_link                   = "https://www.googleapis.com/storage/v1/b/qwiklabs-gcp-01-58cece9419b9"
    storage_class               = "STANDARD"
    uniform_bucket_level_access = true
    url                         = "gs://qwiklabs-gcp-01-58cece9419b9"
}
```

## Add a GCS backend

Editamos el archivo `main.tf`, sustituyendo la declaración relativa al backend:
```hcl
# Declaración del backend
terraform {
  backend "gcs" {
    bucket  = "qwiklabs-gcp-01-58cece9419b9"
    prefix  = "terraform/state"
  }
}

# Declaración del proveedor
provider "google" {
  project     = "qwiklabs-gcp-01-58cece9419b9"
  region      = "us-central-1"
}

# Declaración del bucket
resource "google_storage_bucket" "test-bucket-for-state" {
  name        = "qwiklabs-gcp-01-58cece9419b9"
  location    = "US"
  uniform_bucket_level_access = true
}
```

Inicializamos de nuevo el backend:
```bash
terraform init -migrate-state
```

### Refrescar el backend
Si en este momento, por ejemplo, añadimos unas etiquetas desde la Consola de Google Cloud, no las veremos en terraform. Hay que refrescar el estado. Terraform leerá los recursos del state y refrescará su estado. Para hacerlo ejecutamos:
```bash
terraform refresh
```

## Eliminación de bucket
> [!ERROR]
> Si intentamos eliminar un bucket con contenido usando Terraform, la operación fallará. Es necesario añadir lo siguiente a nuestro archivo TF:
> ```hcl
>   force_destroy = true
> ```

Si hemos añadido la opción de `force_destroy` debemos aplicar los cambios, para luego destruir la infra:
```bash
terraform apply
terraform destroy
```

# Import Terraform configuration
In this section, you will import an existing Docker container and image into an empty Terraform workspace. By doing so, you will learn strategies and considerations for importing real-world infrastructure into Terraform.
The default Terraform workflow involves creating and managing infrastructure entirely with Terraform.
-   Write a Terraform configuration that defines the infrastructure you want to create.
-   Review the Terraform plan to ensure that the configuration will result in the expected state and infrastructure.
-   Apply the configuration to create your Terraform state and infrastructure.
    

![terraform-workflow-diagram.png](https://cdn.qwiklabs.com/aRZeb32%2B2mvoQlsw8BFZO%2BalSG9fMx9mElFoMGB6mc0%3D)

After you create infrastructure with Terraform, you can update the configuration and plan and apply those changes. Eventually you will use Terraform to destroy the infrastructure when it is no longer needed. This workflow assumes that Terraform will create an entirely new infrastructure.

However, you may need to manage infrastructure that wasn’t created by Terraform. Terraform import solves this problem by loading supported resources into your Terraform workspace’s state. The import command doesn’t automatically generate the configuration to manage the infrastructure, though. Because of this, importing existing infrastructure into Terraform is a multi-step process.

Bringing existing infrastructure under Terraform’s control involves five main steps:
-   Identify the existing infrastructure to be imported.
-   Import the infrastructure into your Terraform state.
-   Write a Terraform configuration that matches that infrastructure.
-   Review the Terraform plan to ensure that the configuration matches the expected state and infrastructure.
-   Apply the configuration to update your Terraform state.
  
![terraform-import-workflow-diagram.png](https://cdn.qwiklabs.com/feQ3c7%2Fby0X%2FS1RV9%2FMzQCVzbg30%2FYCHQairKWXjHF4%3D)

In this section, first you will create a Docker container with the Docker CLI. Next, you will import it into a new Terraform workspace. Then you will update the container’s configuration using Terraform before finally destroying it when you are done.

> [!WARNING]
> Importing infrastructure manipulates Terraform state in ways that could leave existing Terraform projects in an invalid state. Make a backup of your `terraform.tfstate` file and `.terraform` directory before using Terraform import on a real Terraform project, and store them securely.

## Importart contenedor en Terraform
```bash
docker run --name hashicorp-learn --detach --publish 8080:80 nginx:latest
```

Clonamos el siguiente repositorio y nos situamos sobre este:
```bash
git clone https://github.com/hashicorp/learn-terraform-import.git
cd learn-terraform-import
```

This directory contains two Terraform configuration files that make up the configuration you will use in this guide:
-   `main.tf` file configures the Docker provider.
-   `docker.tf` file will contain the configuration necessary to manage the Docker container you created in an earlier step.

Inicializamos el espacio de trabajo Terraform:
```bash
terraform init
```

> [!NOTE]
>  If you are getting an error like *Error: Failed to query available provider packages* then run this command: `terraform init -upgrade`

Comentamos o eliminamos la siguiente línea en nuestro archivo ``main.tf``:
```hcl
provider "docker" {
#   host    = "npipe:////.//pipe//docker_engine" # <-- ESTA LÍNEA
}
```

En el archivo `docker.tf` definimos un nuevo recurso vacío:
```hcl
resource "docker_container" "web" {}
```

Obtenemos el ID del contenedor (de nombre *hashicorp-learn*) y lo importamos con el siguiente comando:
```bash
terraform import docker_container.web $(docker inspect -f {{.ID}} hashicorp-learn)
```

### Error: _missing argument_
Si hacemos ejecutamos `terraform plan` recibiremos el siguiente error:

```plain
student_00_7451ba2b0e1c@cloudshell:~/import/learn-terraform-import (qwiklabs-gcp-01-58cece9419b9)$ terraform plan
╷
│ Error: Missing required argument
│
│   on docker.tf line 5, in resource "docker_container" "web":
│    5: resource "docker_container" "web" { }
│
│ The argument "name" is required, but no definition was found.
╵
╷
│ Error: Missing required argument
│
│   on docker.tf line 5, in resource "docker_container" "web":
│    5: resource "docker_container" "web" { }
│
│ The argument "image" is required, but no definition was found.
```

Para solucionarlo tenemos dos opciones:
 - Using the current state is often faster, but can result in an overly verbose configuration because every attribute is included in the state, whether it is necessary to include in your configuration or not.
-  Individually selecting the required attributes can lead to more manageable configuration, but requires you to understand which attributes need to be set in the configuration.

En esta ocasión, guardaremos el estado actual como archivo de defición:
```bash
terraform show -no-color > docker.tf
```

### Error: _unconfigurable attribute_

Si ahora ejecutamos ``terraform apply`` recibiremos 200 errores distintos, muy feos. Del estilo de los mostrados a continuación:
```plain

│ Warning: Argument is deprecated
│
│   with docker_container.web,
│   on docker.tf line 24, in resource "docker_container" "web":
│   24:     links             = []
│
│ The --link flag is a legacy feature of Docker. It may eventually be removed.
╵
╷
│ Error: Value for unconfigurable attribute
│
│   with docker_container.web,
│   on docker.tf line 15, in resource "docker_container" "web":
│   15:     gateway           = "172.18.0.1"
│
│ Can't configure a value for "gateway": its value will be decided automatically based on the result of applying this configuration.
╵
╷
│ Error: Invalid or unknown key
│
│   with docker_container.web,
│   on docker.tf line 18, in resource "docker_container" "web":
│   18:     id                = "94de4c3001c2c8fa147a711a3c52d8fddadf0a267b49006a46c748f7b03b20c2"
│
╵
╷
│ Error: Value for unconfigurable attribute
│
│   with docker_container.web,
│   on docker.tf line 21, in resource "docker_container" "web":
│   21:     ip_address        = "172.18.0.2"
│
│ Can't configure a value for "ip_address": its value will be decided automatically based on the result of applying this configuration.
╵
╷
│ Error: Value for unconfigurable attribute
│
│   with docker_container.web,
│   on docker.tf line 22, in resource "docker_container" "web":
│   22:     ip_prefix_length  = 16
│
│ Can't configure a value for "ip_prefix_length": its value will be decided automatically based on the result of applying this configuration.
╵
╷
│ Error: Value for unconfigurable attribute
│
│   with docker_container.web,
│   on docker.tf line 31, in resource "docker_container" "web":
│   31:     network_data      = [
│   32:         {
│   33:             gateway                   = "172.18.0.1"
│   34:             global_ipv6_address       = ""
│   35:             global_ipv6_prefix_length = 0
│   36:             ip_address                = "172.18.0.2"
│   37:             ip_prefix_length          = 16
│   38:             ipv6_gateway              = ""
│   39:             network_name              = "bridge"
│   40:         },
│   41:     ]
│
│ Can't configure a value for "network_data": its value will be decided automatically based on the result of applying this configuration.
```

*These read-only arguments are values that Terraform stores in its state for Docker containers but that it cannot set via configuration because they are managed internally by Docker. Terraform can set the links argument with configuration, but still displays a warning because it is deprecated and might not be supported by future versions of the Docker provider.*

Para solucionarlo debemos eliminar los valores que dan error eliminando las relativas secciones. Manteniendo únicamente:  `image`, `name`, and `ports`. Podemos añadir algumos otros, siempre y cuando sean válidos. 
El siguiente fragmento es un ejemplo:
```hcl
resource "docker_container" "web" {
    name              = "hashicorp-learn"
    hostname          = "servidor-web-prueba"
    image             = "sha256:de2543b9436b7b0e2f15919c0ad4eab06e421cecc730c9c20660c430d4e5bc47"
    restart           = "always"
    ports {
        external = 8080
        internal = 80
        ip       = "0.0.0.0"
        protocol = "tcp"
    }
}
```

## Declare image 
Obtenemos las etiquetas de la imagen (`nginx:latest`, por ejemplo) y las añadiremos en el siguiente fragmento; que tanbién debemos agregar al archivo docker.tf:

```
resource "docker_image" "nginx" {
  name         = "nginx:latest"
}
```

**Note:** Do not replace the image value in the `docker_container.web` resource yet, or Terraform will destroy and recreate your container. Because Terraform hasn’t loaded the `docker_image.nginx` resource into state yet, it does not have an image ID to compare with the hardcoded one, which will cause Terraform to assume the container must be replaced. To work around this situation, create the image first, and then update the container to use it, as shown in this lab.

Create an image resource in state:
```bash
terraform apply
```

Ahora editamos la declaración del contenedor para referenciar la imagen anterior:
```plain
    image             =  docker_image.nginx.latest
```

Si volvemos a intentar un *apply* nos indicará que no son necesarios aplicar cambios puesto que el identificador de imagen es el mismo en ambos casos. 

Si en este momento editamos (el puerto publicado o el nombre, por ejemplo) el contedor se recreará. 

# Limitations and other considerations
There are several important things to consider when importing resources into Terraform.

Terraform import can only know the current state of infrastructure as reported by the Terraform provider. It does not know:
-   Whether the infrastructure is working correctly.
-   The intent of the infrastructure.
-   Changes you've made to the infrastructure that aren't controlled by Terraform; for example, the state of a Docker container's filesystem.

Importing involves manual steps which can be error-prone, especially if the person importing resources lacks the context of how and why those resources were created originally.

Importing manipulates the Terraform state file; you may want to create a backup before importing new infrastructure.

Terraform import doesn’t detect or generate relationships between infrastructure.

Terraform doesn’t detect default attributes that don’t need to be set in your configuration.

Not all providers and resources support Terraform import.

Importing infrastructure into Terraform does not mean that it can be destroyed and recreated by Terraform. For example, the imported infrastructure could rely on other unmanaged infrastructure or configuration.

Following infrastructure as code (IaC) best practices such as [immutable infrastructure](https://www.hashicorp.com/resources/what-is-mutable-vs-immutable-infrastructure) can help prevent many of these problems, but infrastructure created manually is unlikely to follow IaC best practices.

Tools such as [Terraformer](https://github.com/GoogleCloudPlatform/terraformer) can automate some manual steps associated with importing infrastructure. However, these tools are not part of Terraform itself and are not endorsed or supported by HashiCorp.